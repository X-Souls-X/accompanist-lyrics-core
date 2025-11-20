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
   */
  private createOffscreenCanvas(
    context: CanvasRenderingContext2D,
    maxWidth: number,
    baseFontSize: number,
    fontFamily: string
  ): void {
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
  private canvasContext: CanvasRenderingContext2D | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);

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
    // 初始化歌词
    this.initLyrics();
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
   * 渲染帧
   * Render frame
   */
  private renderFrame(delta: number): void {
    if (!this.canvasContext) {
      console.error('[LyricPlayer] renderFrame: canvasContext is null');
      return;
    }

    const ctx = this.canvasContext;

    // 清空画布
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // === 调试渲染：绘制背景和边框 ===
    ctx.fillStyle = '#1A1A1A'; // 深灰色背景便于调试
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 绘制边框
    ctx.strokeStyle = '#FF0000'; // 红色边框
    ctx.lineWidth = 2;
    ctx.strokeRect(1, 1, this.canvasWidth - 2, this.canvasHeight - 2);

    // === 调试信息文本 ===
    ctx.fillStyle = '#00FF00'; // 绿色文本
    ctx.font = '20px sans-serif';
    ctx.textBaseline = 'top';
    ctx.fillText(`DEBUG: Canvas ${this.canvasWidth}x${this.canvasHeight}`, 10, 10);
    ctx.fillText(`Lyrics: ${this.lineRenderers.length} lines`, 10, 35);
    ctx.fillText(`Time: ${this.currentTime}ms`, 10, 60);
    ctx.fillText(`Playing: ${this.isPlaying}`, 10, 85);

    // === 渲染歌词内容 ===
    ctx.fillStyle = 'white';
    ctx.font = `${this.baseFontSize}px ${this.fontFamily}`;

    if (this.lineRenderers.length === 0) {
      console.warn('[LyricPlayer] No line renderers available');
      ctx.fillStyle = '#FFFF00'; // 黄色警告文本
      ctx.fillText('No lyrics loaded', 10, 120);
      return;
    }

    ctx.save();
    ctx.translate(this.baseFontSize, 150); // 从调试信息下方开始

    // 渲染所有歌词行
    for (let i = 0; i < this.lineRenderers.length; i++) {
      const renderer = this.lineRenderers[i];
      try {
        renderer.update(delta / 1000, ctx, this.baseFontSize);
      } catch (e) {
        console.error(`[LyricPlayer] Error rendering line ${i}:`, e);
      }
    }

    ctx.restore();
  }

  build() {
    Column() {
      Canvas(this.canvasContext)
        .width('100%')
        .height('100%')
        .backgroundColor('#00000000') // 透明背景
        .onReady((): void => {
          // 初始化 Canvas 上下文
          if (!this.canvasContext) {
            this.canvasContext = new CanvasRenderingContext2D(this.settings);
          }

          console.info('[LyricPlayer] Canvas ready');
          console.info('[LyricPlayer] Lyrics count:', this.lyrics.length);

          // 初始化歌词
          this.onCanvasReady();

          // 启动渲染循环（使用 Animator）
          this.startRenderLoop();
        })
        .onAreaChange((oldArea: Area, newArea: Area): void => {
          // 获取真实的 Canvas 尺寸
          this.canvasWidth = Number.parseFloat(newArea.width.toString());
          this.canvasHeight = Number.parseFloat(newArea.height.toString());

          console.info('[LyricPlayer] Area changed:', this.canvasWidth, 'x', this.canvasHeight);

          if (oldArea.width.toString() !== newArea.width.toString() ||
              oldArea.height.toString() !== newArea.height.toString()) {
            // 尺寸变化时重新布局
            if (this.canvasContext && this.lineRenderers.length > 0) {
              for (const renderer of this.lineRenderers) {
                renderer.relayout(
                  this.canvasContext,
                  this.canvasWidth,
                  this.baseFontSize,
                  this.fontFamily
                );
              }
              this.calcLayout();
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
   */
  private startRenderLoop(): void {
    console.info('[LyricPlayer] Starting render loop with Animator');

    if (this.renderAnimator) {
      this.renderAnimator.finish();
    }

    this.lastFrameTime = Date.now();

    // 创建一个无限循环的 Animator
    this.renderAnimator = this.getUIContext().createAnimator({
      duration: 1000000, // 很长的持续时间
      easing: 'linear',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: -1, // 无限循环
      begin: 0,
      end: 1
    });

    let frameCount = 0;
    let that = this;

    // 使用 onFrame 驱动渲染
    this.renderAnimator.onFrame = (value: number): void => {
      const currentTime = Date.now();
      const delta = currentTime - that.lastFrameTime;
      that.lastFrameTime = currentTime;

      that.renderFrame(delta);

      frameCount++;
      // 每60帧打印一次日志
      if (frameCount % 60 === 0) {
        console.info(`[LyricPlayer] Rendered ${frameCount} frames, delta: ${delta}ms`);
      }
    };

    this.renderAnimator.onCancel = (): void => {
      console.info('[LyricPlayer] Animator cancelled');
    };

    this.renderAnimator.onFinish = (): void => {
      console.info('[LyricPlayer] Animator finished');
    };

    this.renderAnimator.play();
    console.info('[LyricPlayer] Animator started');
  }
}
