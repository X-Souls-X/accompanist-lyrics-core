/**
 * AppleMusic-like Lyrics Player for HarmonyOS
 * Canvas歌词播放器组件 - Canvas Lyric Player Component
 */

import { LyricLine, LyricWord } from '../models/LyricModels';
import { Spring, PartialSpringParams } from '../utils/Spring';
import { TextLayoutEngine, TextLayoutConfig, TextLayoutResult } from '../utils/TextLayout';
import { AnimatorResult } from '@kit.ArkUI';

/**
 * 歌词行渲染对象
 * Lyric line rendering object
 */
class LyricLineRenderer {
  private line: LyricLine;
  private layoutResults: TextLayoutResult[] = [];
  private translatedLayoutResults: TextLayoutResult[] = [];
  private romanLayoutResults: TextLayoutResult[] = [];
  private lineSize: number[] = [0, 0];
  private lineCanvas: OffscreenCanvas | null = null;

  // 变换属性
  public posYSpring: Spring = new Spring(0);
  public scaleSpring: Spring = new Spring(100);
  public opacity: number = 1;
  public blur: number = 0;

  constructor(line: LyricLine) {
    this.line = line;
  }

  /**
   * 重新布局歌词行
   * Relayout the lyric line
   */
  relayout(
    context: CanvasRenderingContext2D,
    maxWidth: number,
    baseFontSize: number,
    fontFamily: string
  ): void {
    const config: TextLayoutConfig = {
      fontSize: baseFontSize,
      maxWidth: maxWidth - 50,
      lineHeight: baseFontSize,
      uniformSpace: true
    };

    // 布局主歌词
    context.font = `${baseFontSize}px ${fontFamily}`;
    const layoutEngine = new TextLayoutEngine(context, config);
    const fullText = this.line.words.map(w => w.word).join('');
    this.layoutResults = layoutEngine.mergeLines(layoutEngine.layoutLine(fullText));

    // 布局翻译歌词
    context.font = `${baseFontSize * 0.5}px ${fontFamily}`;
    const translatedEngine = new TextLayoutEngine(context, config);
    this.translatedLayoutResults = translatedEngine.mergeLines(
      translatedEngine.layoutLine(this.line.translatedLyric)
    );

    // 布局音译歌词
    const romanEngine = new TextLayoutEngine(context, config);
    this.romanLayoutResults = romanEngine.mergeLines(
      romanEngine.layoutLine(this.line.romanLyric)
    );

    // 计算行高
    this.calculateSize(baseFontSize);

    // 创建离屏Canvas缓存
    this.createOffscreenCanvas(context, maxWidth, baseFontSize, fontFamily);
  }

  /**
   * 计算行大小
   * Calculate line size
   */
  private calculateSize(baseFontSize: number): void {
    let maxMainLineIndex = 0;
    for (const r of this.layoutResults) {
      if (r.lineIndex + 1 > maxMainLineIndex) {
        maxMainLineIndex = r.lineIndex + 1;
      }
    }

    let maxTranslatedLineIndex = 0;
    for (const r of this.translatedLayoutResults) {
      if (r.lineIndex + 1 > maxTranslatedLineIndex) {
        maxTranslatedLineIndex = r.lineIndex + 1;
      }
    }

    let maxRomanLineIndex = 0;
    for (const r of this.romanLayoutResults) {
      if (r.lineIndex + 1 > maxRomanLineIndex) {
        maxRomanLineIndex = r.lineIndex + 1;
      }
    }

    this.lineSize = [
      0,
      (maxMainLineIndex + maxTranslatedLineIndex + maxRomanLineIndex) * baseFontSize +
      baseFontSize * 0.4
    ];
  }

  /**
   * 创建离屏Canvas用于缓存渲染
   * Create offscreen canvas for cached rendering
   *
   * ⚠️ 暂时禁用：HarmonyOS 的 transferToImageBitmap() 可能导致崩溃
   * Temporarily disabled: transferToImageBitmap() may cause crashes on HarmonyOS
   */
  private createOffscreenCanvas(
    context: CanvasRenderingContext2D,
    maxWidth: number,
    baseFontSize: number,
    fontFamily: string
  ): void {
    // 暂时禁用 OffscreenCanvas，使用直接渲染模式
    // Temporarily disable OffscreenCanvas, use direct rendering mode
    this.lineCanvas = null;
    console.info('[LyricLineRenderer] OffscreenCanvas disabled, using direct rendering');

    /* 原 OffscreenCanvas 代码（暂时禁用）
    const pixelRatio = 2;
    this.lineCanvas = new OffscreenCanvas(
      maxWidth * pixelRatio,
      this.lineSize[1] * pixelRatio
    );

    const ctx = this.lineCanvas.getContext('2d') as OffscreenCanvasRenderingContext2D;
    if (!ctx) return;

    ctx.scale(pixelRatio, pixelRatio);
    ctx.fillStyle = 'white';
    ctx.textBaseline = 'top';
    ctx.textAlign = 'left';

    // 绘制主歌词
    ctx.font = `${baseFontSize}px ${fontFamily}`;
    let lineIndex = 0;
    for (const layout of this.layoutResults) {
      ctx.fillText(layout.text, layout.x, layout.lineIndex * baseFontSize);
      lineIndex = layout.lineIndex;
    }

    // 绘制翻译歌词
    ctx.translate(0, (lineIndex + 1) * baseFontSize);
    ctx.font = `${baseFontSize * 0.5}px ${fontFamily}`;
    ctx.globalAlpha = 0.5;
    lineIndex = 0;
    for (const layout of this.translatedLayoutResults) {
      ctx.fillText(layout.text, layout.x, layout.lineIndex * baseFontSize);
      lineIndex = layout.lineIndex;
    }

    // 绘制音译歌词
    ctx.translate(0, (lineIndex + 1) * baseFontSize);
    for (const layout of this.romanLayoutResults) {
      ctx.fillText(layout.text, layout.x, layout.lineIndex * baseFontSize);
    }
    */
  }

  /**
   * 更新渲染
   * Update and render
   */
  update(delta: number, context: CanvasRenderingContext2D, baseFontSize: number): void {
    this.posYSpring.update(delta);
    this.scaleSpring.update(delta);

    const posY = this.posYSpring.getCurrentPosition();
    const scale = this.scaleSpring.getCurrentPosition() / 100;

    context.save();
    context.globalAlpha = this.opacity;
    // 注意：HarmonyOS 可能不支持 filter 属性，暂时注释
    // context.filter = `blur(${this.blur}px)`;
    context.translate(0, posY);
    context.scale(scale, scale);

    // === 方法1：使用离屏 Canvas（如果可用）===
    if (this.lineCanvas) {
      try {
        const image = this.lineCanvas.transferToImageBitmap();
        context.drawImage(image, 0, 0);
      } catch (e) {
        console.error('[LyricLineRenderer] Failed to draw offscreen canvas, falling back to direct render:', e);
        // 回退到直接渲染
        this.renderDirect(context, baseFontSize);
      }
    } else {
      // === 方法2：直接渲染文本（调试用）===
      this.renderDirect(context, baseFontSize);
    }

    context.restore();
  }

  /**
   * 直接渲染（不使用离屏 Canvas）
   * Direct rendering without offscreen canvas
   */
  private renderDirect(context: CanvasRenderingContext2D, baseFontSize: number): void {
    context.fillStyle = 'white';
    context.textBaseline = 'top';
    context.textAlign = 'left';

    // 渲染主歌词
    context.font = `${baseFontSize}px HarmonyOS Sans`;
    let lineIndex = 0;
    for (const layout of this.layoutResults) {
      context.fillText(layout.text, layout.x, layout.lineIndex * baseFontSize);
      lineIndex = layout.lineIndex;
    }

    // 渲染翻译歌词
    context.save();
    context.translate(0, (lineIndex + 1) * baseFontSize);
    context.font = `${baseFontSize * 0.5}px HarmonyOS Sans`;
    context.globalAlpha = 0.5;
    lineIndex = 0;
    for (const layout of this.translatedLayoutResults) {
      context.fillText(layout.text, layout.x, layout.lineIndex * baseFontSize * 0.5);
      lineIndex = layout.lineIndex;
    }
    context.restore();

    // 渲染音译歌词
    context.save();
    context.translate(0, (lineIndex + 2) * baseFontSize);
    context.font = `${baseFontSize * 0.5}px HarmonyOS Sans`;
    context.globalAlpha = 0.5;
    for (const layout of this.romanLayoutResults) {
      context.fillText(layout.text, layout.x, layout.lineIndex * baseFontSize * 0.5);
    }
    context.restore();
  }

  /**
   * 获取行高
   * Get line height
   */
  getHeight(): number {
    return this.lineSize[1];
  }

  /**
   * 获取歌词行数据
   * Get lyric line data
   */
  getLine(): LyricLine {
    return this.line;
  }
}

/**
 * Canvas歌词播放器
 * Canvas-based lyric player with smooth animations
 */
@Component
export struct CanvasLyricPlayer {
  @Prop lyrics: LyricLine[] = [];
  @Prop currentTime: number = 0;
  @Prop isPlaying: boolean = false;
  private lineRenderers: LyricLineRenderer[] = [];

  // 🔥 关键修复：在声明时就创建 CanvasRenderingContext2D 对象（参考华为官方代码）
  // Key fix: Create CanvasRenderingContext2D object at declaration (following Huawei's code)
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private baseFontSize: number = 30;
  private fontFamily: string = 'HarmonyOS Sans';
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;
  private scrollToIndex: number = 0;
  private hotLines: Set<number> = new Set();
  private bufferedLines: Set<number> = new Set();

  // 弹簧参数
  private posYSpringParams: PartialSpringParams = this.createSpringParams(0.9, 15, 90, false);
  private scaleSpringParams: PartialSpringParams = this.createSpringParams(2, 25, 100, false);

  // 对齐参数
  private alignPosition: number = 0.35;
  private enableBlur: boolean = true;
  private enableScale: boolean = true;

  // Animator 用于驱动渲染循环
  private renderAnimator: AnimatorResult | null = null;
  private lastFrameTime: number = 0;

  /**
   * 创建弹簧参数对象
   * Create spring params object
   */
  private createSpringParams(mass: number, damping: number, stiffness: number, soft: boolean): PartialSpringParams {
    const params: PartialSpringParams = {
      mass: mass,
      damping: damping,
      stiffness: stiffness,
      soft: soft
    };
    return params;
  }

  /**
   * 初始化歌词渲染器
   * Initialize lyric renderers
   */
  private initLyrics(): void {
    console.info('[LyricPlayer] initLyrics called, lyrics count:', this.lyrics.length);

    if (this.lyrics.length === 0) {
      console.warn('[LyricPlayer] No lyrics to initialize');
      return;
    }

    this.lineRenderers = [];
    for (const line of this.lyrics) {
      this.lineRenderers.push(new LyricLineRenderer(line));
    }
    console.info('[LyricPlayer] Created', this.lineRenderers.length, 'line renderers');

    // 初始化弹簧参数
    for (const renderer of this.lineRenderers) {
      renderer.posYSpring.updateParams(this.posYSpringParams);
      renderer.scaleSpring.updateParams(this.scaleSpringParams);
    }
    console.info('[LyricPlayer] Initialized spring params');

    if (this.canvasContext) {
      console.info('[LyricPlayer] Relayout lyrics, canvas size:', this.canvasWidth, 'x', this.canvasHeight);
      for (let i = 0; i < this.lineRenderers.length; i++) {
        const renderer = this.lineRenderers[i];
        try {
          renderer.relayout(
            this.canvasContext,
            this.canvasWidth,
            this.baseFontSize,
            this.fontFamily
          );
          console.info('[LyricPlayer] Line', i, 'layout complete, height:', renderer.getHeight());
        } catch (e) {
          console.error('[LyricPlayer] Error relayouting line', i, ':', e);
        }
      }
    } else {
      console.warn('[LyricPlayer] No canvas context available for relayout');
    }

    this.calcLayout();
    console.info('[LyricPlayer] initLyrics complete');
  }

  /**
   * 更新热行（当前播放行）
   * Update hot lines (currently playing lines)
   */
  private updateHotLines(): void {
    const time = this.currentTime;
    const removedIds: number[] = [];
    const addedIds: number[] = [];

    // 移除过期的热行
    this.hotLines.forEach((id: number): void => {
      const line = this.lyrics[id];
      if (line && (line.startTime > time || line.endTime <= time)) {
        this.hotLines.delete(id);
        removedIds.push(id);
      }
    });

    // 添加新的热行
    for (let i = 0; i < this.lineRenderers.length; i++) {
      const renderer = this.lineRenderers[i];
      const line = renderer.getLine();
      if (!line.isBG && line.startTime <= time && line.endTime > time) {
        if (!this.hotLines.has(i)) {
          this.hotLines.add(i);
          addedIds.push(i);
        }
      }
    }

    // 更新缓冲行
    if (addedIds.length > 0 || removedIds.length > 0) {
      for (const id of addedIds) {
        this.bufferedLines.add(id);
      }
      for (const id of removedIds) {
        if (!this.hotLines.has(id)) {
          this.bufferedLines.delete(id);
        }
      }

      if (this.bufferedLines.size > 0) {
        let minIndex = Number.MAX_VALUE;
        this.bufferedLines.forEach((value: number): void => {
          if (value < minIndex) minIndex = value;
        });
        this.scrollToIndex = minIndex;
      }
    }
  }

  /**
   * 计算布局
   * Calculate layout for all lyric lines
   */
  private calcLayout(): void {
    if (!this.canvasContext) return;

    let curPos = 0;
    const targetAlignIndex = this.scrollToIndex;

    // 计算滚动偏移
    let scrollOffset = 0;
    for (let i = 0; i < targetAlignIndex; i++) {
      const renderer = this.lineRenderers[i];
      if (renderer) {
        const line = renderer.getLine();
        if (!(line.isBG && this.isPlaying)) {
          scrollOffset += renderer.getHeight();
        }
      }
    }

    curPos -= scrollOffset;
    curPos += this.canvasHeight * this.alignPosition;

    let latestIndex = this.scrollToIndex;
    if (this.bufferedLines.size > 0) {
      this.bufferedLines.forEach((value: number): void => {
        if (value > latestIndex) latestIndex = value;
      });
    }

    // 更新每一行的变换
    for (let i = 0; i < this.lineRenderers.length; i++) {
      const renderer = this.lineRenderers[i];
      const hasBuffered = this.bufferedLines.has(i);
      const isActive = hasBuffered || (i >= this.scrollToIndex && i < latestIndex);
      const line = renderer.getLine();

      // 计算不透明度
      let targetOpacity = hasBuffered ? 0.85 : 1.0;

      // 计算模糊
      let blurLevel = 0;
      if (this.enableBlur && !isActive) {
        blurLevel = 1 + Math.abs(i - this.scrollToIndex);
      }

      // 计算缩放
      let targetScale = 100;
      if (!isActive && this.isPlaying && this.enableScale) {
        targetScale = line.isBG ? 75 : 97;
      }

      // 设置变换
      renderer.opacity = targetOpacity;
      renderer.blur = blurLevel * 0.8;
      renderer.posYSpring.setTargetPosition(curPos);
      renderer.scaleSpring.setTargetPosition(targetScale);

      // 更新位置
      if (!line.isBG || !this.isPlaying) {
        curPos += renderer.getHeight();
      }
    }
  }

  /**
   * Canvas准备完成回调
   * Canvas ready callback
   */
  private onCanvasReady(): void {
    if (!this.canvasContext) return;

    // 初始化歌词
    this.initLyrics();
  }

  /**
   * 组件即将出现
   * Component about to appear
   */
  aboutToAppear(): void {
    // ❌ 不要在这里初始化！此时 Canvas 还没有尺寸
    // Don't initialize here! Canvas doesn't have size yet
    // 等待 onAreaChange 获得有效尺寸后再初始化
    // Wait for onAreaChange to get valid size before initializing
    console.info('[LyricPlayer] 🎬 aboutToAppear called');
  }

  /**
   * 监听属性变化
   * Watch for property changes
   */
  aboutToUpdate(): void {
    // 更新播放时间
    this.updateHotLines();
    this.calcLayout();
  }

  /**
   * 渲染帧 - 每帧都会被 Animator 调用
   * Render frame - Called by Animator on each frame
   *
   * @param delta 距离上一帧的时间间隔（毫秒）
   */
  private renderFrame(delta: number): void {
    // ============================================================
    // 第一步：验证 Canvas 上下文是否存在
    // Step 1: Validate Canvas context exists
    // ============================================================
    if (!this.canvasContext) {
      console.error('[LyricPlayer] ❌ renderFrame: canvasContext is null!');
      return;
    }

    // ============================================================
    // 第二步：验证 Canvas 尺寸是否有效
    // Step 2: Validate Canvas size is valid
    // ============================================================
    if (this.canvasWidth <= 0 || this.canvasHeight <= 0) {
      console.warn('[LyricPlayer] ⚠️ Invalid canvas size:', this.canvasWidth, 'x', this.canvasHeight);
      return;
    }

    // 如果能执行到这里，说明 Canvas 上下文和尺寸都正常
    // If we reach here, Canvas context and size are both valid
    const ctx = this.canvasContext;

    try {
      // ============================================================
      // 第三步：清空画布
      // Step 3: Clear the canvas
      // ============================================================
      ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

      // ============================================================
      // 第四步：绘制深灰色背景
      // Step 4: Draw dark gray background
      // ============================================================
      ctx.fillStyle = '#1A1A1A';
      ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

      // ============================================================
      // 第五步：检查是否有歌词数据
      // Step 5: Check if lyrics data exists
      // ============================================================
      if (this.lineRenderers.length === 0) {
        // 没有歌词 - 显示黄色警告文本
        // No lyrics - show yellow warning text
        ctx.fillStyle = '#FFFF00';
        ctx.font = '24px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('No lyrics loaded', this.canvasWidth / 2, this.canvasHeight / 2);
        console.warn('[LyricPlayer] ⚠️ No lyrics to render');
        return;
      }

      // ============================================================
      // 第六步：使用完整的渲染系统绘制歌词
      // Step 6: Render lyrics using full rendering system
      // 包含 Spring 动画、OffscreenCanvas 缓存、视觉效果
      // Includes Spring animations, OffscreenCanvas caching, visual effects
      // ============================================================
      ctx.save();
      ctx.translate(this.baseFontSize, this.canvasHeight * this.alignPosition);

      for (let i = 0; i < this.lineRenderers.length; i++) {
        const renderer = this.lineRenderers[i];
        try {
          renderer.update(delta / 1000, ctx, this.baseFontSize);
        } catch (e) {
          console.error(`[LyricPlayer] Error rendering line ${i}:`, e);
        }
      }

      ctx.restore();

    } catch (error) {
      // ============================================================
      // 捕获并记录任何渲染错误
      // Catch and log any rendering errors
      // ============================================================
      console.error('[LyricPlayer] ❌ Error in renderFrame:', error);
    }
  }

  /**
   * 构建 UI 组件
   * Build UI component
   *
   * 重要说明：
   * 1. Canvas 组件接收 canvasContext（已在构造函数中创建）
   * 2. onReady 只是标记 Canvas 已准备好，但此时还没有尺寸
   * 3. onAreaChange 是获取真实尺寸的唯一方式，在这里初始化
   */
  build() {
    Column() {
      Canvas(this.canvasContext)
        .width('100%')
        .layoutWeight(1)  // 使用 layoutWeight 而不是固定高度
        .backgroundColor('#000000')
        .onReady((): void => {
          // ============================================================
          // Canvas 组件已准备好（但还没有尺寸信息）
          // Canvas component is ready (but no size info yet)
          // ============================================================
          console.info('[LyricPlayer] 🎨 Canvas onReady event triggered');
          console.info('[LyricPlayer]   - Lyrics count:', this.lyrics.length);
          console.info('[LyricPlayer]   - Initial size:', this.canvasWidth, 'x', this.canvasHeight, '(还是初始值)');

          // 注意：不要在这里初始化 context，它已经在构造函数中创建了
          // Note: Don't initialize context here, it's already created in constructor
          // 等待 onAreaChange 获取正确尺寸后再初始化歌词
          // Wait for onAreaChange to get correct size before initializing lyrics
        })
        .onAreaChange((oldArea: Area, newArea: Area): void => {
          // ============================================================
          // Canvas 区域变化事件 - 这是获取真实尺寸的唯一途径
          // Canvas area change event - This is the only way to get real size
          // ============================================================

          // 解析新的宽度和高度
          // Parse new width and height
          const newWidth = Number.parseFloat(newArea.width.toString());
          const newHeight = Number.parseFloat(newArea.height.toString());

          console.info('[LyricPlayer] 📏 Area changed:');
          console.info('[LyricPlayer]   - Old:', oldArea.width, 'x', oldArea.height);
          console.info('[LyricPlayer]   - New:', newWidth, 'x', newHeight);

          // 检查尺寸是否真的变化了
          // Check if size really changed
          const widthChanged = this.canvasWidth !== newWidth;
          const heightChanged = this.canvasHeight !== newHeight;

          // 更新存储的尺寸
          // Update stored size
          this.canvasWidth = newWidth;
          this.canvasHeight = newHeight;

          // ============================================================
          // 只有在尺寸变化且有效时才处理
          // Only process if size changed and is valid
          // ============================================================
          if (widthChanged || heightChanged) {
            if (this.canvasWidth > 0 && this.canvasHeight > 0) {
              console.info('[LyricPlayer] ✓ Valid size obtained:', this.canvasWidth, 'x', this.canvasHeight);

              // ============================================================
              // 情况1：首次获得有效尺寸且有歌词数据 - 进行初始化
              // Case 1: First time getting valid size with lyrics data - Initialize
              // ============================================================
              if (this.lineRenderers.length === 0 && this.lyrics.length > 0) {
                console.info('[LyricPlayer] 🚀 First valid size, initializing lyrics...');
                this.onCanvasReady();  // 初始化歌词渲染器

                // 🔥 关键：立即绘制一次（参考华为官方做法）
                // Key: Draw immediately (following Huawei's approach)
                console.info('[LyricPlayer] 🎨 Drawing initial frame...');
                this.renderFrame(0);

                this.startRenderLoop();  // 启动 Animator 渲染循环
                console.info('[LyricPlayer] ✓ Initialization complete');
              }
              // ============================================================
              // 情况2：已经初始化过 - 只需要重新布局
              // Case 2: Already initialized - Just relayout
              // ============================================================
              else if (this.lineRenderers.length > 0) {
                console.info('[LyricPlayer] 🔄 Relayouting due to size change...');

                // 添加 null 检查以满足 TypeScript 类型要求
                // Add null check for TypeScript type requirement
                if (!this.canvasContext) {
                  console.error('[LyricPlayer] ❌ canvasContext is null during relayout');
                  return;
                }

                // 重新布局所有歌词行
                // Relayout all lyric lines
                for (const renderer of this.lineRenderers) {
                  renderer.relayout(
                    this.canvasContext,
                    this.canvasWidth,
                    this.baseFontSize,
                    this.fontFamily
                  );
                }
                this.calcLayout();
                console.info('[LyricPlayer] ✓ Relayout complete');

                // 🔥 如果渲染循环还没启动，启动它
                // If render loop hasn't started yet, start it
                if (!this.renderAnimator) {
                  console.info('[LyricPlayer] 🎨 Drawing initial frame after relayout...');
                  this.renderFrame(0);
                  this.startRenderLoop();
                  console.info('[LyricPlayer] ✓ Render loop started');
                }
              }
            } else {
              console.warn('[LyricPlayer] ⚠️ Size is still invalid:', this.canvasWidth, 'x', this.canvasHeight);
            }
          }
        })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 启动渲染循环（使用 Animator 驱动）
   * Start render loop using Animator
   *
   * 重要说明：
   * 1. 使用 Animator 而不是 setTimeout 来驱动渲染循环
   * 2. Animator.onFrame 会在每一帧时被调用
   * 3. iterations: -1 表示无限循环
   * 4. 这是华为官方推荐的渲染方式
   */
  private startRenderLoop(): void {
    console.info('[LyricPlayer] ⚙️ Starting render loop with Animator');

    // ============================================================
    // 第一步：清理之前的 Animator（如果存在）
    // Step 1: Clean up previous Animator (if exists)
    // ============================================================
    if (this.renderAnimator) {
      console.warn('[LyricPlayer] ⚠️ Stopping previous animator');
      this.renderAnimator.finish();
    }

    // ============================================================
    // 第二步：初始化时间戳
    // Step 2: Initialize timestamp
    // ============================================================
    this.lastFrameTime = Date.now();
    console.info('[LyricPlayer] ⏱️ Initial timestamp:', this.lastFrameTime);

    // ============================================================
    // 第三步：创建 Animator 对象
    // Step 3: Create Animator object
    // ============================================================
    try {
      this.renderAnimator = this.getUIContext().createAnimator({
        duration: 1000000,     // 持续时间：1000秒（足够长）
        easing: 'linear',      // 线性缓动（匀速）
        delay: 0,              // 无延迟
        fill: 'forwards',      // 动画结束后保持最终状态
        direction: 'normal',   // 正向播放
        iterations: -1,        // 无限循环（-1 表示永久）
        begin: 0,              // 起始值
        end: 1                 // 结束值
      });
      console.info('[LyricPlayer] ✓ Animator created successfully');
    } catch (error) {
      console.error('[LyricPlayer] ❌ Failed to create Animator:', error);
      return;
    }

    // ============================================================
    // 第四步：设置 onFrame 回调（每帧都会被调用）
    // Step 4: Setup onFrame callback (called every frame)
    // ============================================================
    let frameCount = 0;
    let that = this;

    this.renderAnimator.onFrame = (value: number): void => {
      // 计算距离上一帧的时间间隔（用于动画插值）
      // Calculate time delta since last frame (for animation interpolation)
      const currentTime = Date.now();
      const delta = currentTime - that.lastFrameTime;
      that.lastFrameTime = currentTime;

      // 调用渲染函数
      // Call render function
      that.renderFrame(delta);

      frameCount++;

      // 每60帧（约1秒）打印一次日志
      // Log every 60 frames (about 1 second)
      if (frameCount % 60 === 0) {
        console.info(`[LyricPlayer] 🎬 Rendered ${frameCount} frames, delta: ${delta}ms`);
      }

      // 前几帧打印详细日志用于调试
      // Print detailed logs for first few frames for debugging
      if (frameCount <= 5) {
        console.info(`[LyricPlayer] 🎬 Frame ${frameCount}, value: ${value}, delta: ${delta}ms`);
      }
    };

    // ============================================================
    // 第五步：设置取消回调
    // Step 5: Setup cancel callback
    // ============================================================
    this.renderAnimator.onCancel = (): void => {
      console.info('[LyricPlayer] 🛑 Animator cancelled');
    };

    // ============================================================
    // 第六步：设置完成回调
    // Step 6: Setup finish callback
    // ============================================================
    this.renderAnimator.onFinish = (): void => {
      console.info('[LyricPlayer] ✅ Animator finished');
    };

    // ============================================================
    // 第七步：启动 Animator
    // Step 7: Start the Animator
    // ============================================================
    try {
      this.renderAnimator.play();
      console.info('[LyricPlayer] ▶️ Animator play() called - render loop should start now');
      console.info('[LyricPlayer] 👀 Watch for "Frame X" messages to confirm rendering is working');
    } catch (error) {
      console.error('[LyricPlayer] ❌ Failed to play Animator:', error);
    }
  }
}
