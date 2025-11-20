/**
 * AppleMusic-like Lyrics Player for HarmonyOS
 * 鸿蒙版 AppleMusic 风格歌词播放器 - 数据模型
 */

/**
 * 歌词单词
 * A single word in a lyric line
 */
export class LyricWord {
  /** 单词的起始时间（毫秒） / Start time in milliseconds */
  startTime: number = 0;

  /** 单词的结束时间（毫秒） / End time in milliseconds */
  endTime: number = 0;

  /** 单词内容 / Word content */
  word: string = '';

  /** 单词的音译内容 / Romanized word content */
  romanWord: string = '';

  /** 单词内容是否包含不雅用语 / Whether word contains obscene content */
  obscene: boolean = false;

  constructor(
    word: string,
    startTime: number,
    endTime: number,
    romanWord: string = '',
    obscene: boolean = false
  ) {
    this.word = word;
    this.startTime = startTime;
    this.endTime = endTime;
    this.romanWord = romanWord;
    this.obscene = obscene;
  }
}

/**
 * 一行歌词
 * A single line of lyrics
 */
export class LyricLine {
  /** 该行的所有单词 / All words in this line */
  words: LyricWord[] = [];

  /** 该行的翻译歌词 / Translated lyrics for this line */
  translatedLyric: string = '';

  /** 该行的音译歌词 / Romanized lyrics for this line */
  romanLyric: string = '';

  /** 句子的起始时间（毫秒） / Start time in milliseconds */
  startTime: number = 0;

  /** 句子的结束时间（毫秒） / End time in milliseconds */
  endTime: number = 0;

  /** 是否为背景歌词行 / Whether this is a background vocal line */
  isBG: boolean = false;

  /** 是否为对唱歌词行 / Whether this is a duet line (right-aligned) */
  isDuet: boolean = false;

  constructor(
    words: LyricWord[],
    startTime: number,
    endTime: number,
    translatedLyric: string = '',
    romanLyric: string = '',
    isBG: boolean = false,
    isDuet: boolean = false
  ) {
    this.words = words;
    this.startTime = startTime;
    this.endTime = endTime;
    this.translatedLyric = translatedLyric;
    this.romanLyric = romanLyric;
    this.isBG = isBG;
    this.isDuet = isDuet;
  }

  /**
   * 获取该行歌词的完整文本
   * Get the full text of this line
   */
  getFullText(): string {
    return this.words.map(w => w.word).join('');
  }
}
