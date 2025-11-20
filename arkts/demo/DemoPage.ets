/**
 * AppleMusic-like Lyrics Player for HarmonyOS
 * 使用示例 - Demo Page
 */

import { CanvasLyricPlayer } from '../components/LyricPlayer';
import { LyricLine, LyricWord } from '../models/LyricModels';

/**
 * 示例歌词数据
 * Sample lyric data
 */
function getSampleLyrics(): LyricLine[] {
  return [
    new LyricLine(
      [
        new LyricWord('如', 0, 500),
        new LyricWord('果', 500, 1000),
        new LyricWord('有', 1000, 1500),
        new LyricWord('一', 1500, 2000),
        new LyricWord('天', 2000, 2500)
      ],
      0, 2500, 'If one day'
    ),
    new LyricLine(
      [
        new LyricWord('我', 3000, 3500),
        new LyricWord('悄', 3500, 4000),
        new LyricWord('然', 4000, 4500),
        new LyricWord('离', 4500, 5000),
        new LyricWord('去', 5000, 5500)
      ],
      3000, 5500, 'I quietly leave'
    ),
    new LyricLine(
      [
        new LyricWord('请', 6000, 6500),
        new LyricWord('把', 6500, 7000),
        new LyricWord('我', 7000, 7500),
        new LyricWord('埋', 7500, 8000),
        new LyricWord('在', 8000, 8500),
        new LyricWord('这', 8500, 9000),
        new LyricWord('春', 9000, 9500),
        new LyricWord('天', 9500, 10000),
        new LyricWord('里', 10000, 10500)
      ],
      6000, 10500, 'Please bury me in this spring'
    ),
    new LyricLine(
      [
        new LyricWord('I', 11000, 11300),
        new LyricWord(' ', 11300, 11400),
        new LyricWord('lean', 11400, 12000),
        new LyricWord(' ', 12000, 12100),
        new LyricWord('in', 12100, 12400),
        new LyricWord(' ', 12400, 12500),
        new LyricWord('and', 12500, 12800),
        new LyricWord(' ', 12800, 12900),
        new LyricWord('you', 12900, 13200),
        new LyricWord(' ', 13200, 13300),
        new LyricWord('move', 13300, 13800),
        new LyricWord(' ', 13800, 13900),
        new LyricWord('away', 13900, 14500)
      ],
      11000, 14500, '我靠近你却离开'
    ),
    new LyricLine(
      [
        new LyricWord('这', 15000, 15300),
        new LyricWord('是', 15300, 15600),
        new LyricWord('背', 15600, 16000),
        new LyricWord('景', 16000, 16500),
        new LyricWord('人', 16500, 17000),
        new LyricWord('声', 17000, 17500)
      ],
      15000, 17500, '', '', true, false // 背景歌词
    ),
    new LyricLine(
      [
        new LyricWord('月', 18000, 18500),
        new LyricWord('光', 18500, 19000),
        new LyricWord('还', 19000, 19500),
        new LyricWord('是', 19500, 20000),
        new LyricWord('少', 20000, 20500),
        new LyricWord('年', 20500, 21000),
        new LyricWord('的', 21000, 21500),
        new LyricWord('月', 21500, 22000),
        new LyricWord('光', 22000, 22500)
      ],
      18000, 22500, 'The moonlight is still the moonlight of youth'
    )
  ];
}

/**
 * 演示页面
 * Demo page showing how to use the lyric player
 */
@Entry
@Component
struct DemoPage {
  @State private currentTime: number = 0;
  @State private isPlaying: boolean = false;
  private timer: number = -1;

  aboutToDisappear() {
    if (this.timer !== -1) {
      clearInterval(this.timer);
    }
  }

  /**
   * 播放/暂停切换
   * Toggle play/pause
   */
  private togglePlayPause(): void {
    this.isPlaying = !this.isPlaying;

    if (this.isPlaying) {
      this.startTimer();
    } else {
      this.stopTimer();
    }
  }

  /**
   * 启动计时器
   * Start timer
   */
  private startTimer(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
    }

    this.timer = setInterval(() => {
      this.currentTime += 50;
      if (this.currentTime > 25000) {
        this.currentTime = 0;
      }
    }, 50);
  }

  /**
   * 停止计时器
   * Stop timer
   */
  private stopTimer(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  /**
   * 跳转到指定时间
   * Seek to specific time
   */
  private seekTo(time: number): void {
    this.currentTime = time;
  }

  /**
   * 格式化时间
   * Format time in mm:ss format
   */
  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const secStr = seconds < 10 ? '0' + seconds : '' + seconds;
    return `${minutes}:${secStr}`;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('AppleMusic 风格歌词播放器')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(60)
      .backgroundColor('#1C1C1E')
      .justifyContent(FlexAlign.Center)

      // 歌词播放器区域
      Stack() {
        // 背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#2C2C2E')

        // 歌词播放器组件
        CanvasLyricPlayer()
          .width('100%')
          .height('100%')
      }
      .layoutWeight(1)

      // 控制栏
      Column({ space: 20 }) {
        // 进度条
        Row({ space: 10 }) {
          Text(this.formatTime(this.currentTime))
            .fontSize(12)
            .fontColor(Color.White)

          Slider({
            value: this.currentTime,
            min: 0,
            max: 25000,
            step: 100,
            style: SliderStyle.OutSet
          })
            .blockColor(Color.White)
            .trackColor(Color.Gray)
            .selectedColor('#007AFF')
            .layoutWeight(1)
            .onChange((value: number) => {
              this.seekTo(value);
            })

          Text(this.formatTime(25000))
            .fontSize(12)
            .fontColor(Color.White)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })

        // 播放控制按钮
        Row({ space: 40 }) {
          // 播放/暂停按钮
          Button(this.isPlaying ? '暂停' : '播放')
            .width(80)
            .height(80)
            .backgroundColor('#007AFF')
            .onClick(() => {
              this.togglePlayPause();
            })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')

        // 快捷跳转按钮
        Row({ space: 10 }) {
          Button('0s')
            .onClick(() => this.seekTo(0))
            .fontSize(12)
            .width(50)
          Button('5s')
            .onClick(() => this.seekTo(5000))
            .fontSize(12)
            .width(50)
          Button('10s')
            .onClick(() => this.seekTo(10000))
            .fontSize(12)
            .width(50)
          Button('15s')
            .onClick(() => this.seekTo(15000))
            .fontSize(12)
            .width(50)
          Button('20s')
            .onClick(() => this.seekTo(20000))
            .fontSize(12)
            .width(50)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }
      .width('100%')
      .height(220)
      .backgroundColor('#1C1C1E')
      .padding({ top: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
