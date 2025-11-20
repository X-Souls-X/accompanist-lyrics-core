# AppleMusic-like Lyrics Player for HarmonyOS

🎵 鸿蒙版 AppleMusic 风格歌词播放器

一个基于 Canvas 实现的流畅、美观的歌词播放器组件，适用于鸿蒙(HarmonyOS)应用开发。

## ✨ 特性

- 🎨 **AppleMusic 风格设计** - 高度还原 Apple Music 的歌词显示效果
- 🌊 **流畅的物理动画** - 基于弹簧物理系统的平滑过渡动画
- 📝 **多语言支持** - 支持主歌词、翻译歌词和音译歌词同时显示
- 🎭 **背景和对唱歌词** - 支持背景人声和对唱歌词行
- 🎯 **精确的时间同步** - 逐词级别的时间控制
- 🚀 **高性能渲染** - 使用 Canvas 和离屏缓存优化性能
- 🎪 **丰富的视觉效果** - 支持缩放、模糊、不透明度等动画效果

## 📦 项目结构

```
arkts/
├── models/           # 数据模型
│   └── LyricModels.ets      # 歌词数据结构(LyricWord, LyricLine)
├── utils/            # 工具类
│   ├── Spring.ets           # 弹簧动画系统
│   └── TextLayout.ets       # 文本布局引擎
├── components/       # 组件
│   └── LyricPlayer.ets      # 主歌词播放器组件
├── demo/            # 示例代码
│   ├── SimpleExample.ets    # 简单示例
│   └── DemoPage.ets         # 完整演示页面
└── README.md        # 本文档
```

## 🚀 快速开始

### 1. 基本使用

```typescript
import { CanvasLyricPlayer } from '../components/LyricPlayer';
import { LyricLine, LyricWord } from '../models/LyricModels';

@Entry
@Component
struct MyPage {
  private lyricPlayer: CanvasLyricPlayer | null = null;

  build() {
    Column() {
      CanvasLyricPlayer()
        .width('100%')
        .height('100%')
        .onAppear(() => {
          // 创建歌词数据
          const lyrics: LyricLine[] = [
            new LyricLine(
              [
                new LyricWord('Hello', 0, 1000),
                new LyricWord(' ', 1000, 1100),
                new LyricWord('World', 1100, 2000)
              ],
              0,          // 开始时间(ms)
              2000,       // 结束时间(ms)
              '你好世界', // 翻译
              '',         // 音译
              false,      // 是否为背景歌词
              false       // 是否为对唱歌词
            )
          ];

          // 设置歌词
          this.lyricPlayer?.setLyrics(lyrics);

          // 开始播放
          this.lyricPlayer?.play();
        })
    }
  }
}
```

### 2. 更新播放进度

```typescript
// 在音频播放进度更新时调用
let currentTime = 0;
setInterval(() => {
  currentTime += 50;  // 毫秒
  this.lyricPlayer?.setCurrentTime(currentTime);
}, 50);
```

### 3. 播放控制

```typescript
// 播放
this.lyricPlayer?.play();

// 暂停
this.lyricPlayer?.pause();

// 跳转到指定时间
this.lyricPlayer?.setCurrentTime(5000); // 跳转到5秒
```

## 📖 详细文档

### LyricWord 类

表示歌词中的一个单词或字符。

```typescript
class LyricWord {
  startTime: number;    // 开始时间(毫秒)
  endTime: number;      // 结束时间(毫秒)
  word: string;         // 单词内容
  romanWord: string;    // 音译内容
  obscene: boolean;     // 是否包含不雅用语
}
```

**构造函数:**
```typescript
new LyricWord(
  word: string,           // 单词内容
  startTime: number,      // 开始时间
  endTime: number,        // 结束时间
  romanWord?: string,     // 音译(可选)
  obscene?: boolean       // 是否不雅(可选,默认false)
)
```

### LyricLine 类

表示一行歌词。

```typescript
class LyricLine {
  words: LyricWord[];       // 单词数组
  translatedLyric: string;  // 翻译歌词
  romanLyric: string;       // 音译歌词
  startTime: number;        // 开始时间(毫秒)
  endTime: number;          // 结束时间(毫秒)
  isBG: boolean;            // 是否为背景歌词
  isDuet: boolean;          // 是否为对唱歌词
}
```

**构造函数:**
```typescript
new LyricLine(
  words: LyricWord[],           // 单词数组
  startTime: number,            // 开始时间
  endTime: number,              // 结束时间
  translatedLyric?: string,     // 翻译(可选)
  romanLyric?: string,          // 音译(可选)
  isBG?: boolean,               // 背景歌词(可选,默认false)
  isDuet?: boolean              // 对唱歌词(可选,默认false)
)
```

**方法:**
- `getFullText(): string` - 获取该行的完整文本内容

### CanvasLyricPlayer 组件

主歌词播放器组件。

**方法:**

- `setLyrics(lyrics: LyricLine[]): void`
  - 设置歌词数据
  - 参数: lyrics - 歌词行数组

- `setCurrentTime(time: number): void`
  - 设置当前播放时间
  - 参数: time - 当前时间(毫秒)

- `play(): void`
  - 开始播放

- `pause(): void`
  - 暂停播放

## 🎨 高级功能

### 背景歌词

背景歌词用于显示和声或背景人声，当主歌词行被激活时会同时显示:

```typescript
new LyricLine(
  [new LyricWord('啊~', 5000, 7000)],
  5000,
  7000,
  '',
  '',
  true,  // isBG = true 表示这是背景歌词
  false
)
```

### 对唱歌词

对唱歌词会靠右对齐显示:

```typescript
new LyricLine(
  words,
  10000,
  12000,
  '',
  '',
  false,
  true   // isDuet = true 表示这是对唱歌词
)
```

### 翻译和音译

每行歌词都可以有翻译和音译:

```typescript
new LyricLine(
  [new LyricWord('さくら', 0, 2000)],
  0,
  2000,
  '樱花',           // translatedLyric - 翻译
  'sakura',         // romanLyric - 音译
  false,
  false
)
```

## 🎯 完整示例

请查看 `demo/` 目录:

- **SimpleExample.ets** - 最简单的使用示例
- **DemoPage.ets** - 包含完整UI的演示页面

运行演示:
```bash
# 在DevEco Studio中打开项目
# 选择demo/DemoPage.ets作为入口
# 点击运行
```

## ⚙️ 技术细节

### 动画系统

使用物理弹簧算法实现平滑的动画过渡:

```typescript
// 弹簧参数
interface SpringParams {
  mass: number;        // 质量
  damping: number;     // 阻尼
  stiffness: number;   // 刚度
  soft: boolean;       // 软模式
}
```

默认参数:
- 位置动画: `{ mass: 0.9, damping: 15, stiffness: 90 }`
- 缩放动画: `{ mass: 2, damping: 25, stiffness: 100 }`

### 文本布局

自动处理:
- ✅ CJK字符(中文、日文、韩文)
- ✅ 拉丁字符(保持单词完整性)
- ✅ 自动换行
- ✅ 多行布局

### 性能优化

- 使用 `OffscreenCanvas` 预渲染歌词行
- 只渲染可见区域内的歌词
- 使用弹簧动画缓存减少计算

## 📝 数据格式示例

```typescript
const sampleLyrics: LyricLine[] = [
  // 普通歌词行
  new LyricLine(
    [
      new LyricWord('如', 0, 500),
      new LyricWord('果', 500, 1000),
      new LyricWord('有', 1000, 1500),
      new LyricWord('一', 1500, 2000),
      new LyricWord('天', 2000, 2500)
    ],
    0,
    2500,
    'If one day',
    '',
    false,
    false
  ),

  // 英文歌词(保持单词完整)
  new LyricLine(
    [
      new LyricWord('I', 3000, 3300),
      new LyricWord(' ', 3300, 3400),
      new LyricWord('love', 3400, 4000),
      new LyricWord(' ', 4000, 4100),
      new LyricWord('you', 4100, 4500)
    ],
    3000,
    4500,
    '我爱你',
    '',
    false,
    false
  )
];
```

## 🔧 常见问题

### Q: 如何与音频播放器同步?

A: 在音频播放器的进度更新回调中调用 `setCurrentTime`:

```typescript
audioPlayer.on('timeUpdate', (time) => {
  this.lyricPlayer?.setCurrentTime(time);
});
```

### Q: 歌词行之间的间奏如何处理?

A: 组件会自动处理间奏，如果间奏时间>=4秒，会显示间奏点动画。

### Q: 如何自定义样式?

A: 目前版本使用固定样式，未来版本会支持样式自定义。

## 📄 License

本项目基于原项目 [applemusic-like-lyrics](https://github.com/Steve-xmh/applemusic-like-lyrics) 转换为鸿蒙ArkTS版本。

- 原项目: MIT License
- 本项目: Apache License 2.0

## 🙏 致谢

- 原项目作者: [Steve-xmh](https://github.com/Steve-xmh)
- 弹簧动画系统: [pushkine](https://github.com/pushkine/)

## 📞 支持

如有问题或建议,请提交 Issue 或 Pull Request。

---

Made with ❤️ for HarmonyOS
