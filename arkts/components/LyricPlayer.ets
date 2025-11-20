/**
 * AppleMusic-like Lyrics Player for HarmonyOS
 * Canvas歌词播放器组件 - Canvas Lyric Player Component
 *
 * 参考华为官方 LrcInfoComponent 的渲染模式
 */

import { LyricLine, LyricWord } from '../models/LyricModels';
import { AnimatorResult } from '@kit.ArkUI';

/**
 * Canvas 歌词播放器
 * 使用 Animator 驱动的按需渲染模式（而非持续循环）
 */
@Component
export struct CanvasLyricPlayer {
  @Prop @Watch('onLyricsChanged') lyrics: LyricLine[] = [];
  @Prop @Watch('onTimeChanged') currentTime: number = 0;
  @Prop isPlaying: boolean = false;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // Canvas 尺寸
  private viewWidth: number = 360;
  private viewHeight: number = 500;

  // 字体设置
  private baseFontSize: number = 30;
  private currentFontSize: number = 36;
  private fontFamily: string = 'HarmonyOS Sans';
  private normalTextColor: string = '#99FFFFFF';
  private currentTextColor: string = '#FFFFFF';

  // 布局参数
  private lineSpacing: number = 24;
  private initFirstLineY: number = 0;
  private alignPosition: number = 0.35; // 当前行对齐位置（0-1）

  // 状态
  private currentLine: number = -1;
  private curCanvasOffsetY: number = 0;

  // 动画
  private animator: AnimatorResult | null = null;

  /**
   * 歌词变化时重置
   */
  onLyricsChanged(): void {
    console.info('[LyricPlayer] Lyrics changed, count:', this.lyrics.length);
    this.currentLine = -1;
    this.curCanvasOffsetY = 0;
    this.onTimeChanged();
  }

  /**
   * 时间变化时更新显示
   */
  onTimeChanged(): void {
    if (this.lyrics.length === 0) {
      this.drawContent(0);
      return;
    }

    const line = this.findCurrentLine(this.currentTime);
    console.info('[LyricPlayer] Time:', this.currentTime, 'Line:', line);

    if (line !== this.currentLine) {
      this.currentLine = line;
      this.smoothScrollTo(line);
    } else {
      // 当前行内，重绘以更新逐字效果
      this.drawContent(this.curCanvasOffsetY);
    }
  }

  /**
   * 查找当前时间对应的歌词行
   */
  private findCurrentLine(time: number): number {
    for (let i = 0; i < this.lyrics.length; i++) {
      const line = this.lyrics[i];
      if (line.startTime <= time && line.endTime > time) {
        return i;
      }
    }
    return this.currentLine >= 0 ? this.currentLine : 0;
  }

  /**
   * 计算滚动到指定行需要的偏移量
   */
  private getOffset(line: number): number {
    let offsetY = 0;

    for (let i = 0; i <= line && i < this.lyrics.length; i++) {
      if (i === line) {
        // 当前行使用较大字体
        offsetY += this.getLineHeight(this.lyrics[i].words.map(w => w.word).join(''), true) / 2;
      } else {
        offsetY += this.getLineHeight(this.lyrics[i].words.map(w => w.word).join(''), false) + this.lineSpacing;
      }
    }

    return offsetY;
  }

  /**
   * 计算文本行高
   */
  private getLineHeight(text: string, isCurrent: boolean): number {
    const fontSize = isCurrent ? this.currentFontSize : this.baseFontSize;
    this.context.font = `${fontSize}vp ${this.fontFamily}`;
    const metrics = this.context.measureText(text);
    return metrics.height || fontSize * 1.2; // 回退到字体大小的1.2倍
  }

  /**
   * 平滑滚动到指定行
   */
  private smoothScrollTo(line: number): void {
    const offset = this.getOffset(line);
    console.info('[LyricPlayer] Smooth scroll to line:', line, 'offset:', offset);
    this.startAnimator(-offset);
  }

  /**
   * 启动动画
   */
  private startAnimator(desOffsetY: number): void {
    if (this.animator) {
      this.animator.finish();
    }

    this.animator = this.getUIContext().createAnimator({
      duration: 400,
      easing: 'ease',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: this.curCanvasOffsetY,
      end: desOffsetY
    });

    this.animator.onFrame = (value: number): void => {
      this.drawContent(value);
    };

    this.animator.onFinish = (): void => {
      this.curCanvasOffsetY = desOffsetY;
    };

    this.animator.play();
  }

  /**
   * 绘制内容
   */
  private drawContent(offsetY: number): void {
    if (!this.context) {
      console.error('[LyricPlayer] Context not ready');
      return;
    }

    const ctx = this.context;

    // 清空画布
    ctx.clearRect(0, 0, this.viewWidth, this.viewHeight);

    // === 调试：绘制背景和边框 ===
    ctx.fillStyle = '#1A1A1A';
    ctx.fillRect(0, 0, this.viewWidth, this.viewHeight);

    ctx.strokeStyle = '#FF0000';
    ctx.lineWidth = 2;
    ctx.strokeRect(1, 1, this.viewWidth - 2, this.viewHeight - 2);

    // === 调试信息 ===
    ctx.fillStyle = '#00FF00';
    ctx.font = '16px sans-serif';
    ctx.textBaseline = 'top';
    ctx.fillText(`Canvas: ${this.viewWidth}x${this.viewHeight}`, 10, 10);
    ctx.fillText(`Lyrics: ${this.lyrics.length} lines`, 10, 30);
    ctx.fillText(`Time: ${this.currentTime}ms`, 10, 50);
    ctx.fillText(`Line: ${this.currentLine}`, 10, 70);
    ctx.fillText(`Offset: ${offsetY.toFixed(2)}`, 10, 90);

    // 更新当前偏移
    this.curCanvasOffsetY = offsetY;

    // 如果没有歌词，显示提示
    if (this.lyrics.length === 0) {
      ctx.fillStyle = '#FFFF00';
      ctx.font = `${this.baseFontSize}vp ${this.fontFamily}`;
      ctx.textAlign = 'center';
      ctx.fillText('No lyrics loaded', this.viewWidth / 2, this.viewHeight / 2);
      return;
    }

    // === 绘制歌词 ===
    ctx.save();

    // 应用偏移
    let y = this.initFirstLineY + offsetY;

    // 绘制每一行歌词
    for (let i = 0; i < this.lyrics.length; i++) {
      const line = this.lyrics[i];
      const isCurrent = i === this.currentLine;

      y = this.drawLyricLine(ctx, line, y, isCurrent);
    }

    ctx.restore();

    // === 渐变蒙版效果 ===
    ctx.globalCompositeOperation = 'destination-in';
    const grad = ctx.createLinearGradient(0, 0, 0, this.viewHeight);
    grad.addColorStop(0.0, '#00FFFFFF');
    grad.addColorStop(0.15, '#FFFFFFFF');
    grad.addColorStop(0.85, '#FFFFFFFF');
    grad.addColorStop(1.0, '#00FFFFFF');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, this.viewWidth, this.viewHeight);

    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * 绘制单行歌词
   */
  private drawLyricLine(ctx: CanvasRenderingContext2D, line: LyricLine, y: number, isCurrent: boolean): number {
    const fontSize = isCurrent ? this.currentFontSize : this.baseFontSize;
    const color = isCurrent ? this.currentTextColor : this.normalTextColor;

    ctx.font = `${fontSize}vp ${this.fontFamily}`;
    ctx.fillStyle = color;
    ctx.textAlign = 'start';
    ctx.textBaseline = 'top';

    // 主歌词
    const mainText = line.words.map(w => w.word).join('');
    const mainMetrics = ctx.measureText(mainText);

    y += this.lineSpacing;

    // 绘制主歌词（带逐字高亮效果）
    if (isCurrent && line.words.length > 0) {
      this.drawWordByWord(ctx, line, 20, y);
    } else {
      ctx.fillText(mainText, 20, y);
    }

    y += mainMetrics.height || fontSize * 1.2;

    // 翻译歌词
    if (line.translatedLyric && line.translatedLyric.length > 0) {
      ctx.save();
      ctx.font = `${fontSize * 0.6}vp ${this.fontFamily}`;
      ctx.globalAlpha = 0.6;
      ctx.fillText(line.translatedLyric, 20, y);
      const transMetrics = ctx.measureText(line.translatedLyric);
      y += (transMetrics.height || fontSize * 0.6 * 1.2);
      ctx.restore();
    }

    return y;
  }

  /**
   * 逐字绘制（带渐变高亮）
   */
  private drawWordByWord(ctx: CanvasRenderingContext2D, line: LyricLine, x: number, y: number): void {
    let wordX = x;

    for (let i = 0; i < line.words.length; i++) {
      const word = line.words[i];
      const wordStartTime = word.startTime;
      const wordEndTime = word.endTime;

      // 判断当前词是否正在播放
      if (wordStartTime <= this.currentTime && this.currentTime < wordEndTime) {
        // 正在播放的词使用高亮色
        ctx.fillStyle = '#18BBFC'; // 蓝色高亮
      } else if (wordEndTime <= this.currentTime) {
        // 已播放的词
        ctx.fillStyle = this.currentTextColor;
      } else {
        // 未播放的词
        ctx.fillStyle = this.normalTextColor;
      }

      ctx.fillText(word.word, wordX, y);
      wordX += ctx.measureText(word.word).width;
    }
  }

  /**
   * 计算初始参数
   */
  private calculate(): void {
    // 根据对齐位置计算首行Y坐标
    this.initFirstLineY = this.viewHeight * this.alignPosition;
    console.info('[LyricPlayer] Calculate - initFirstLineY:', this.initFirstLineY);
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .onReady((): void => {
        console.info('[LyricPlayer] Canvas ready');
        this.calculate();
        this.drawContent(0);
      })
      .onAreaChange((oldArea: Area, newArea: Area): void => {
        // 获取真实的 Canvas 尺寸
        this.viewWidth = Number.parseFloat(newArea.width.toString());
        this.viewHeight = Number.parseFloat(newArea.height.toString());

        console.info('[LyricPlayer] Area changed:', this.viewWidth, 'x', this.viewHeight);

        if (oldArea.width.toString() !== newArea.width.toString() ||
            oldArea.height.toString() !== newArea.height.toString()) {
          this.calculate();

          // 重新计算当前行并绘制
          const line = this.findCurrentLine(this.currentTime);
          const offset = this.getOffset(line);
          this.drawContent(-offset);
        }
      })
  }
}
