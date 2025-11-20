# ArkTS 语法修复说明

## 修复的主要问题

### 1. 对象展开运算符 (Object Spread Operator)

**问题**: ArkTS 不支持 `...` 展开对象

**错误代码**:
```typescript
// ❌ 错误
const merged = { ...obj1, ...obj2 };
currentLine = { ...result };
```

**修复后**:
```typescript
// ✅ 正确 - 手动复制属性
const merged = {
  prop1: obj1.prop1,
  prop2: obj2.prop2
};

currentLine = {
  text: result.text,
  index: result.index,
  lineIndex: result.lineIndex,
  width: result.width,
  height: result.height,
  x: result.x
};
```

**影响文件**:
- `utils/Spring.ets` (3处修复)
- `utils/TextLayout.ets` (1处修复)

---

### 2. Canvas API 类型错误

**问题**: 使用了错误的 Canvas API 类型名称

**错误代码**:
```typescript
// ❌ 错误
private renderingContext: RenderingContext | null = null;
private settings: CanvasRenderingContext2DSettings = new CanvasRenderingContext2DSettings(true);
```

**修复后**:
```typescript
// ✅ 正确
private canvasContext: CanvasRenderingContext2D | null = null;
private settings: RenderingContextSettings = new RenderingContextSettings(true);
```

**影响文件**:
- `components/LyricPlayer.ets`

---

### 3. Set 遍历方式

**问题**: 使用了不兼容的 Set 转换方式

**错误代码**:
```typescript
// ❌ 可能不兼容
const minIndex = Math.min(...Array.from(this.bufferedLines));
```

**修复后**:
```typescript
// ✅ 正确 - 使用 forEach
let minIndex = Number.MAX_VALUE;
this.bufferedLines.forEach((value: number) => {
  if (value < minIndex) minIndex = value;
});
```

**影响文件**:
- `components/LyricPlayer.ets`

---

### 4. 数组类型定义

**问题**: 使用了元组类型

**错误代码**:
```typescript
// ❌ ArkTS 对元组支持有限
private lineSize: [number, number] = [0, 0];
```

**修复后**:
```typescript
// ✅ 正确 - 使用普通数组
private lineSize: number[] = [0, 0];
```

**影响文件**:
- `components/LyricPlayer.ets`

---

### 5. Canvas 绘制 API

**问题**: 使用了错误的 Canvas 绘制方法

**错误代码**:
```typescript
// ❌ 错误
context.drawImage(this.lineCanvas, 0, 0);
```

**修复后**:
```typescript
// ✅ 正确 - 使用 OffscreenCanvas 的正确方法
const image = this.lineCanvas.transferToImageBitmap();
context.transferFromImageBitmap(image);
```

**影响文件**:
- `components/LyricPlayer.ets`

---

### 6. 动画循环

**问题**: requestAnimationFrame 可能不可用

**错误代码**:
```typescript
// ❌ 可能不支持
requestAnimationFrame(loop);
```

**修复后**:
```typescript
// ✅ 正确 - 使用 setTimeout
setTimeout(() => loop(), 16); // 约60fps
```

**影响文件**:
- `components/LyricPlayer.ets`

---

## 修复后的代码结构

### Spring.ets
```typescript
// 手动合并对象参数
updateParams(params: Partial<SpringParams>, delay: number = 0): void {
  if (delay > 0) {
    const merged: Partial<SpringParams> & { time: number } = { time: delay };
    const existing = this.queueParams ?? {};
    // 手动复制每个属性
    if (existing.mass !== undefined) merged.mass = existing.mass;
    if (existing.damping !== undefined) merged.damping = existing.damping;
    // ... 其他属性
    if (params.mass !== undefined) merged.mass = params.mass;
    if (params.damping !== undefined) merged.damping = params.damping;
    // ... 其他属性
    this.queueParams = merged;
  } else {
    // 直接修改属性
    if (params.mass !== undefined) this.params.mass = params.mass;
    if (params.damping !== undefined) this.params.damping = params.damping;
    // ...
  }
}
```

### TextLayout.ets
```typescript
// 手动复制布局结果对象
mergeLines(results: TextLayoutResult[]): TextLayoutResult[] {
  const merged: TextLayoutResult[] = [];
  let currentLine: TextLayoutResult | null = null;

  for (const result of results) {
    if (!currentLine || currentLine.lineIndex !== result.lineIndex) {
      if (currentLine) {
        merged.push(currentLine);
      }
      // 手动复制所有属性
      currentLine = {
        text: result.text,
        index: result.index,
        lineIndex: result.lineIndex,
        width: result.width,
        height: result.height,
        x: result.x
      };
    } else {
      currentLine.text += result.text;
      currentLine.width = result.x + result.width - currentLine.x;
    }
  }

  return merged;
}
```

### LyricPlayer.ets
```typescript
// 正确的 Canvas API 使用
@Component
export struct CanvasLyricPlayer {
  private canvasContext: CanvasRenderingContext2D | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);

  build() {
    Canvas(this.canvasContext)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.canvasContext = new CanvasRenderingContext2D(this.settings);
        // ...
      })
  }
}
```

---

## 测试建议

### 1. 编译测试
```bash
# 在 DevEco Studio 中编译项目
# 确保没有 ArkTS 语法错误
```

### 2. 运行测试
- 测试 SimpleExample.ets 简单示例
- 测试 DemoPage.ets 完整演示
- 验证动画流畅性
- 验证歌词显示正确

### 3. 性能测试
- 监控内存使用
- 检查 Canvas 渲染性能
- 验证弹簧动画平滑度

---

## 已知限制

1. **Canvas 宽高**: 当前使用固定值，需要根据实际组件大小动态获取
2. **字体**: 使用系统默认字体 'HarmonyOS Sans'
3. **渲染频率**: 使用 setTimeout 而非 requestAnimationFrame

---

## 后续优化建议

1. **动态获取 Canvas 尺寸**: 从组件实际大小获取宽高
2. **优化渲染循环**: 如果鸿蒙支持，使用原生动画 API
3. **添加错误处理**: 增加更多的边界检查和错误提示
4. **性能优化**: 考虑使用 Web Worker 或其他并发方案

---

## 版本信息

- **修复版本**: v1.0.1
- **修复日期**: 2024-11-20
- **ArkTS 版本**: 兼容 HarmonyOS 4.0+

---

## 参考文档

- [HarmonyOS Canvas 组件文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-drawing-customization-on-canvas)
- [ArkTS 语法规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-basic-syntax-overview)
