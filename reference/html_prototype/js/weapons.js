'use strict';
// ─────────────────────────────────────────────
// 무기 동작
// ─────────────────────────────────────────────

function createWeapon(id) {
  const def = WEAPONS[id];
  const w = {
    id,
    def,
    level: 1,
    s: null,
    timer: 0.4,
    burstLeft: 0,
    burstIdx: 0,
    burstTimer: 0,
    dmgDealt: 0,
    kills: 0,
    acquiredAt: Game.time,
    // 무기별 상태
    tick: 0,
    angle: 0,
    active: 0,
    cool: 0.3,
    books: [],
    targets: [],
    radius: 0,
  };
  computeWeaponStats(w);
  return w;
}

function computeWeaponStats(w) {
  const s = Object.assign({}, w.def.base);
  for (let i = 0; i < w.level - 1; i++) {
    const lv = w.def.levels[i];
    for (const k in lv) if (k !== 'text') s[k] = (s[k] || 0) + lv[k];
  }
  w.s = s;
}

// 플레이어 스탯이 반영된 실제 수치
const W = {
  dmg: (w) => w.s.damage * Game.player.stats.might,
  cd: (w) => Math.max(0.08, w.s.cooldown * Game.player.stats.cooldown),
  amt: (w) => Math.max(1, (w.s.amount || 1) + Game.player.stats.amount),
  area: (w) => (w.s.area || 1) * Game.player.stats.area,
  spd: (w) => (w.s.speed || 1) * Game.player.stats.projSpeed,
  dur: (w) => (w.s.duration || 1) * Game.player.stats.duration,
};

const tmpList = [];

const WeaponTypes = {
  // ── 채찍: 좌우 베기 ──
  whip: {
    gap: 0.12,
    fire(w, g, i) {
      const p = g.player;
      const side = (i % 2 === 0 ? 1 : -1) * p.faceX;
      const area = W.area(w);
      const len = 150 * area, hgt = 34 * area;
      const yOff = -4 - Math.floor(i / 2) * 26;
      g.addProj({
        kind: 'whip', shape: 'rect',
        x: p.x + side * (len / 2 + 6), y: p.y + yOff,
        w: len, h: hgt, side,
        life: 0.22, maxLife: 0.22,
        damage: W.dmg(w), pierce: Infinity, kb: w.s.knockback, weapon: w,
        lifesteal: w.s.lifesteal || 0, stealLeft: 8,
      });
      Sound.play('whip');
    },
  },

  // ── 마법 지팡이: 가까운 적 조준 ──
  wand: {
    gap: 0.08,
    onVolley(w, g) {
      w.targets = g.nearestEnemies(g.player.x, g.player.y, W.amt(w), 650);
    },
    fire(w, g, i) {
      const p = g.player;
      if (!w.targets.length) return;
      const t = w.targets[i % w.targets.length];
      const a = Math.atan2(t.y - p.y, t.x - p.x) + (i >= w.targets.length ? rand(-0.15, 0.15) : 0);
      const sp = W.spd(w);
      g.addProj({
        kind: 'bolt', x: p.x, y: p.y - 4, r: 7 * W.area(w),
        vx: Math.cos(a) * sp, vy: Math.sin(a) * sp,
        life: W.dur(w), damage: W.dmg(w), pierce: w.s.pierce, kb: 0.6, weapon: w,
        color: w.def.evolved ? '#ffe070' : '#7ad8ff',
      });
      Sound.play('shoot');
    },
  },

  // ── 단검: 이동 방향으로 던짐 ──
  knife: {
    gap: 0.05,
    fire(w, g, i) {
      const p = g.player;
      const n = W.amt(w);
      const dx = p.dir.x, dy = p.dir.y;
      const off = (i - (n - 1) / 2) * 9 + rand(-3, 3);
      const a = Math.atan2(dy, dx) + rand(-0.05, 0.05);
      const sp = W.spd(w);
      g.addProj({
        kind: 'knife', x: p.x - dy * off, y: p.y - 4 + dx * off, r: 6,
        vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, rot: a,
        life: W.dur(w), damage: W.dmg(w), pierce: w.s.pierce, kb: 0.4, weapon: w,
      });
      Sound.play('shoot');
    },
  },

  // ── 도끼: 포물선 ──
  axe: {
    gap: 0.12,
    fire(w, g, i) {
      const p = g.player;
      const sp = W.spd(w);
      const dirX = i % 2 === 0 ? p.faceX : -p.faceX;
      g.addProj({
        kind: 'axe', x: p.x, y: p.y - 10, r: 14 * W.area(w),
        vx: dirX * (50 + Math.floor(i / 2) * 55 + rand(0, 40)), vy: -rand(500, 570) * sp,
        gravity: 950 * sp, rot: 0, spin: 12 * dirX,
        life: 3, damage: W.dmg(w), pierce: w.s.pierce, kb: 0.8, weapon: w,
      });
      Sound.play('shoot');
    },
  },

  // ── 죽음의 나선: 사방으로 회전 낫 ──
  spiral: {
    gap: 0,
    onVolley(w) {
      w.angle += 0.35;
    },
    fire(w, g, i) {
      const p = g.player;
      const n = W.amt(w);
      const a = w.angle + (i / n) * TAU;
      const sp = 280 * W.spd(w);
      g.addProj({
        kind: 'scythe', x: p.x, y: p.y, r: 18 * W.area(w),
        vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, rot: 0, spin: 14, curve: 1.3,
        life: W.dur(w), damage: W.dmg(w), pierce: Infinity, kb: 0.8, weapon: w,
      });
      if (i === 0) Sound.play('whip');
    },
  },

  // ── 마늘: 오라 ──
  garlic: {
    update(w, g, dt) {
      const p = g.player;
      const R = 48 * W.area(w);
      w.radius = R;
      w.tick -= dt;
      if (w.tick > 0) return;
      w.tick = Math.max(0.15, w.s.interval * (0.5 + 0.5 * p.stats.cooldown));
      const list = g.grid.query(p.x, p.y, R + 20, tmpList);
      let hits = 0;
      for (const e of list) {
        if (e.dead) continue;
        if (dist2(e.x, e.y, p.x, p.y) < (R + e.r) * (R + e.r)) {
          g.damageEnemy(e, W.dmg(w), w.s.knockback, p.x, p.y, w);
          hits++;
        }
      }
      g.hitProps(p.x, p.y, R);
      if (w.s.heal && hits) g.healPlayer(Math.min(3, hits * 0.15), false);
    },
  },

  // ── 성서: 주위를 도는 책 ──
  bible: {
    update(w, g, dt) {
      const p = g.player;
      const n = W.amt(w);
      w.angle += dt * 3.2 * W.spd(w);
      const R = 72 * W.area(w);
      const rebuild = () => {
        for (const b of w.books) b.dead = true;
        w.books = [];
        for (let i = 0; i < n; i++) {
          const b = g.addProj({
            kind: 'book', x: p.x, y: p.y, r: 13 * W.area(w), managed: true,
            life: Infinity, damage: W.dmg(w), pierce: Infinity, hitInterval: w.s.interval,
            kb: w.s.knockback, weapon: w,
          });
          w.books.push(b);
        }
      };
      if (w.active > 0) {
        w.active -= dt;
        if (w.active <= 0) {
          for (const b of w.books) b.dead = true;
          w.books = [];
          w.cool = W.cd(w);
        } else if (w.books.length !== n) {
          rebuild();
        }
      } else {
        w.cool -= dt;
        if (w.cool <= 0) {
          w.active = W.dur(w);
          rebuild();
        }
      }
      for (let i = 0; i < w.books.length; i++) {
        const b = w.books[i];
        const a = w.angle + (i / w.books.length) * TAU;
        b.x = p.x + Math.cos(a) * R;
        b.y = p.y + Math.sin(a) * R;
        b.r = 13 * W.area(w);
        b.damage = W.dmg(w);
        // 사라질 때 살짝 작아지는 연출
        b.scale = w.active < 0.25 ? Math.max(0.1, w.active / 0.25) : 1;
      }
    },
  },

  // ── 성수: 지대 생성 ──
  zone: {
    gap: 0.15,
    fire(w, g, i) {
      const p = g.player;
      let tx, ty;
      const e = g.randomEnemyInView(0.8);
      if (e && Math.random() < 0.85) {
        tx = e.x + rand(-20, 20);
        ty = e.y + rand(-20, 20);
      } else {
        const a = rand(0, TAU), d = rand(70, 220);
        tx = p.x + Math.cos(a) * d;
        ty = p.y + Math.sin(a) * d;
      }
      const delay = 0.35;
      g.addProj({
        kind: 'zone', x: tx, y: ty, r: 38 * W.area(w),
        delay, life: delay + W.dur(w), maxLife: W.dur(w),
        damage: W.dmg(w), pierce: Infinity, hitInterval: w.s.interval, kb: 0.1, weapon: w,
        evolved: !!w.def.evolved,
      });
    },
  },

  // ── 번개 ──
  lightning: {
    gap: 0.09,
    fire(w, g, i) {
      const e = g.randomEnemyInView(1);
      if (!e) return;
      const R = 30 * W.area(w);
      const x = e.x, y = e.y;
      g.addEffect({ type: 'bolt', x, y, life: 0.25, maxLife: 0.25, pts: makeBoltPoints(x, y, g.viewH), r: R });
      g.addEffect({ type: 'ring', x, y, r: 4, r2: R * 1.3, life: 0.25, maxLife: 0.25, color: '#fff6a0' });
      const list = g.grid.query(x, y, R + 20, tmpList);
      for (const t of list) {
        if (t.dead) continue;
        if (dist2(t.x, t.y, x, y) < (R + t.r) * (R + t.r)) g.damageEnemy(t, W.dmg(w), 0.3, x, y - 1, w);
      }
      g.hitProps(x, y, R);
      g.shake(2, 0.08);
      Sound.play('thunder');
    },
  },
};

function makeBoltPoints(x, y, viewH) {
  const pts = [];
  const top = y - viewH * 0.7;
  let cx = x + rand(-40, 40);
  const segs = 9;
  for (let i = 0; i <= segs; i++) {
    const t = i / segs;
    const py = lerp(top, y, t);
    const px = i === segs ? x : lerp(cx, x, t) + rand(-14, 14);
    pts.push(px, py);
  }
  return pts;
}

function updateWeapons(g, dt) {
  const p = g.player;
  for (const w of p.weapons) {
    const T = WeaponTypes[w.def.type];
    if (T.update) T.update(w, g, dt);
    if (!T.fire) continue;
    w.timer -= dt;
    if (w.timer <= 0) {
      w.timer = W.cd(w);
      w.burstLeft = W.amt(w);
      w.burstIdx = 0;
      w.burstTimer = 0;
      if (T.onVolley) T.onVolley(w, g);
    }
    if (w.burstLeft > 0) {
      w.burstTimer -= dt;
      while (w.burstLeft > 0 && w.burstTimer <= 0) {
        T.fire(w, g, w.burstIdx++);
        w.burstLeft--;
        w.burstTimer += T.gap;
      }
    }
  }
}
