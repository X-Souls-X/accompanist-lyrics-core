# 项目结构说明

## 📁 目录结构

```
arkts/
│
├── models/                          # 数据模型层
│   └── LyricModels.ets             # 歌词数据模型 (LyricWord, LyricLine)
│
├── utils/                           # 工具类层
│   ├── Spring.ets                  # 弹簧动画系统
│   └── TextLayout.ets              # 文本布局引擎
│
├── components/                      # 组件层
│   └── LyricPlayer.ets             # 主歌词播放器组件
│
├── demo/                            # 示例代码
│   ├── SimpleExample.ets           # 简单使用示例
│   └── DemoPage.ets                # 完整演示页面
│
├── README.md                        # 使用文档
├── API.md                           # API参考文档
└── PROJECT_STRUCTURE.md             # 本文件
```

## 📄 文件说明

### 数据模型 (models/)

#### LyricModels.ets
- **LyricWord 类**: 表示歌词中的单个单词/字符
  - 包含时间信息(开始/结束时间)
  - 支持音译和不雅词标记

- **LyricLine 类**: 表示一行完整的歌词
  - 包含多个LyricWord
  - 支持翻译、音译
  - 支持背景歌词和对唱歌词标记

### 工具类 (utils/)

#### Spring.ets
- **Spring 类**: 物理弹簧动画实现
  - 基于物理公式的平滑动画
  - 支持质量、阻尼、刚度参数调节
  - 用于歌词位置和缩放的平滑过渡

#### TextLayout.ets
- **TextLayoutEngine 类**: 文本布局引擎
  - 自动处理CJK字符和拉丁字符
  - 智能换行(保持英文单词完整性)
  - 生成文本布局结果供渲染使用

### 组件 (components/)

#### LyricPlayer.ets
- **LyricLineRenderer 类**: 单行歌词渲染器
  - 负责单行歌词的布局和渲染
  - 使用离屏Canvas缓存提升性能
  - 管理单行的变换状态(位置、缩放、透明度)

- **CanvasLyricPlayer 组件**: 主歌词播放器
  - Canvas绘制歌词
  - 管理所有歌词行的状态
  - 处理播放逻辑和动画更新
  - 暴露API供外部调用

### 示例 (demo/)

#### SimpleExample.ets
- 最简单的使用示例
- 展示基本API调用
- 适合快速上手

#### DemoPage.ets
- 完整的演示页面
- 包含播放控制UI
- 进度条、播放/暂停按钮
- 展示完整的使用场景

## 🔄 数据流

```
用户设置歌词
    ↓
LyricLine[] → CanvasLyricPlayer
    ↓
创建 LyricLineRenderer[]
    ↓
使用 TextLayoutEngine 布局文本
    ↓
渲染到离屏Canvas缓存
    ↓
根据播放时间更新状态
    ↓
使用 Spring 计算动画位置
    ↓
绘制到主Canvas
```

## 🎨 渲染流程

1. **初始化阶段**:
   - 创建Canvas上下文
   - 设置字体和样式参数

2. **布局阶段**:
   - 使用TextLayoutEngine布局每行歌词
   - 计算每行的宽高
   - 创建离屏Canvas缓存

3. **更新阶段** (每帧):
   - 根据当前时间更新热行(hotLines)
   - 计算每行的目标位置和状态
   - 更新弹簧动画

4. **渲染阶段** (每帧):
   - 清空主Canvas
   - 应用变换(位置、缩放、透明度、模糊)
   - 从离屏Canvas绘制到主Canvas

## 🎯 核心概念

### 热行 (Hot Lines)
- 当前正在播放时间范围内的歌词行
- 用于高亮显示当前歌词

### 缓冲行 (Buffered Lines)
- 包含热行和即将播放的歌词行
- 用于平滑过渡效果

### 间奏 (Interlude)
- 歌词行之间的空白时间
- 超过4秒会显示间奏点动画

### 弹簧动画
- 基于物理的平滑动画
- 相比CSS transition更自然
- 可调节物理参数

## 🛠️ 技术选型

### 为什么使用Canvas?
- ✅ 更高的渲染性能
- ✅ 更灵活的动画控制
- ✅ 支持复杂的视觉效果(模糊、渐变)
- ✅ 减少DOM节点数量

### 为什么使用弹簧动画?
- ✅ 更自然的运动效果
- ✅ 符合物理直觉
- ✅ 可精确控制运动特性
- ✅ Apple设计规范推荐

### 为什么使用离屏Canvas?
- ✅ 缓存渲染结果
- ✅ 减少重复绘制
- ✅ 提升整体性能
- ✅ 降低CPU使用率

## 📊 性能考虑

### 优化点:
1. **离屏渲染**: 文本只渲染一次,后续使用缓存
2. **视口裁剪**: 只渲染可见区域的歌词
3. **请求动画帧**: 使用requestAnimationFrame同步屏幕刷新
4. **弹簧缓存**: 到达目标位置后停止计算

### 性能指标:
- 建议歌词行数: < 1000行
- 推荐更新频率: 50ms (20fps)
- 目标渲染帧率: 60fps

## 🔧 扩展性

### 可扩展点:
1. **自定义渲染器**: 继承LyricLineRenderer实现自定义效果
2. **自定义布局**: 实现TextLayoutEngine接口
3. **自定义动画**: 替换Spring为其他动画系统
4. **主题系统**: 添加样式配置接口

### 未来功能:
- [ ] 歌词编辑器
- [ ] LRC格式导入/导出
- [ ] 更多视觉效果
- [ ] 歌词同步工具

## 📝 编码规范

### 命名约定:
- 类名: PascalCase (如: `LyricLine`)
- 方法名: camelCase (如: `setCurrentTime`)
- 私有属性: 前缀 `private` (如: `private currentTime`)
- 常量: UPPER_SNAKE_CASE (如: `MAX_LINES`)

### 注释规范:
- 所有公共API必须有JSDoc注释
- 中英文双语注释
- 复杂逻辑添加行内注释

## 🐛 常见问题

### 歌词不显示?
- 检查Canvas是否正确初始化
- 检查歌词数据格式是否正确
- 检查是否调用了setLyrics()

### 动画不流畅?
- 检查更新频率是否过低
- 检查歌词行数是否过多
- 尝试禁用模糊效果

### 内存占用过高?
- 减少离屏Canvas的尺寸
- 减少同时渲染的歌词行数
- 及时释放不用的资源

## 📚 参考资料

- [HarmonyOS Canvas API](https://developer.harmonyos.com/)
- [Apple Music Design Guidelines](https://developer.apple.com/design/)
- [Spring Animation Theory](https://github.com/pushkine/)

---

**文档版本**: 1.0.0
**最后更新**: 2024
