/**
 * AppleMusic-like Lyrics Player for HarmonyOS
 * Canvas歌词播放器组件 - Canvas Lyric Player Component
 */

import { LyricLine, LyricWord } from '../models/LyricModels';
import { Spring, SpringParams } from '../utils/Spring';
import { TextLayoutEngine, TextLayoutConfig, TextLayoutResult } from '../utils/TextLayout';

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
  update(delta: number, context: CanvasRenderingContext2D): void {
    this.posYSpring.update(delta);
    this.scaleSpring.update(delta);

    const posY = this.posYSpring.getCurrentPosition();
    const scale = this.scaleSpring.getCurrentPosition() / 100;

    context.save();
    context.globalAlpha = this.opacity;
    context.filter = `blur(${this.blur}px)`;
    context.translate(0, posY);
    context.scale(scale, scale);

    if (this.lineCanvas) {
      const image = this.lineCanvas.transferToImageBitmap();
      context.transferFromImageBitmap(image);
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
  private posYSpringParams: SpringParams = {
    mass: 0.9,
    damping: 15,
    stiffness: 90,
    soft: false
  };

  private scaleSpringParams: SpringParams = {
    mass: 2,
    damping: 25,
    stiffness: 100,
    soft: false
  };

  // 对齐参数
  private alignPosition: number = 0.35;
  private enableBlur: boolean = true;
  private enableScale: boolean = true;

  /**
   * 初始化歌词渲染器
   * Initialize lyric renderers
   */
  private initLyrics(): void {
    if (this.lyrics.length === 0) return;

    this.lineRenderers = [];
    for (const line of this.lyrics) {
      this.lineRenderers.push(new LyricLineRenderer(line));
    }

    // 初始化弹簧参数
    for (const renderer of this.lineRenderers) {
      renderer.posYSpring.updateParams(this.posYSpringParams);
      renderer.scaleSpring.updateParams(this.scaleSpringParams);
    }

    if (this.canvasContext) {
      for (const renderer of this.lineRenderers) {
        renderer.relayout(
          this.canvasContext,
          this.canvasWidth,
          this.baseFontSize,
          this.fontFamily
        );
      }
    }

    this.calcLayout();
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
    if (!this.canvasContext) return;

    const ctx = this.canvasContext;

    // 清空画布
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    ctx.fillStyle = 'white';
    ctx.font = `${this.baseFontSize}px ${this.fontFamily}`;

    ctx.save();
    ctx.translate(this.baseFontSize, 0);

    // 渲染所有歌词行
    for (const renderer of this.lineRenderers) {
      renderer.update(delta / 1000, ctx);
    }

    ctx.restore();
  }

  build() {
    Canvas(this.canvasContext)
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .onReady((): void => {
        this.canvasContext = new CanvasRenderingContext2D(this.settings);
        // 注意：实际使用时需要从Canvas组件获取宽高
        // 这里只是示例，需要根据实际组件大小调整
        this.canvasWidth = 800; // 需要从实际组件获取
        this.canvasHeight = 600; // 需要从实际组件获取
        this.onCanvasReady();

        // 启动渲染循环
        this.startRenderLoop();
      })
  }

  /**
   * 启动渲染循环
   * Start render loop
   */
  private startRenderLoop(): void {
    let lastTime = Date.now();

    const loop = (): void => {
      const currentTime = Date.now();
      const delta = currentTime - lastTime;
      lastTime = currentTime;

      this.renderFrame(delta);

      // 继续下一帧
      setTimeout((): void => { loop(); }, 16); // 约60fps
    };

    loop();
  }
}
