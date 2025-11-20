/**
 * 最简单的 Canvas 测试组件
 * 用于验证 Canvas 基础绘制是否正常工作
 */

@Entry
@Component
struct CanvasTest {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private viewWidth: number = 360;
  private viewHeight: number = 500;

  /**
   * 绘制测试内容
   */
  private drawTest(): void {
    console.info('[CanvasTest] drawTest called, size:', this.viewWidth, 'x', this.viewHeight);

    if (!this.context) {
      console.error('[CanvasTest] context is null!');
      return;
    }

    const ctx = this.context;

    // 1. 清空画布
    ctx.clearRect(0, 0, this.viewWidth, this.viewHeight);
    console.info('[CanvasTest] clearRect done');

    // 2. 绘制背景
    ctx.fillStyle = '#FF0000'; // 红色背景
    ctx.fillRect(0, 0, this.viewWidth, this.viewHeight);
    console.info('[CanvasTest] background drawn');

    // 3. 绘制边框
    ctx.strokeStyle = '#00FF00'; // 绿色边框
    ctx.lineWidth = 5;
    ctx.strokeRect(10, 10, this.viewWidth - 20, this.viewHeight - 20);
    console.info('[CanvasTest] border drawn');

    // 4. 绘制圆形
    ctx.beginPath();
    ctx.arc(this.viewWidth / 2, this.viewHeight / 2, 50, 0, Math.PI * 2);
    ctx.fillStyle = '#0000FF'; // 蓝色圆形
    ctx.fill();
    console.info('[CanvasTest] circle drawn');

    // 5. 绘制文本
    ctx.fillStyle = '#FFFFFF'; // 白色文字
    ctx.font = '30px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText('Canvas Test', this.viewWidth / 2, 50);
    console.info('[CanvasTest] text drawn');

    // 6. 绘制第二行文本
    ctx.fillStyle = '#FFFF00'; // 黄色文字
    ctx.font = '20px sans-serif';
    ctx.fillText(`Size: ${this.viewWidth} x ${this.viewHeight}`, this.viewWidth / 2, 100);
    console.info('[CanvasTest] size text drawn');

    // 7. 绘制矩形
    ctx.fillStyle = '#FF00FF'; // 紫色矩形
    ctx.fillRect(50, this.viewHeight - 150, this.viewWidth - 100, 100);
    console.info('[CanvasTest] rectangle drawn');

    console.info('[CanvasTest] drawTest complete');
  }

  build() {
    Column() {
      Text('Canvas 测试')
        .fontSize(24)
        .fontColor(Color.White)
        .padding(10)
        .backgroundColor('#333333')
        .width('100%')

      Canvas(this.context)
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .onReady((): void => {
          console.info('[CanvasTest] Canvas onReady called');
          this.drawTest();
        })
        .onAreaChange((oldArea: Area, newArea: Area): void => {
          this.viewWidth = Number.parseFloat(newArea.width.toString());
          this.viewHeight = Number.parseFloat(newArea.height.toString());
          console.info('[CanvasTest] Area changed:', this.viewWidth, 'x', this.viewHeight);

          if (oldArea.width.toString() !== newArea.width.toString() ||
              oldArea.height.toString() !== newArea.height.toString()) {
            this.drawTest();
          }
        })

      Text('如果看到红色背景、绿色边框、蓝色圆形和文字，说明Canvas正常工作')
        .fontSize(14)
        .fontColor(Color.White)
        .padding(10)
        .backgroundColor('#333333')
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
