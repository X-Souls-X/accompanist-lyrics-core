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
  private lineSize: [number, number] = [0, 0];
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
    const maxMainLineIndex = Math.max(0, ...this.layoutResults.map(r => r.lineIndex + 1));
    const maxTranslatedLineIndex = Math.max(0, ...this.translatedLayoutResults.map(r => r.lineIndex + 1));
    const maxRomanLineIndex = Math.max(0, ...this.romanLayoutResults.map(r => r.lineIndex + 1));

    this.lineSize = [
      0, // width will be set by parent
      (maxMainLineIndex + maxTranslatedLineIndex + maxRomanLineIndex) * baseFontSize + baseFontSize * 0.4
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
    // Note: HarmonyOS使用OffscreenCanvas代替HTMLCanvasElement
    const pixelRatio = 2; // 鸿蒙设备像素比
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
      context.drawImage(this.lineCanvas, 0, 0);
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
  @State private lyrics: LyricLine[] = [];
  @State private currentTime: number = 0;
  @State private isPlaying: boolean = false;
  private lineRenderers: LyricLineRenderer[] = [];
  private canvasContext: CanvasRenderingContext2D | null = null;
  private renderingContext: RenderingContext | null = null;
  private settings: CanvasRenderingContext2DSettings = new CanvasRenderingContext2DSettings(true);

  private baseFontSize: number = 30;
  private fontFamily: string = 'HarmonyOS Sans';
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;
  private scrollToIndex: number = 0;
  private hotLines: Set<number> = new Set();
  private bufferedLines: Set<number> = new Set();

  // 弹簧参数
  private posYSpringParams: Partial<SpringParams> = {
    mass: 0.9,
    damping: 15,
    stiffness: 90
  };

  private scaleSpringParams: Partial<SpringParams> = {
    mass: 2,
    damping: 25,
    stiffness: 100
  };

  // 对齐参数
  private alignPosition: number = 0.35;
  private enableBlur: boolean = true;
  private enableScale: boolean = true;

  /**
   * 设置歌词数据
   * Set lyric lines
   */
  setLyrics(lyrics: LyricLine[]): void {
    this.lyrics = lyrics;
    this.lineRenderers = lyrics.map(line => new LyricLineRenderer(line));

    // 初始化弹簧参数
    for (const renderer of this.lineRenderers) {
      renderer.posYSpring.updateParams(this.posYSpringParams);
      renderer.scaleSpring.updateParams(this.scaleSpringParams);
    }

    this.calcLayout();
  }

  /**
   * 设置当前播放时间
   * Set current playback time
   */
  setCurrentTime(time: number): void {
    this.currentTime = time;
    this.updateHotLines();
    this.calcLayout();
  }

  /**
   * 更新热行（当前播放行）
   * Update hot lines (currently playing lines)
   */
  private updateHotLines(): void {
    const time = this.currentTime;
    const removedIds = new Set<number>();
    const addedIds = new Set<number>();

    // 移除过期的热行
    for (const id of this.hotLines) {
      const line = this.lyrics[id];
      if (line && (line.startTime > time || line.endTime <= time)) {
        this.hotLines.delete(id);
        removedIds.add(id);
      }
    }

    // 添加新的热行
    this.lineRenderers.forEach((renderer, id) => {
      const line = renderer.getLine();
      if (!line.isBG && line.startTime <= time && line.endTime > time) {
        if (!this.hotLines.has(id)) {
          this.hotLines.add(id);
          addedIds.add(id);
        }
      }
    });

    // 更新缓冲行
    if (addedIds.size > 0 || removedIds.size > 0) {
      for (const id of addedIds) {
        this.bufferedLines.add(id);
      }
      for (const id of removedIds) {
        if (!this.hotLines.has(id)) {
          this.bufferedLines.delete(id);
        }
      }

      if (this.bufferedLines.size > 0) {
        this.scrollToIndex = Math.min(...Array.from(this.bufferedLines));
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
    const scrollOffset = this.lineRenderers
      .slice(0, targetAlignIndex)
      .reduce((acc, renderer) => {
        const line = renderer.getLine();
        return acc + (line.isBG && this.isPlaying ? 0 : renderer.getHeight());
      }, 0);

    curPos -= scrollOffset;
    curPos += this.canvasHeight * this.alignPosition;

    const latestIndex = this.bufferedLines.size > 0
      ? Math.max(...Array.from(this.bufferedLines))
      : this.scrollToIndex;

    // 更新每一行的变换
    this.lineRenderers.forEach((renderer, i) => {
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
    });
  }

  /**
   * Canvas准备完成回调
   * Canvas ready callback
   */
  private onCanvasReady(): void {
    if (!this.canvasContext) return;

    // 重新布局所有行
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
    Canvas(this.renderingContext)
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .onReady(() => {
        if (this.renderingContext) {
          this.canvasContext = this.renderingContext.getContext(this.settings);
          this.canvasWidth = this.renderingContext.width;
          this.canvasHeight = this.renderingContext.height;
          this.onCanvasReady();

          // 启动渲染循环
          this.startRenderLoop();
        }
      })
  }

  /**
   * 启动渲染循环
   * Start render loop
   */
  private startRenderLoop(): void {
    let lastTime = Date.now();

    const loop = () => {
      const currentTime = Date.now();
      const delta = currentTime - lastTime;
      lastTime = currentTime;

      this.renderFrame(delta);

      requestAnimationFrame(loop);
    };

    requestAnimationFrame(loop);
  }

  /**
   * 播放
   * Play
   */
  play(): void {
    this.isPlaying = true;
    this.calcLayout();
  }

  /**
   * 暂停
   * Pause
   */
  pause(): void {
    this.isPlaying = false;
    this.calcLayout();
  }
}
