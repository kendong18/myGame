'use strict';
// ─────────────────────────────────────────────
// 사운드: 외부 파일 없이 WebAudio로 효과음/배경음 합성
// ─────────────────────────────────────────────
const Sound = {
  ctx: null,
  master: null,
  sfxGain: null,
  musicGain: null,
  noiseBuf: null,
  last: {},
  music: { on: false, timer: null, step: 0, next: 0 },

  // 브라우저 정책상 첫 사용자 입력 이후에만 오디오 시작 가능
  unlock() {
    if (this.ctx) {
      if (this.ctx.state === 'suspended') this.ctx.resume();
      return;
    }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    this.ctx = new AC();
    this.master = this.ctx.createGain();
    this.master.gain.value = 0.6;
    this.master.connect(this.ctx.destination);
    this.sfxGain = this.ctx.createGain();
    this.sfxGain.connect(this.master);
    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.value = 0.22;
    this.musicGain.connect(this.master);

    const len = this.ctx.sampleRate * 0.5;
    this.noiseBuf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
    const d = this.noiseBuf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    this.applySettings();
  },

  applySettings() {
    if (!this.ctx) return;
    const s = Save.data.settings;
    this.sfxGain.gain.value = s.sfx ? 1 : 0;
    this.musicGain.gain.value = s.music ? 0.22 : 0;
  },

  tone(freq, dur, { type = 'square', vol = 0.2, slide = 0, t = 0, attack = 0.005, dest = null } = {}) {
    const c = this.ctx;
    const start = t || c.currentTime;
    const o = c.createOscillator();
    const g = c.createGain();
    o.type = type;
    o.frequency.setValueAtTime(freq, start);
    if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(20, freq + slide), start + dur);
    g.gain.setValueAtTime(0.0001, start);
    g.gain.exponentialRampToValueAtTime(vol, start + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, start + dur);
    o.connect(g);
    g.connect(dest || this.sfxGain);
    o.start(start);
    o.stop(start + dur + 0.02);
  },

  noise(dur, { vol = 0.2, freq = 1200, q = 1, type = 'lowpass', t = 0, dest = null } = {}) {
    const c = this.ctx;
    const start = t || c.currentTime;
    const src = c.createBufferSource();
    src.buffer = this.noiseBuf;
    const f = c.createBiquadFilter();
    f.type = type;
    f.frequency.value = freq;
    f.Q.value = q;
    const g = c.createGain();
    g.gain.setValueAtTime(vol, start);
    g.gain.exponentialRampToValueAtTime(0.0001, start + dur);
    src.connect(f);
    f.connect(g);
    g.connect(dest || this.sfxGain);
    src.start(start);
    src.stop(start + dur + 0.02);
  },

  // 같은 소리가 너무 자주 겹치지 않게 제한
  throttle(name, gap) {
    const now = performance.now();
    if (this.last[name] && now - this.last[name] < gap) return false;
    this.last[name] = now;
    return true;
  },

  play(name) {
    if (!this.ctx || !Save.data.settings.sfx) return;
    switch (name) {
      case 'hit':
        if (!this.throttle(name, 45)) return;
        this.noise(0.06, { vol: 0.12, freq: 2500, type: 'bandpass', q: 0.8 });
        break;
      case 'kill':
        if (!this.throttle(name, 60)) return;
        this.tone(rand(180, 240), 0.08, { type: 'square', vol: 0.05, slide: -120 });
        break;
      case 'shoot':
        if (!this.throttle(name, 70)) return;
        this.tone(rand(700, 900), 0.06, { type: 'triangle', vol: 0.05, slide: 300 });
        break;
      case 'whip':
        if (!this.throttle(name, 80)) return;
        this.noise(0.12, { vol: 0.12, freq: 3200, type: 'highpass' });
        break;
      case 'gem':
        if (!this.throttle(name, 35)) return;
        this.tone(rand(1300, 1500), 0.06, { type: 'sine', vol: 0.07, slide: 400 });
        break;
      case 'coin':
        if (!this.throttle(name, 60)) return;
        this.tone(1320, 0.06, { type: 'square', vol: 0.06 });
        this.tone(1760, 0.12, { type: 'square', vol: 0.06, t: this.ctx.currentTime + 0.06 });
        break;
      case 'hurt':
        if (!this.throttle(name, 150)) return;
        this.tone(160, 0.18, { type: 'sawtooth', vol: 0.15, slide: -90 });
        break;
      case 'levelup': {
        const t0 = this.ctx.currentTime;
        [523, 659, 784, 1047].forEach((f, i) => this.tone(f, 0.16, { type: 'square', vol: 0.09, t: t0 + i * 0.07 }));
        break;
      }
      case 'select':
        this.tone(880, 0.08, { type: 'triangle', vol: 0.12 });
        this.tone(1320, 0.12, { type: 'triangle', vol: 0.1, t: this.ctx.currentTime + 0.05 });
        break;
      case 'click':
        this.tone(600, 0.05, { type: 'triangle', vol: 0.1 });
        break;
      case 'chest': {
        const t0 = this.ctx.currentTime;
        [392, 523, 659, 784, 1047, 1319].forEach((f, i) => this.tone(f, 0.25, { type: 'square', vol: 0.08, t: t0 + i * 0.09 }));
        break;
      }
      case 'thunder':
        if (!this.throttle(name, 90)) return;
        this.noise(0.35, { vol: 0.2, freq: 900 });
        this.tone(90, 0.3, { type: 'sawtooth', vol: 0.08, slide: -40 });
        break;
      case 'boom':
        this.noise(0.6, { vol: 0.35, freq: 500 });
        this.tone(70, 0.5, { type: 'sine', vol: 0.3, slide: -40 });
        break;
      case 'heal':
        this.tone(660, 0.1, { type: 'sine', vol: 0.12 });
        this.tone(990, 0.2, { type: 'sine', vol: 0.12, t: this.ctx.currentTime + 0.08 });
        break;
      case 'warning': {
        const t0 = this.ctx.currentTime;
        for (let i = 0; i < 3; i++) this.tone(440, 0.22, { type: 'sawtooth', vol: 0.09, t: t0 + i * 0.35, slide: -200 });
        break;
      }
      case 'death':
        this.tone(300, 1.2, { type: 'sawtooth', vol: 0.18, slide: -250 });
        this.noise(0.8, { vol: 0.2, freq: 600 });
        break;
      case 'victory': {
        const t0 = this.ctx.currentTime;
        [523, 659, 784, 1047, 784, 1047, 1319].forEach((f, i) => this.tone(f, 0.3, { type: 'square', vol: 0.09, t: t0 + i * 0.13 }));
        break;
      }
      case 'enemyShot':
        if (!this.throttle(name, 120)) return;
        this.tone(300, 0.12, { type: 'triangle', vol: 0.05, slide: 200 });
        break;
    }
  },

  // ── 배경음 (간단한 시퀀서) ──
  // A단조 진행: Am - F - G - Em
  CHORDS: [
    [57, 60, 64],
    [53, 57, 60],
    [55, 59, 62],
    [52, 55, 59],
  ],
  LEAD: [
    76, 0, 72, 0, 74, 0, 76, 79, 77, 0, 76, 0, 74, 0, 72, 0,
    72, 0, 69, 0, 72, 0, 74, 0, 72, 0, 69, 0, 65, 0, 69, 0,
    71, 0, 74, 0, 79, 0, 77, 76, 74, 0, 71, 0, 74, 0, 79, 0,
    76, 0, 71, 0, 67, 0, 71, 0, 76, 0, 79, 0, 76, 0, 0, 0,
  ],

  midi(n) {
    return 440 * Math.pow(2, (n - 69) / 12);
  },

  startMusic() {
    if (!this.ctx || this.music.on) return;
    this.music.on = true;
    this.music.step = 0;
    this.music.next = this.ctx.currentTime + 0.1;
    this.music.timer = setInterval(() => this.scheduleMusic(), 40);
  },

  stopMusic() {
    this.music.on = false;
    clearInterval(this.music.timer);
  },

  scheduleMusic() {
    if (!this.music.on) return;
    const stepDur = 60 / 138 / 4;
    while (this.music.next < this.ctx.currentTime + 0.15) {
      this.musicStep(this.music.step, this.music.next);
      this.music.next += stepDur;
      this.music.step = (this.music.step + 1) % 64;
    }
  },

  musicStep(s, t) {
    const dest = this.musicGain;
    const chord = this.CHORDS[Math.floor(s / 16)];
    // 베이스
    if (s % 4 === 0 || s % 16 === 14) {
      this.tone(this.midi(chord[0] - 24), 0.22, { type: 'square', vol: 0.12, t, dest });
    }
    // 아르페지오
    if (s % 2 === 0) {
      const n = chord[(s / 2) % 3] + 12;
      this.tone(this.midi(n), 0.1, { type: 'triangle', vol: 0.06, t, dest });
    }
    // 멜로디
    const lead = this.LEAD[s];
    if (lead) this.tone(this.midi(lead), 0.2, { type: 'square', vol: 0.045, t, dest });
    // 하이햇 / 킥
    if (s % 4 === 2) this.noise(0.04, { vol: 0.05, freq: 7000, type: 'highpass', t, dest });
    if (s % 8 === 0) this.tone(120, 0.12, { type: 'sine', vol: 0.25, slide: -70, t, dest });
  },
};
