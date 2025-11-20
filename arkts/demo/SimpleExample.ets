/**
 * AppleMusic-like Lyrics Player for HarmonyOS
 * 简单使用示例 - Simple Usage Example
 */

import { CanvasLyricPlayer } from '../components/LyricPlayer';
import { LyricLine, LyricWord } from '../models/LyricModels';

/**
 * 最简单的使用示例
 * Simplest usage example
 */
@Entry
@Component
struct SimpleExample {
  @State private currentTime: number = 0;
  @State private isPlaying: boolean = true;
  @State private lyrics: LyricLine[] = [];
  private timer: number = -1;

  aboutToAppear(): void {
    // 创建歌词数据
    this.lyrics = [
      new LyricLine(
        [
          new LyricWord('Hello', 0, 1000),
          new LyricWord(' ', 1000, 1100),
          new LyricWord('World', 1100, 2000)
        ],
        0, 2000, '你好世界'
      ),
      new LyricLine(
        [
          new LyricWord('Welcome', 3000, 4000),
          new LyricWord(' ', 4000, 4100),
          new LyricWord('to', 4100, 4500),
          new LyricWord(' ', 4500, 4600),
          new LyricWord('HarmonyOS', 4600, 6000)
        ],
        3000, 6000, '欢迎来到鸿蒙'
      )
    ];

    // 启动定时器模拟播放
    this.timer = setInterval((): void => {
      this.currentTime += 50;
      if (this.currentTime > 7000) {
        this.currentTime = 0;
      }
    }, 50);
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
    }
  }

  build() {
    Column() {
      CanvasLyricPlayer({
        lyrics: this.lyrics,
        currentTime: this.currentTime,
        isPlaying: this.isPlaying
      })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
