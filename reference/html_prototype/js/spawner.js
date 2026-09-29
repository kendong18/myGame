'use strict';
// ─────────────────────────────────────────────
// 적 스폰 / 이벤트 연출
// ─────────────────────────────────────────────

const EVENTS = [
  { time: 55, run: (g) => Spawner.spawnElite(g) },
  { time: 100, run: (g) => Spawner.ring(g, 'bat', 36, '박쥐 떼가 몰려온다!') },
  { time: 120, run: (g) => Spawner.spawnElite(g) },
  { time: 170, run: (g) => Spawner.stream(g, 'bat', 40) },
  { time: 180, run: (g) => Spawner.spawnElite(g) },
  { time: 230, run: (g) => Spawner.ring(g, 'zombie', 40, '좀비들에게 포위당했다!') },
  { time: 240, run: (g) => Spawner.spawnElite(g) },
  { time: 300, run: (g) => Spawner.spawnBoss(g, 'vampire') },
  { time: 350, run: (g) => Spawner.ring(g, 'ghost', 44, '유령들이 떠돈다...') },
  { time: 360, run: (g) => Spawner.spawnElite(g) },
  { time: 400, run: (g) => Spawner.stream(g, 'werewolf', 24) },
  { time: 420, run: (g) => Spawner.spawnElite(g, 2) },
  { time: 460, run: (g) => Spawner.ring(g, 'skeleton', 50, '해골 군단이 포위했다!') },
  { time: 480, run: (g) => Spawner.spawnElite(g, 2) },
  { time: 520, run: (g) => Spawner.stream(g, 'bat', 60) },
  { time: 540, run: (g) => Spawner.spawnElite(g, 3) },
  { time: 560, run: (g) => Spawner.ring(g, 'golem', 24, '골렘들이 땅을 울린다!') },
  { time: 600, run: (g) => Spawner.spawnBoss(g, 'demon') },
];

const Spawner = {
  acc: 0,
  eventIdx: 0,
  propTimer: 0,

  reset() {
    this.acc = 0;
    this.eventIdx = 0;
    this.propTimer = 0;
  },

  currentWave(t) {
    return WAVES[Math.min(WAVES.length - 1, Math.floor(t / 60))];
  },

  update(g, dt) {
    const t = g.time;
    const wave = this.currentWave(t);
    const finalPhase = g.finalBossSpawned && !g.victory;
    let rate = wave.rate * (finalPhase ? 0.45 : 1);
    this.acc += rate * dt;
    while (this.acc >= 1) {
      this.acc -= 1;
      if (g.enemies.length < wave.max) g.spawnEnemy(pick(wave.types));
    }
    // 초반에는 최소 적 수 유지
    if (g.enemies.length < 8 + t / 10) this.acc += dt * 3;

    while (this.eventIdx < EVENTS.length && t >= EVENTS[this.eventIdx].time) {
      EVENTS[this.eventIdx].run(g);
      this.eventIdx++;
    }

    // 화로(부술 수 있는 오브젝트) 유지
    this.propTimer -= dt;
    if (this.propTimer <= 0) {
      this.propTimer = 2;
      const near = g.props.filter((pr) => dist2(pr.x, pr.y, g.player.x, g.player.y) < 900 * 900).length;
      if (near < 4) g.spawnProp();
    }
  },

  spawnElite(g, count = 1) {
    const wave = this.currentWave(g.time);
    for (let i = 0; i < count; i++) {
      // 현재 웨이브에서 가장 강한 적을 엘리트로
      let best = wave.types[0];
      for (const tpe of wave.types) if (ENEMIES[tpe].hp > ENEMIES[best].hp) best = tpe;
      const type = Math.random() < 0.5 ? best : pick(wave.types);
      g.spawnEnemy(type, { elite: true });
    }
    g.banner('강력한 적이 나타났다!', '#ffcc4d');
  },

  // 플레이어를 둘러싸는 원형 포위
  ring(g, type, count, text) {
    const p = g.player;
    const R = Math.hypot(g.viewW, g.viewH) / 2 + 30;
    for (let i = 0; i < count; i++) {
      const a = (i / count) * TAU;
      g.spawnEnemy(type, { x: p.x + Math.cos(a) * R, y: p.y + Math.sin(a) * R, noCap: true });
    }
    if (text) g.banner(text, '#ff8a8a');
  },

  // 화면을 가로지르는 적 무리 (직진)
  stream(g, type, count) {
    const p = g.player;
    const fromLeft = Math.random() < 0.5;
    const sx = p.x + (fromLeft ? -1 : 1) * (g.viewW / 2 + 60);
    const def = ENEMIES[type];
    for (let i = 0; i < count; i++) {
      const y = p.y + rand(-g.viewH * 0.45, g.viewH * 0.45);
      const x = sx + (fromLeft ? -1 : 1) * rand(0, 250);
      g.spawnEnemy(type, {
        x, y, noCap: true,
        straight: { vx: (fromLeft ? 1 : -1) * def.speed * 1.8, vy: 0 },
      });
    }
    g.banner('무리가 돌진해 온다!', '#ff8a8a');
  },

  spawnBoss(g, type) {
    const def = ENEMIES[type];
    const e = g.spawnEnemy(type, { noCap: true, boss: true });
    g.bosses.push(e);
    if (type === 'demon') g.finalBossSpawned = true;
    g.banner('⚠ 보스 등장: ' + def.name + ' ⚠', '#ff4a5a', 4);
    Sound.play('warning');
  },
};
