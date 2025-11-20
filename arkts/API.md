# API 文档

## 核心类

### LyricWord

歌词单词类,表示歌词中的一个单词或字符。

#### 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `startTime` | `number` | 单词开始时间(毫秒) |
| `endTime` | `number` | 单词结束时间(毫秒) |
| `word` | `string` | 单词内容 |
| `romanWord` | `string` | 音译内容 |
| `obscene` | `boolean` | 是否包含不雅用语 |

#### 构造函数

```typescript
constructor(
  word: string,
  startTime: number,
  endTime: number,
  romanWord: string = '',
  obscene: boolean = false
)
```

**参数:**
- `word` - 单词内容
- `startTime` - 开始时间(毫秒)
- `endTime` - 结束时间(毫秒)
- `romanWord` - 音译内容(可选,默认为空字符串)
- `obscene` - 是否包含不雅用语(可选,默认为false)

**示例:**
```typescript
// 中文字
const word1 = new LyricWord('你', 0, 500);

// 英文单词
const word2 = new LyricWord('Hello', 1000, 2000);

// 带音译的日文
const word3 = new LyricWord('さくら', 3000, 5000, 'sakura');
```

---

### LyricLine

歌词行类,表示一行完整的歌词。

#### 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `words` | `LyricWord[]` | 该行的所有单词 |
| `translatedLyric` | `string` | 翻译歌词 |
| `romanLyric` | `string` | 音译歌词 |
| `startTime` | `number` | 句子开始时间(毫秒) |
| `endTime` | `number` | 句子结束时间(毫秒) |
| `isBG` | `boolean` | 是否为背景歌词行 |
| `isDuet` | `boolean` | 是否为对唱歌词行 |

#### 构造函数

```typescript
constructor(
  words: LyricWord[],
  startTime: number,
  endTime: number,
  translatedLyric: string = '',
  romanLyric: string = '',
  isBG: boolean = false,
  isDuet: boolean = false
)
```

**参数:**
- `words` - 单词数组
- `startTime` - 开始时间(毫秒)
- `endTime` - 结束时间(毫秒)
- `translatedLyric` - 翻译歌词(可选)
- `romanLyric` - 音译歌词(可选)
- `isBG` - 是否为背景歌词(可选,默认false)
- `isDuet` - 是否为对唱歌词(可选,默认false)

#### 方法

##### getFullText()

获取该行歌词的完整文本。

```typescript
getFullText(): string
```

**返回值:** 完整的歌词文本

**示例:**
```typescript
const line = new LyricLine(
  [
    new LyricWord('Hello', 0, 1000),
    new LyricWord(' ', 1000, 1100),
    new LyricWord('World', 1100, 2000)
  ],
  0,
  2000
);

console.log(line.getFullText()); // 输出: "Hello World"
```

**示例:**
```typescript
// 普通歌词行
const normalLine = new LyricLine(
  [
    new LyricWord('如', 0, 500),
    new LyricWord('果', 500, 1000)
  ],
  0,
  1000,
  'If',
  '',
  false,
  false
);

// 背景歌词行
const bgLine = new LyricLine(
  [new LyricWord('啊~', 2000, 4000)],
  2000,
  4000,
  '',
  '',
  true,  // isBG
  false
);

// 对唱歌词行
const duetLine = new LyricLine(
  [new LyricWord('你好', 5000, 6000)],
  5000,
  6000,
  'Hello',
  '',
  false,
  true   // isDuet
);
```

---

### CanvasLyricPlayer

Canvas歌词播放器组件。

#### 方法

##### setLyrics()

设置歌词数据。

```typescript
setLyrics(lyrics: LyricLine[]): void
```

**参数:**
- `lyrics` - 歌词行数组

**示例:**
```typescript
const lyrics: LyricLine[] = [
  new LyricLine([...], 0, 2000),
  new LyricLine([...], 3000, 5000)
];

this.lyricPlayer?.setLyrics(lyrics);
```

---

##### setCurrentTime()

设置当前播放时间。

```typescript
setCurrentTime(time: number): void
```

**参数:**
- `time` - 当前时间(毫秒)

**示例:**
```typescript
// 跳转到5秒位置
this.lyricPlayer?.setCurrentTime(5000);

// 在定时器中更新
setInterval(() => {
  currentTime += 50;
  this.lyricPlayer?.setCurrentTime(currentTime);
}, 50);
```

---

##### play()

开始播放(启用动画效果)。

```typescript
play(): void
```

**示例:**
```typescript
this.lyricPlayer?.play();
```

---

##### pause()

暂停播放(暂停动画效果)。

```typescript
pause(): void
```

**示例:**
```typescript
this.lyricPlayer?.pause();
```

---

## 工具类

### Spring

弹簧动画类,用于实现平滑的物理动画。

#### 接口

##### SpringParams

弹簧参数接口。

```typescript
interface SpringParams {
  mass: number;        // 质量
  damping: number;     // 阻尼
  stiffness: number;   // 刚度
  soft: boolean;       // 软模式
}
```

#### 构造函数

```typescript
constructor(currentPosition: number = 0)
```

#### 方法

##### setPosition()

直接设置位置(无动画)。

```typescript
setPosition(targetPosition: number): void
```

##### setTargetPosition()

设置目标位置(使用动画)。

```typescript
setTargetPosition(targetPosition: number, delay: number = 0): void
```

##### update()

更新动画状态。

```typescript
update(delta: number = 0): void
```

**参数:**
- `delta` - 时间增量(秒)

##### getCurrentPosition()

获取当前位置。

```typescript
getCurrentPosition(): number
```

##### updateParams()

更新弹簧参数。

```typescript
updateParams(params: Partial<SpringParams>, delay: number = 0): void
```

##### arrived()

判断是否到达目标位置。

```typescript
arrived(): boolean
```

---

### TextLayoutEngine

文本布局引擎。

#### 接口

##### TextLayoutConfig

文本布局配置。

```typescript
interface TextLayoutConfig {
  fontSize: number;      // 字体大小
  maxWidth: number;      // 最大宽度
  lineHeight: number;    // 行高
  uniformSpace: boolean; // 是否统一空格宽度
}
```

##### TextLayoutResult

文本布局结果。

```typescript
interface TextLayoutResult {
  text: string;      // 文本内容
  index: number;     // 字符索引
  lineIndex: number; // 行索引
  width: number;     // 宽度
  height: number;    // 高度
  x: number;         // X坐标
}
```

#### 构造函数

```typescript
constructor(
  context: CanvasRenderingContext2D,
  config: TextLayoutConfig
)
```

#### 方法

##### layoutLine()

对文本进行布局。

```typescript
layoutLine(text: string, initialX: number = 0): TextLayoutResult[]
```

##### mergeLines()

合并同行的布局结果。

```typescript
mergeLines(results: TextLayoutResult[]): TextLayoutResult[]
```

---

## 使用模式

### 基本模式

```typescript
@Component
struct MyLyricPage {
  private lyricPlayer: CanvasLyricPlayer | null = null;

  build() {
    CanvasLyricPlayer()
      .width('100%')
      .height('100%')
      .onAppear(() => {
        // 设置歌词
        this.lyricPlayer?.setLyrics(myLyrics);
        // 开始播放
        this.lyricPlayer?.play();
      })
  }
}
```

### 与音频同步模式

```typescript
@Component
struct AudioLyricSync {
  private lyricPlayer: CanvasLyricPlayer | null = null;
  private audioPlayer: AudioPlayer;

  aboutToAppear() {
    this.audioPlayer = new AudioPlayer();

    // 监听音频进度
    this.audioPlayer.on('timeUpdate', (time) => {
      this.lyricPlayer?.setCurrentTime(time);
    });
  }

  build() {
    Column() {
      CanvasLyricPlayer()
        .layoutWeight(1)
    }
  }
}
```

### 可控播放模式

```typescript
@Component
struct ControlledLyricPlayer {
  @State currentTime: number = 0;
  @State isPlaying: boolean = false;
  private lyricPlayer: CanvasLyricPlayer | null = null;

  togglePlay() {
    this.isPlaying = !this.isPlaying;
    if (this.isPlaying) {
      this.lyricPlayer?.play();
    } else {
      this.lyricPlayer?.pause();
    }
  }

  seekTo(time: number) {
    this.currentTime = time;
    this.lyricPlayer?.setCurrentTime(time);
  }

  build() {
    Column() {
      CanvasLyricPlayer()
        .layoutWeight(1)

      Button(this.isPlaying ? '暂停' : '播放')
        .onClick(() => this.togglePlay())
    }
  }
}
```

---

## 常量和默认值

### 默认弹簧参数

```typescript
// 位置动画
posYSpringParams = {
  mass: 0.9,
  damping: 15,
  stiffness: 90
}

// 缩放动画
scaleSpringParams = {
  mass: 2,
  damping: 25,
  stiffness: 100
}
```

### 默认样式参数

```typescript
baseFontSize = 30          // 基础字体大小
fontFamily = 'HarmonyOS Sans'  // 字体
alignPosition = 0.35       // 对齐位置(0-1)
enableBlur = true          // 启用模糊效果
enableScale = true         // 启用缩放效果
```

---

## 事件和回调

目前版本暂不支持自定义事件回调,未来版本将添加:

- `onLineChange` - 当前行改变时
- `onWordChange` - 当前词改变时
- `onInterlude` - 间奏开始/结束时

---

## 注意事项

1. **时间单位**: 所有时间参数都以毫秒(ms)为单位
2. **坐标系统**: 使用Canvas 2D坐标系统,原点在左上角
3. **性能**: 建议歌词行数不超过1000行
4. **内存**: 组件会缓存离屏Canvas,注意内存使用
5. **更新频率**: 建议每50ms更新一次播放时间

---

## 版本历史

### v1.0.0 (当前版本)
- ✅ 基础歌词播放功能
- ✅ 弹簧动画系统
- ✅ 文本自动布局
- ✅ 背景歌词和对唱歌词支持
- ✅ 翻译和音译支持

### 计划功能
- ⏳ 自定义样式支持
- ⏳ 事件回调系统
- ⏳ 歌词编辑功能
- ⏳ 导出为LRC格式

---

**文档版本**: 1.0.0
**最后更新**: 2024
