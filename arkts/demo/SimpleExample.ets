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
  private lyricPlayer: CanvasLyricPlayer | null = null;

  build() {
    Column() {
      // 歌词播放器
      CanvasLyricPlayer()
        .width('100%')
        .height('100%')
        .onAppear(() => {
          // 1. 创建歌词数据
          const lyrics: LyricLine[] = [
            new LyricLine(
              [
                new LyricWord('Hello', 0, 1000),
                new LyricWord(' ', 1000, 1100),
                new LyricWord('World', 1100, 2000)
              ],
              0,          // 开始时间
              2000,       // 结束时间
              '你好世界', // 翻译
              '',         // 音译
              false,      // 是否为背景歌词
              false       // 是否为对唱歌词
            ),
            new LyricLine(
              [
                new LyricWord('Welcome', 3000, 4000),
                new LyricWord(' ', 4000, 4100),
                new LyricWord('to', 4100, 4500),
                new LyricWord(' ', 4500, 4600),
                new LyricWord('HarmonyOS', 4600, 6000)
              ],
              3000,
              6000,
              '欢迎来到鸿蒙',
              '',
              false,
              false
            )
          ];

          // 2. 设置歌词
          this.lyricPlayer?.setLyrics(lyrics);

          // 3. 开始播放
          this.lyricPlayer?.play();

          // 4. 模拟播放进度更新
          let currentTime = 0;
          setInterval(() => {
            currentTime += 50;
            this.lyricPlayer?.setCurrentTime(currentTime);

            // 循环播放
            if (currentTime > 7000) {
              currentTime = 0;
            }
          }, 50);
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
