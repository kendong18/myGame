'use strict';
// ─────────────────────────────────────────────
// 입력: 키보드 + 드래그 가상 조이스틱(터치/마우스)
// ─────────────────────────────────────────────
const Input = {
  keys: new Set(),
  joy: { active: false, id: null, sx: 0, sy: 0, x: 0, y: 0 },
  JOY_RADIUS: 55,

  init(canvas) {
    window.addEventListener('keydown', (e) => {
      Sound.unlock();
      if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) e.preventDefault();
      if (!e.repeat) UI.onKey(e);
      this.keys.add(e.code);
    });
    window.addEventListener('keyup', (e) => this.keys.delete(e.code));
    window.addEventListener('blur', () => {
      this.keys.clear();
      this.joy.active = false;
      if (Game.state === 'playing') Game.pause();
    });

    canvas.addEventListener('pointerdown', (e) => {
      Sound.unlock();
      if (this.joy.active) return;
      this.joy.active = true;
      this.joy.id = e.pointerId;
      this.joy.sx = this.joy.x = e.clientX;
      this.joy.sy = this.joy.y = e.clientY;
      canvas.setPointerCapture(e.pointerId);
    });
    canvas.addEventListener('pointermove', (e) => {
      if (!this.joy.active || e.pointerId !== this.joy.id) return;
      this.joy.x = e.clientX;
      this.joy.y = e.clientY;
      // 손가락이 너무 멀리 가면 기준점이 따라오게
      const dx = this.joy.x - this.joy.sx, dy = this.joy.y - this.joy.sy;
      const d = Math.hypot(dx, dy);
      if (d > this.JOY_RADIUS * 1.6) {
        const k = (d - this.JOY_RADIUS * 1.6) / d;
        this.joy.sx += dx * k;
        this.joy.sy += dy * k;
      }
    });
    const end = (e) => {
      if (e.pointerId === this.joy.id) this.joy.active = false;
    };
    canvas.addEventListener('pointerup', end);
    canvas.addEventListener('pointercancel', end);
  },

  down(...codes) {
    return codes.some((c) => this.keys.has(c));
  },

  // 이동 방향 벡터 (길이 0~1)
  axis() {
    let x = 0, y = 0;
    if (this.down('KeyA', 'ArrowLeft')) x -= 1;
    if (this.down('KeyD', 'ArrowRight')) x += 1;
    if (this.down('KeyW', 'ArrowUp')) y -= 1;
    if (this.down('KeyS', 'ArrowDown')) y += 1;
    if (this.joy.active) {
      const dx = this.joy.x - this.joy.sx, dy = this.joy.y - this.joy.sy;
      const d = Math.hypot(dx, dy);
      if (d > 6) {
        const m = Math.min(1, d / this.JOY_RADIUS);
        x += (dx / d) * m;
        y += (dy / d) * m;
      }
    }
    const len = Math.hypot(x, y);
    if (len > 1) {
      x /= len;
      y /= len;
    }
    return { x, y };
  },
};
