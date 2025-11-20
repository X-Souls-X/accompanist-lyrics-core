/**
 * 使用 Animator 驱动的 Canvas 测试组件
 * 测试 Animator.onFrame 是否能正常驱动 Canvas 绘制
 */

import { AnimatorResult } from '@kit.ArkUI';

@Entry
@Component
struct CanvasAnimatorTest {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private viewWidth: number = 360;
  private viewHeight: number = 500;
  private animator: AnimatorResult | null = null;
  private frameCount: number = 0;

  /**
   * 绘制测试内容（每帧都会调用）
   */
  private drawFrame(): void {
    if (!this.context) {
      console.error('[AnimatorTest] context is null!');
      return;
    }

    const ctx = this.context;

    // 1. 清空画布
    ctx.clearRect(0, 0, this.viewWidth, this.viewHeight);

    // 2. 绘制背景
    ctx.fillStyle = '#1A1A1A'; // 深灰色背景
    ctx.fillRect(0, 0, this.viewWidth, this.viewHeight);

    // 3. 绘制边框
    ctx.strokeStyle = '#FF0000'; // 红色边框
    ctx.lineWidth = 3;
    ctx.strokeRect(2, 2, this.viewWidth - 4, this.viewHeight - 4);

    // 4. 绘制标题
    ctx.fillStyle = '#00FF00'; // 绿色文字
    ctx.font = '24px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText('Animator Canvas Test', this.viewWidth / 2, 20);

    // 5. 绘制帧数（动态变化）
    ctx.fillStyle = '#FFFF00'; // 黄色文字
    ctx.font = '20px sans-serif';
    ctx.fillText(`Frame: ${this.frameCount}`, this.viewWidth / 2, 60);

    // 6. 绘制画布尺寸
    ctx.fillStyle = '#00FFFF'; // 青色文字
    ctx.font = '16px sans-serif';
    ctx.fillText(`Canvas: ${this.viewWidth} x ${this.viewHeight}`, this.viewWidth / 2, 100);

    // 7. 绘制动画圆形（位置会变化）
    const centerY = this.viewHeight / 2;
    const offset = Math.sin(this.frameCount * 0.05) * 50; // 上下移动
    ctx.beginPath();
    ctx.arc(this.viewWidth / 2, centerY + offset, 30, 0, Math.PI * 2);
    ctx.fillStyle = '#FF00FF'; // 紫色圆形
    ctx.fill();

    // 8. 绘制旋转的矩形
    ctx.save();
    ctx.translate(this.viewWidth / 2, this.viewHeight - 100);
    ctx.rotate((this.frameCount * 0.02) * Math.PI / 180); // 旋转
    ctx.fillStyle = '#0000FF'; // 蓝色矩形
    ctx.fillRect(-40, -40, 80, 80);
    ctx.restore();

    // 9. 底部提示
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '14px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('如果帧数递增、圆形上下移动、矩形旋转', this.viewWidth / 2, this.viewHeight - 40);
    ctx.fillText('说明 Animator 驱动的渲染循环正常工作', this.viewWidth / 2, this.viewHeight - 20);
  }

  /**
   * 启动 Animator 渲染循环
   */
  private startAnimator(): void {
    console.info('[AnimatorTest] Starting animator');

    if (this.animator) {
      this.animator.finish();
    }

    this.animator = this.getUIContext().createAnimator({
      duration: 1000000,
      easing: 'linear',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: -1, // 无限循环
      begin: 0,
      end: 1
    });

    let that = this;

    this.animator.onFrame = (value: number): void => {
      that.frameCount++;
      that.drawFrame();

      // 每60帧打印一次日志
      if (that.frameCount % 60 === 0) {
        console.info(`[AnimatorTest] Frame ${that.frameCount}`);
      }
    };

    this.animator.onCancel = (): void => {
      console.info('[AnimatorTest] Animator cancelled');
    };

    this.animator.onFinish = (): void => {
      console.info('[AnimatorTest] Animator finished');
    };

    this.animator.play();
    console.info('[AnimatorTest] Animator started');
  }

  aboutToDisappear(): void {
    if (this.animator) {
      this.animator.finish();
    }
  }

  build() {
    Column() {
      Text('Animator Canvas 测试')
        .fontSize(24)
        .fontColor(Color.White)
        .padding(10)
        .backgroundColor('#333333')
        .width('100%')

      Canvas(this.context)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#000000')
        .onReady((): void => {
          console.info('[AnimatorTest] Canvas onReady');
          this.drawFrame();
          this.startAnimator();
        })
        .onAreaChange((oldArea: Area, newArea: Area): void => {
          this.viewWidth = Number.parseFloat(newArea.width.toString());
          this.viewHeight = Number.parseFloat(newArea.height.toString());
          console.info('[AnimatorTest] Area changed:', this.viewWidth, 'x', this.viewHeight);
        })

      Column() {
        Text('预期效果：')
          .fontSize(16)
          .fontColor(Color.White)
          .alignSelf(ItemAlign.Start)
        Text('1. 红色边框 + 深灰色背景')
          .fontSize(14)
          .fontColor('#AAAAAA')
          .alignSelf(ItemAlign.Start)
        Text('2. 绿色标题 "Animator Canvas Test"')
          .fontSize(14)
          .fontColor('#AAAAAA')
          .alignSelf(ItemAlign.Start)
        Text('3. 黄色帧数不断递增')
          .fontSize(14)
          .fontColor('#AAAAAA')
          .alignSelf(ItemAlign.Start)
        Text('4. 紫色圆形上下移动')
          .fontSize(14)
          .fontColor('#AAAAAA')
          .alignSelf(ItemAlign.Start)
        Text('5. 蓝色矩形不断旋转')
          .fontSize(14)
          .fontColor('#AAAAAA')
          .alignSelf(ItemAlign.Start)
      }
      .padding(10)
      .backgroundColor('#333333')
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
