'use strict';
// ─────────────────────────────────────────────
// 저장 데이터 (브라우저 localStorage)
// ─────────────────────────────────────────────
const Save = {
  KEY: 'night_survivors_save_v1',
  data: null,

  defaults() {
    return {
      gold: 0,
      upgrades: {},
      best: { time: 0, kills: 0, level: 0 },
      wins: 0,
      runs: 0,
      settings: { sfx: true, music: true, damageNumbers: true, screenShake: true },
    };
  },

  load() {
    const d = this.defaults();
    try {
      const raw = localStorage.getItem(this.KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        Object.assign(d, parsed);
        d.settings = Object.assign(this.defaults().settings, parsed.settings || {});
        d.best = Object.assign(this.defaults().best, parsed.best || {});
        d.upgrades = parsed.upgrades || {};
      }
    } catch (e) {
      console.warn('세이브 로드 실패', e);
    }
    this.data = d;
  },

  save() {
    try {
      localStorage.setItem(this.KEY, JSON.stringify(this.data));
    } catch (e) {
      // 저장소를 쓸 수 없는 환경이면 조용히 무시
    }
  },

  upgradeLevel(id) {
    return this.data.upgrades[id] || 0;
  },
};
