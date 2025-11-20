# Canvas 渲染问题诊断指南

## 问题现象
Canvas 组件无法绘制任何内容，连红色边框都看不到。

## 诊断步骤

### 1. 检查控制台日志

运行应用后，按照以下顺序查找日志：

#### 步骤 1: Canvas 初始化
```
应该看到：
[LyricPlayer] 🎨 Canvas onReady event triggered
[LyricPlayer]   - Lyrics count: X
[LyricPlayer]   - Initial size: 0 x 0 (还是初始值)
```

✅ **如果看到这个** → Canvas 组件已创建
❌ **如果看不到** → Canvas 组件没有正确挂载

---

#### 步骤 2: 尺寸获取
```
应该看到：
[LyricPlayer] 📏 Area changed:
[LyricPlayer]   - Old: 0vp x 0vp
[LyricPlayer]   - New: XXXvp x XXXvp
[LyricPlayer] ✓ Valid size obtained: XXX x XXX
```

✅ **如果看到这个** → Canvas 尺寸已正确获取
❌ **如果看不到** → Canvas 没有获得有效尺寸

---

#### 步骤 3: 歌词初始化
```
应该看到：
[LyricPlayer] 🚀 First valid size, initializing lyrics...
[LyricPlayer] initLyrics called, lyrics count: X
[LyricPlayer] Created X line renderers
[LyricPlayer] ✓ Initialization complete
```

✅ **如果看到这个** → 歌词渲染器已创建
❌ **如果看不到** → 可能是：
- 没有歌词数据（lyrics.length === 0）
- Canvas 尺寸无效

---

#### 步骤 4: Animator 启动
```
应该看到：
[LyricPlayer] ⚙️ Starting render loop with Animator
[LyricPlayer] ⏱️ Initial timestamp: XXXXXXX
[LyricPlayer] ✓ Animator created successfully
[LyricPlayer] ▶️ Animator play() called - render loop should start now
[LyricPlayer] 👀 Watch for "Frame X" messages to confirm rendering is working
```

✅ **如果看到这个** → Animator 已启动
❌ **如果看不到** → Animator 创建失败

---

#### 步骤 5: 渲染帧
```
应该看到（前5帧会有详细日志）：
[LyricPlayer] 🎬 Frame 1, value: X, delta: Xms
[LyricPlayer] ✓ Canvas cleared
[LyricPlayer] ✓ Background drawn
[LyricPlayer] ✓ Red border drawn
[LyricPlayer] ✓ Debug text drawn
[LyricPlayer] ✓ Lyrics text drawn, lines: X

然后每60帧：
[LyricPlayer] 🎬 Rendered 60 frames, delta: Xms
[LyricPlayer] 🎬 Rendered 120 frames, delta: Xms
```

✅ **如果看到这个** → 渲染循环正常工作
❌ **如果看不到 Frame 消息** → Animator.onFrame 没有被调用

---

## 常见问题及解决方案

### 问题 A: 看到 "Canvas onReady" 但没有 "Area changed"

**原因：** Canvas 组件没有正确的布局容器

**解决方案：**
```typescript
// 确保 Canvas 的父容器有明确的尺寸
Column() {
  Canvas(...)
    .width('100%')
    .layoutWeight(1)  // 使用 layoutWeight
}
.width('100%')
.height('100%')  // 父容器必须有高度
```

---

### 问题 B: 看到 "Animator play() called" 但没有 "Frame X" 消息

**原因：** Animator 没有真正启动或 onFrame 没有被触发

**可能原因：**
1. `getUIContext()` 返回了无效的上下文
2. Animator API 在当前环境中不可用
3. 组件还没有正确挂载到 UI 树上

**解决方案：**
```typescript
// 在 aboutToAppear 中延迟初始化
aboutToAppear(): void {
  setTimeout(() => {
    // 确保在 UI 完全准备好后再启动
  }, 100);
}
```

---

### 问题 C: 看到 "Frame X" 但仍然看不到内容

**原因：** Canvas 绘制命令执行了但没有显示

**可能原因：**
1. Canvas 被其他组件遮挡
2. Canvas 的 z-index 太低
3. Canvas 背景色和绘制内容颜色相同

**解决方案：**
```typescript
// 检查 Canvas 的 backgroundColor
Canvas(...)
  .backgroundColor('#000000')  // 确保是黑色
  .zIndex(10)  // 提高层级
```

---

### 问题 D: 看到错误 "Invalid canvas size: 0 x 0"

**原因：** Canvas 在有效尺寸之前就尝试渲染

**解决方案：** 已在代码中添加尺寸检查，如果持续出现，检查：
```typescript
if (this.canvasWidth <= 0 || this.canvasHeight <= 0) {
  console.warn('Invalid size');
  return;  // 不绘制
}
```

---

## 测试用的最小示例

如果主组件还是不工作，使用测试组件验证 Canvas 基本功能：

### 测试文件 1: CanvasTest.ets
最简单的静态绘制测试

### 测试文件 2: CanvasAnimatorTest.ets
Animator 动画测试（已验证能工作）

运行测试组件，如果能看到内容，说明 Canvas 和 Animator 都正常工作，问题在于歌词组件的某个地方。

---

## 调试清单

运行后，逐一检查以下项目：

- [ ] 能看到 "Canvas onReady" 日志
- [ ] 能看到 "Area changed" 日志
- [ ] 能看到有效的尺寸（大于 0）
- [ ] 能看到 "initializing lyrics" 日志
- [ ] 能看到 "Animator created successfully" 日志
- [ ] 能看到 "Animator play() called" 日志
- [ ] 能看到 "Frame 1, 2, 3..." 日志
- [ ] 能看到 "Canvas cleared" 日志
- [ ] 能看到 "Background drawn" 日志
- [ ] 能看到 "Red border drawn" 日志

如果上面所有日志都能看到，但屏幕上还是空白，问题可能出在：
1. Canvas 组件被完全遮挡
2. 系统层面的问题（需要重启应用或设备）
3. Canvas 渲染结果没有正确刷新到屏幕

---

## 下一步

根据日志输出，把看到的情况告诉我：
1. 能看到哪些日志？
2. 停在哪个步骤？
3. 有没有错误信息？

这样我就能准确定位问题所在！
