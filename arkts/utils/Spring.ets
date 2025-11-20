/**
 * AppleMusic-like Lyrics Player for HarmonyOS
 * 弹簧动画系统 - Spring Animation System
 *
 * MIT License - Original implementation from github.com/pushkine/
 */

/**
 * 弹簧参数
 * Spring parameters for physics-based animation
 */
export interface SpringParams {
  /** 质量 / Mass */
  mass: number;

  /** 阻尼 / Damping */
  damping: number;

  /** 刚度 / Stiffness */
  stiffness: number;

  /** 软模式 / Soft mode */
  soft: boolean;
}

/**
 * 弹簧参数（可选）
 * Optional spring parameters
 */
interface PartialSpringParams {
  /** 质量 / Mass */
  mass?: number;

  /** 阻尼 / Damping */
  damping?: number;

  /** 刚度 / Stiffness */
  stiffness?: number;

  /** 软模式 / Soft mode */
  soft?: boolean;
}

/**
 * 队列参数（带延迟）
 * Queued parameters with delay
 */
interface QueuedSpringParams {
  /** 质量 / Mass */
  mass?: number;

  /** 阻尼 / Damping */
  damping?: number;

  /** 刚度 / Stiffness */
  stiffness?: number;

  /** 软模式 / Soft mode */
  soft?: boolean;

  /** 延迟时间 / Delay time */
  time: number;
}

/**
 * 队列位置（带延迟）
 * Queued position with delay
 */
interface QueuedPosition {
  /** 目标位置 / Target position */
  position: number;

  /** 延迟时间 / Delay time */
  time: number;
}

/**
 * 获取函数导数（速度）
 * Get derivative of a function (velocity)
 */
function getVelocity(fn: (t: number) => number): (t: number) => number {
  const h = 0.001;
  return (t: number) => (fn(t + h) - fn(t - h)) / (2 * h);
}

/**
 * 求解弹簧运动
 * Solve spring motion equation
 */
function solveSpring(
  from: number,
  velocity: number,
  to: number,
  delay: number = 0,
  params?: PartialSpringParams
): (t: number) => number {
  const soft = params?.soft ?? false;
  const stiffness = params?.stiffness ?? 100;
  const damping = params?.damping ?? 10;
  const mass = params?.mass ?? 1;
  const delta = to - from;

  if (soft || 1.0 <= damping / (2.0 * Math.sqrt(stiffness * mass))) {
    // Over-damped or critically damped case
    const angular_frequency = -Math.sqrt(stiffness / mass);
    const leftover = -angular_frequency * delta - velocity;

    return (t: number): number => {
      t -= delay;
      if (t < 0) return from;
      return to - (delta + t * leftover) * Math.exp(t * angular_frequency);
    };
  }

  // Under-damped case (oscillation)
  const damping_frequency = Math.sqrt(4.0 * mass * stiffness - damping ** 2.0);
  const leftover = (damping * delta - 2.0 * mass * velocity) / damping_frequency;
  const dfm = (0.5 * damping_frequency) / mass;
  const dm = -(0.5 * damping) / mass;

  return (t: number): number => {
    t -= delay;
    if (t < 0) return from;
    return (
      to -
      (Math.cos(t * dfm) * delta + Math.sin(t * dfm) * leftover) *
      Math.exp(t * dm)
    );
  };
}

/**
 * 弹簧动画类
 * Spring animation class for smooth physics-based transitions
 */
export class Spring {
  private currentPosition: number = 0;
  private targetPosition: number = 0;
  private currentTime: number = 0;
  private params: PartialSpringParams = {};
  private currentSolver: (t: number) => number;
  private getV: (t: number) => number;
  private getV2: (t: number) => number;
  private queueParams?: QueuedSpringParams;
  private queuePosition?: QueuedPosition;

  constructor(currentPosition: number = 0) {
    this.targetPosition = currentPosition;
    this.currentPosition = this.targetPosition;
    this.currentSolver = () => this.targetPosition;
    this.getV = () => 0;
    this.getV2 = () => 0;
  }

  /**
   * 重置求解器
   * Reset the solver with current state
   */
  private resetSolver(): void {
    const curV = this.getV(this.currentTime);
    this.currentTime = 0;
    this.currentSolver = solveSpring(
      this.currentPosition,
      curV,
      this.targetPosition,
      0,
      this.params
    );
    this.getV = getVelocity(this.currentSolver);
    this.getV2 = getVelocity(this.getV);
  }

  /**
   * 判断是否到达目标位置
   * Check if arrived at target position
   */
  arrived(): boolean {
    return (
      Math.abs(this.targetPosition - this.currentPosition) < 0.01 &&
      Math.abs(this.getV(this.currentTime)) < 0.01 &&
      Math.abs(this.getV2(this.currentTime)) < 0.01 &&
      !this.queueParams &&
      !this.queuePosition
    );
  }

  /**
   * 直接设置位置（无动画）
   * Set position immediately without animation
   */
  setPosition(targetPosition: number): void {
    this.targetPosition = targetPosition;
    this.currentPosition = targetPosition;
    this.currentSolver = () => this.targetPosition;
    this.getV = () => 0;
    this.getV2 = () => 0;
  }

  /**
   * 更新动画状态
   * Update animation state
   * @param delta 时间增量（秒） / Time delta in seconds
   */
  update(delta: number = 0): void {
    this.currentTime += delta;
    this.currentPosition = this.currentSolver(this.currentTime);

    if (this.queueParams) {
      this.queueParams.time -= delta;
      if (this.queueParams.time <= 0) {
        // 复制参数（不包括 time）
        const paramsCopy: PartialSpringParams = {};
        if (this.queueParams.mass !== undefined) paramsCopy.mass = this.queueParams.mass;
        if (this.queueParams.damping !== undefined) paramsCopy.damping = this.queueParams.damping;
        if (this.queueParams.stiffness !== undefined) paramsCopy.stiffness = this.queueParams.stiffness;
        if (this.queueParams.soft !== undefined) paramsCopy.soft = this.queueParams.soft;
        this.updateParams(paramsCopy);
      }
    }

    if (this.queuePosition) {
      this.queuePosition.time -= delta;
      if (this.queuePosition.time <= 0) {
        this.setTargetPosition(this.queuePosition.position);
      }
    }

    if (this.arrived()) {
      this.setPosition(this.targetPosition);
    }
  }

  /**
   * 更新弹簧参数
   * Update spring parameters
   */
  updateParams(params: PartialSpringParams, delay: number = 0): void {
    if (delay > 0) {
      // 创建队列参数对象
      const merged: QueuedSpringParams = { time: delay };
      const existing = this.queueParams;

      // 复制现有队列参数
      if (existing) {
        if (existing.mass !== undefined) merged.mass = existing.mass;
        if (existing.damping !== undefined) merged.damping = existing.damping;
        if (existing.stiffness !== undefined) merged.stiffness = existing.stiffness;
        if (existing.soft !== undefined) merged.soft = existing.soft;
      }

      // 应用新参数
      if (params.mass !== undefined) merged.mass = params.mass;
      if (params.damping !== undefined) merged.damping = params.damping;
      if (params.stiffness !== undefined) merged.stiffness = params.stiffness;
      if (params.soft !== undefined) merged.soft = params.soft;

      this.queueParams = merged;
    } else {
      this.queueParams = undefined;
      // 直接更新参数
      if (params.mass !== undefined) this.params.mass = params.mass;
      if (params.damping !== undefined) this.params.damping = params.damping;
      if (params.stiffness !== undefined) this.params.stiffness = params.stiffness;
      if (params.soft !== undefined) this.params.soft = params.soft;
      this.resetSolver();
    }
  }

  /**
   * 设置目标位置（使用动画）
   * Set target position with animation
   */
  setTargetPosition(targetPosition: number, delay: number = 0): void {
    if (delay > 0) {
      // 创建队列位置对象
      const queued: QueuedPosition = {
        position: targetPosition,
        time: delay
      };
      this.queuePosition = queued;
    } else {
      this.queuePosition = undefined;
      this.targetPosition = targetPosition;
      this.resetSolver();
    }
  }

  /**
   * 获取当前位置
   * Get current position
   */
  getCurrentPosition(): number {
    return this.currentPosition;
  }
}
