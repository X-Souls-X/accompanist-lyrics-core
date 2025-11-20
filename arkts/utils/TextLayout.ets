/**
 * AppleMusic-like Lyrics Player for HarmonyOS
 * 文本布局系统 - Text Layout System
 */

/**
 * 文本布局结果
 * Text layout result for a single segment
 */
export interface TextLayoutResult {
  /** 文本内容 / Text content */
  text: string;

  /** 字符索引 / Character index */
  index: number;

  /** 行索引 / Line index */
  lineIndex: number;

  /** 宽度 / Width */
  width: number;

  /** 高度 / Height */
  height: number;

  /** X坐标 / X coordinate */
  x: number;
}

/**
 * 文本布局配置
 * Text layout configuration
 */
export interface TextLayoutConfig {
  /** 字体大小 / Font size */
  fontSize: number;

  /** 最大宽度 / Maximum width */
  maxWidth: number;

  /** 行高 / Line height */
  lineHeight: number;

  /** 是否统一空格宽度 / Whether to use uniform space width */
  uniformSpace: boolean;
}

/**
 * 判断字符是否为CJK字符（中日韩统一表意文字）
 * Check if character is CJK (Chinese, Japanese, Korean)
 */
function isCJK(char: string): boolean {
  if (!char || char.length === 0) return false;
  const code = char.charCodeAt(0);
  return (
    (code >= 0x4E00 && code <= 0x9FFF) ||   // CJK Unified Ideographs
    (code >= 0x3400 && code <= 0x4DBF) ||   // CJK Extension A
    (code >= 0x20000 && code <= 0x2A6DF) || // CJK Extension B
    (code >= 0xF900 && code <= 0xFAFF) ||   // CJK Compatibility Ideographs
    (code >= 0x2F800 && code <= 0x2FA1F) || // CJK Compatibility Ideographs Supplement
    (code >= 0x3040 && code <= 0x309F) ||   // Hiragana
    (code >= 0x30A0 && code <= 0x30FF) ||   // Katakana
    (code >= 0xAC00 && code <= 0xD7AF)      // Hangul Syllables
  );
}

/**
 * 判断字符是否为拉丁字符
 * Check if character is Latin
 */
function isLatin(char: string): boolean {
  if (!char || char.length === 0) return false;
  const latinRegex = /^[a-zA-Z0-9!"#$%&'()*+,-./:;<=>?@\[\]^_`{|}~]+$/;
  return latinRegex.test(char);
}

/**
 * 判断字符是否为空白字符
 * Check if character is whitespace
 */
function isWhitespace(char: string): boolean {
  return /^\s$/.test(char);
}

/**
 * 文本布局器
 * Text layout engine for multi-line text rendering
 */
export class TextLayoutEngine {
  private context: CanvasRenderingContext2D;
  private config: TextLayoutConfig;

  constructor(context: CanvasRenderingContext2D, config: TextLayoutConfig) {
    this.context = context;
    this.config = config;
  }

  /**
   * 对文本进行布局
   * Layout text and return positioned segments
   */
  layoutLine(text: string, initialX: number = 0): TextLayoutResult[] {
    const results: TextLayoutResult[] = [];
    let x = initialX;
    let lineIndex = 0;
    let i = 0;
    const spaceWidth = this.context.measureText(' ').width;

    while (i < text.length) {
      const char = text[i];

      // 处理空白字符
      if (isWhitespace(char)) {
        i++;
        continue;
      }

      // 处理拉丁文字（连续处理以保持单词完整）
      if (isLatin(char)) {
        let word = '';
        let startIndex = i;

        // 收集完整单词
        while (i < text.length && isLatin(text[i])) {
          word += text[i];
          i++;
        }

        const wordWidth = this.context.measureText(word).width;

        // 检查是否需要换行
        if (x + wordWidth > this.config.maxWidth && x > initialX) {
          x = 0;
          lineIndex++;
        }

        // 添加结果
        results.push({
          text: word,
          index: startIndex,
          lineIndex: lineIndex,
          width: wordWidth,
          height: this.config.fontSize,
          x: x
        });

        x += wordWidth + spaceWidth;
        continue;
      }

      // 处理CJK字符和其他字符
      const charWidth = this.context.measureText(char).width;

      // 检查是否需要换行
      if (x + charWidth > this.config.maxWidth && x > initialX) {
        x = 0;
        lineIndex++;
      }

      results.push({
        text: char,
        index: i,
        lineIndex: lineIndex,
        width: charWidth,
        height: this.config.fontSize,
        x: x
      });

      x += charWidth;
      i++;
    }

    return results;
  }

  /**
   * 合并同行的布局结果
   * Merge layout results on the same line
   */
  mergeLines(results: TextLayoutResult[]): TextLayoutResult[] {
    const merged: TextLayoutResult[] = [];
    let currentLine: TextLayoutResult | null = null;

    for (const result of results) {
      if (!currentLine || currentLine.lineIndex !== result.lineIndex) {
        if (currentLine) {
          merged.push(currentLine);
        }
        // ArkTS 不支持对象展开，手动复制属性
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

    if (currentLine) {
      merged.push(currentLine);
    }

    return merged;
  }
}
