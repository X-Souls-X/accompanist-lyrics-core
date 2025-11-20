# 修复和调试说明 / Fixes and Debugging Guide

## 主要问题 / Main Issues Fixed

### 1. Canvas API 错误 / Canvas API Errors

**问题 / Problem:**
- `Canvas(this.canvasContext)` 的使用不正确
- `context.transferFromImageBitmap(image)` API 不存在
- `context.filter` 属性在 HarmonyOS 中可能不支持

**修复 / Fixes:**
- 修改了 build() 方法，正确初始化 Canvas 组件
- 在 onReady 回调中初始化 CanvasRenderingContext2D
- 使用 `drawImage()` 替代不存在的 `transferFromImageBitmap()`
- 暂时禁用了 filter 属性

### 2. Import 错误 / Import Errors

**问题 / Problem:**
- 使用了 `SpringParams` 但应该使用 `PartialSpringParams`
- `PartialSpringParams` 没有导出

**修复 / Fixes:**
- 将所有 `SpringParams` 引用改为 `PartialSpringParams`
- 在 Spring.ets 中导出 `PartialSpringParams` 接口

### 3. 渲染管道问题 / Rendering Pipeline Issues

**问题 / Problem:**
- OffscreenCanvas 的使用可能存在兼容性问题
- 缺少调试信息，无法判断问题所在

**修复 / Fixes:**
- 添加了直接渲染方法 `renderDirect()`，不依赖 OffscreenCanvas
- 如果 OffscreenCanvas 失败，自动回退到直接渲染
- 添加了大量调试日志和可视化调试信息

## 调试功能 / Debug Features

### 1. 可视化调试 / Visual Debug

渲染帧现在包含以下调试信息：
- 红色边框：确认 Canvas 正常工作
- 深灰色背景：便于看清文字
- 绿色调试文本：显示关键信息
  - Canvas 尺寸
  - 歌词行数
  - 当前播放时间
  - 播放状态

### 2. 控制台日志 / Console Logs

关键事件都会输出日志：
- Canvas 初始化
- 歌词数据加载
- 布局计算
- 渲染循环启动
- 错误信息

查看日志的标签前缀：
- `[LyricPlayer]` - 主组件日志
- `[LyricLineRenderer]` - 行渲染器日志

### 3. 帧率监控 / FPS Monitoring

每60帧打印一次帧率信息，确认渲染循环正常运行。

## 使用建议 / Usage Recommendations

### 检查步骤 / Check Steps

1. **确认 Canvas 显示**
   - 应该能看到红色边框和深灰色背景
   - 如果看不到，说明 Canvas 组件本身有问题

2. **检查调试文本**
   - 应该能看到绿色的调试信息
   - "Lyrics: X lines" 应该显示正确的歌词行数
   - 如果显示 "No lyrics loaded"，说明数据传递有问题

3. **查看控制台日志**
   - 查找 `[LyricPlayer]` 开头的日志
   - 确认初始化和渲染循环都正常启动

4. **检查歌词渲染**
   - 如果能看到白色歌词文本，说明渲染成功
   - 如果看不到，检查日志中的错误信息

### 常见问题 / Common Issues

1. **完全空白 / Completely Blank**
   - 检查 Canvas 组件是否正确挂载
   - 检查组件的宽高是否设置正确
   - 查看控制台是否有错误日志

2. **只有调试信息，没有歌词 / Only Debug Info, No Lyrics**
   - 检查歌词数据是否正确传递给组件
   - 查看 "Lyrics: X lines" 显示的数量
   - 检查日志中的 "initLyrics" 相关信息

3. **渲染卡顿 / Rendering Stutters**
   - 查看 FPS 日志
   - 检查是否有大量错误日志
   - 考虑禁用 OffscreenCanvas（已自动回退）

## 下一步优化 / Next Optimizations

1. **Canvas 尺寸**
   - 当前使用固定的 800x600
   - 需要动态获取实际组件尺寸

2. **OffscreenCanvas 兼容性**
   - 验证 HarmonyOS 对 OffscreenCanvas 的支持
   - 如果不支持，完全移除相关代码

3. **性能优化**
   - 测试直接渲染 vs OffscreenCanvas 的性能
   - 减少不必要的重绘

4. **移除调试代码**
   - 确认渲染正常后，可以移除调试边框和文本
   - 保留关键的日志输出

## 文件修改列表 / Modified Files

1. `arkts/components/LyricPlayer.ets`
   - 修复 Canvas API 使用
   - 添加调试渲染
   - 修改 import 语句
   - 添加详细日志

2. `arkts/utils/Spring.ets`
   - 导出 `PartialSpringParams` 接口

3. `arkts/DEBUG_FIXES.md` (新增)
   - 本文档
