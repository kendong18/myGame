'use strict';
// ─────────────────────────────────────────────
// 픽셀 아트 스프라이트 (문자열 → 캔버스로 굽기)
// '.' 은 투명, 나머지 문자는 팔레트 색상
// ─────────────────────────────────────────────

const PIXEL_ART = {
  hero: [
    '................',
    '.....HHHHHH.....',
    '....HHHHHHHH....',
    '....HSSSSSSH....',
    '....SSeSSeSS....',
    '....SSSSSSSS....',
    '.....SSmmSS.....',
    '...AABBBBBBAA...',
    '..AABBBBBBBBAA..',
    '..SSBBBccBBBSS..',
    '..SS.BBBBBB.SS..',
    '.....LLLLLL.....',
    '.....LLLLLL.....',
    '.....LL..LL.....',
    '.....DD..DD.....',
    '....DDD..DDD....',
  ],
  bat1: [
    'BB............BB',
    'BBB..........BBB',
    '.BBB..b..b..BBB.',
    '.BBBBbbbbbbBBBB.',
    '..BBbbrbbrbbBB..',
    '...BbbbbbbbbB...',
    '.....bbwwbb.....',
    '......bbbb......',
    '................',
  ],
  bat2: [
    '................',
    '......b..b......',
    '.....bbbbbb.....',
    '....bbrbbrbb....',
    '..BBBbbbbbbBBB..',
    '.BBBBbbwwbbBBBB.',
    'BBBB..bbbb..BBBB',
    'BBB..........BBB',
    'BB............BB',
  ],
  zombie: [
    '................',
    '.....GGGGGG.....',
    '....GGGGGGGG....',
    '....GrGGGGrG....',
    '....GGGGGGGG....',
    '....GGdddGGG....',
    '.....GGGGGG.....',
    '...TTTTTTTTTT...',
    '..GTTTtTTTTTTG..',
    '..GG.TTTTtTT.GG.',
    '.....PPPPPP.....',
    '.....PPPPPP.....',
    '.....PP..PP.....',
    '.....GG..GG.....',
    '....GGG..GGG....',
    '................',
  ],
  skeleton: [
    '................',
    '.....WWWWWW.....',
    '....WWWWWWWW....',
    '....WkkWWkkW....',
    '....WkkWWkkW....',
    '....WWWggWWW....',
    '.....WkWkWk.....',
    '......WWWW......',
    '....g.WWWW.g....',
    '...g.WgWWgW.g...',
    '...g.WgWWgW.g...',
    '......WWWW......',
    '.....W....W.....',
    '.....W....W.....',
    '....WW....WW....',
    '................',
  ],
  ghost: [
    '................',
    '......WWWW......',
    '....WWWWWWWW....',
    '...WWWWWWWWWW...',
    '...WWkkWWkkWW...',
    '...WWkkWWkkWW...',
    '..WWWWWWWWWWWW..',
    '..WWWWWkkWWWWW..',
    '..WWWWWWWWWWWW..',
    '..WWWWWWWWWWWW..',
    '..bWWWWWWWWWWb..',
    '..bbWWWbbWWWbb..',
    '..b.bWb..bWb.b..',
    '....b......b....',
  ],
  golem: [
    '................',
    '....rrRRRRrr....',
    '...rRRlRRRRRr...',
    '...RRyyRRyyRR...',
    '...RRRRRRRRRR...',
    '.rrRRrRRRRrRRrr.',
    'rRRRRRRRRRRRRRRr',
    'rRRlRRRRRRRRlRRr',
    'rRR.RRRrrRRR.RRr',
    'rrr.RRRRRRRR.rrr',
    '....RRRRRRRR....',
    '....RRr..rRR....',
    '....RRr..rRR....',
    '...rRRr..rRRr...',
    '...rrrr..rrrr...',
    '................',
  ],
  werewolf: [
    '................',
    '...f........f...',
    '...ff......ff...',
    '...fFFFFFFFFf...',
    '...FFyFFFFyFF...',
    '...FFFFFFFFFF...',
    '....FFFnnFFF....',
    '....FwFwwFwF....',
    '..ffFFFFFFFFff..',
    '.fFFFFFFFFFFFFf.',
    '.fF.FFFffFFF.Ff.',
    '.ww.FFFFFFFF.ww.',
    '....FFFFFFFF....',
    '....ff....ff....',
    '...fff....fff...',
    '................',
  ],
  mage: [
    '......PPPP......',
    '.....PPPPPP.....',
    '....PPWWWWPP....',
    '....PWkWWkWP....',
    '....PWWWWWWP....',
    '....pPWkkWPp....',
    '...PPPPPPPPPPo..',
    '..PPPPPPPPPPPs..',
    '..W.PPPPPPPP.s..',
    '....PPPPPPPP.s..',
    '....pPPPPPPp.s..',
    '...pPPPPPPPPp...',
    '...pppPPPPppp...',
    '..pppppppppppp..',
  ],
  demon: [
    '..h..........h..',
    '..hh........hh..',
    '...hDDDDDDDDh...',
    '...DDyyDDyyDD...',
    '...DDDDDDDDDD...',
    '....DDkkkkDD....',
    'ww..DDWDDWDD..ww',
    'www.dDDDDDDd.www',
    'wwwwDDDDDDDDwwww',
    '.wwDDDddDDDDww..',
    '..wDDDDDDDDDDw..',
    '....DDDDDDDD....',
    '....dDD..DDd....',
    '....dDD..DDd....',
    '...kkkk..kkkk...',
  ],
  chest: [
    '..bbbbbbbbbb..',
    '.bBBBBBBBBBBb.',
    'bBBBBBBBBBBBBb',
    'bbbbbbyybbbbbb',
    'bBBBBByyBBBBBb',
    'bBBBBBBBBBBBBb',
    'bBBBBBBBBBBBBb',
    'bbbbbbbbbbbbbb',
  ],
  gem: [
    '..w..',
    '.wcc.',
    'wcccd',
    'cccdd',
    '.cdd.',
    '..d..',
  ],
};

const HERO_BASE_PALETTE = { S: '#f2c29b', e: '#1a1a2e', m: '#d9967a' };

const SPRITE_PALETTES = {
  bat: { B: '#4a2a6a', b: '#6a3a8a', r: '#ff4040', w: '#ffffff' },
  zombie: { G: '#6aa84f', r: '#ff3030', d: '#3a5a2a', T: '#6a5a8a', t: '#4a3a6a', P: '#4a4040' },
  skeleton: { W: '#e8e4d8', k: '#201818', g: '#a8a498' },
  ghost: { W: '#e0f0ff', b: '#a0c8f0', k: '#203050' },
  golem: { R: '#7a7a8a', r: '#5a5a6a', y: '#ffcc33', l: '#9a9aaa' },
  werewolf: { F: '#7a5030', f: '#5a3820', y: '#ffe040', w: '#ffffff', n: '#201010' },
  mage: { P: '#5a2a8a', p: '#3a1a5a', W: '#e8e4d8', k: '#201818', o: '#40f0ff', s: '#8a6a3a' },
  vampire: { H: '#1a1a22', S: '#e0d8e8', e: '#ff2020', m: '#b08898', A: '#301020', B: '#801828', c: '#e8c040', L: '#1a1a1a', D: '#101010' },
  demon: { D: '#b02030', d: '#701020', h: '#e8d8b0', y: '#ffe040', k: '#200808', W: '#ffffff', w: '#4a1838' },
  chest: { B: '#c08030', b: '#6a4018', y: '#ffe040' },
};

const GEM_TIERS = [
  { max: 2, pal: { c: '#4aa8ff', d: '#1f5fbf', w: '#e0f4ff' } },
  { max: 10, pal: { c: '#50e070', d: '#1f8f3f', w: '#e0ffe8' } },
  { max: 40, pal: { c: '#ff5060', d: '#a01830', w: '#ffe0e4' } },
  { max: Infinity, pal: { c: '#c070ff', d: '#6a20a0', w: '#f4e0ff' } },
];

const Sprites = {
  cache: {},
  SCALE: 4, // 굽는 해상도 (픽셀 1칸 = 4px)

  bake(key, rows, palette, outline = '#120a18') {
    const h = rows.length;
    let w = 0;
    for (const r of rows) w = Math.max(w, r.length);
    const W = w + 2, H = h + 2;
    const grid = [];
    for (let y = 0; y < H; y++) grid.push(new Array(W).fill(null));
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < rows[y].length; x++) {
        const ch = rows[y][x];
        if (ch !== '.' && ch !== ' ') grid[y + 1][x + 1] = palette[ch] || '#ff00ff';
      }
    }
    // 외곽선
    if (outline) {
      const add = [];
      for (let y = 0; y < H; y++) {
        for (let x = 0; x < W; x++) {
          if (grid[y][x]) continue;
          const n =
            (y > 0 && grid[y - 1][x]) || (y < H - 1 && grid[y + 1][x]) ||
            (x > 0 && grid[y][x - 1]) || (x < W - 1 && grid[y][x + 1]);
          if (n) add.push([x, y]);
        }
      }
      for (const [x, y] of add) grid[y][x] = outline;
    }
    const S = this.SCALE;
    const make = (flash) => {
      const c = document.createElement('canvas');
      c.width = W * S;
      c.height = H * S;
      const ctx = c.getContext('2d');
      for (let y = 0; y < H; y++) {
        for (let x = 0; x < W; x++) {
          const col = grid[y][x];
          if (!col) continue;
          ctx.fillStyle = flash ? '#ffffff' : col;
          ctx.fillRect(x * S, y * S, S, S);
        }
      }
      return c;
    };
    const spr = { img: make(false), flash: make(true), w: W, h: H };
    this.cache[key] = spr;
    return spr;
  },

  get(key) {
    return this.cache[key];
  },

  heroKey(charId) {
    return 'hero_' + charId;
  },

  init() {
    for (const ch of CHARACTERS) {
      this.bake(this.heroKey(ch.id), PIXEL_ART.hero, Object.assign({}, HERO_BASE_PALETTE, ch.palette));
    }
    this.bake('bat1', PIXEL_ART.bat1, SPRITE_PALETTES.bat);
    this.bake('bat2', PIXEL_ART.bat2, SPRITE_PALETTES.bat);
    this.bake('zombie', PIXEL_ART.zombie, SPRITE_PALETTES.zombie);
    this.bake('skeleton', PIXEL_ART.skeleton, SPRITE_PALETTES.skeleton);
    this.bake('ghost', PIXEL_ART.ghost, SPRITE_PALETTES.ghost);
    this.bake('golem', PIXEL_ART.golem, SPRITE_PALETTES.golem);
    this.bake('werewolf', PIXEL_ART.werewolf, SPRITE_PALETTES.werewolf);
    this.bake('mage', PIXEL_ART.mage, SPRITE_PALETTES.mage);
    this.bake('vampire', PIXEL_ART.hero, SPRITE_PALETTES.vampire);
    this.bake('demon', PIXEL_ART.demon, SPRITE_PALETTES.demon);
    this.bake('chest', PIXEL_ART.chest, SPRITE_PALETTES.chest);
    GEM_TIERS.forEach((t, i) => this.bake('gem' + i, PIXEL_ART.gem, t.pal));

    // 그림자
    const sh = document.createElement('canvas');
    sh.width = 64;
    sh.height = 24;
    const sx = sh.getContext('2d');
    const g = sx.createRadialGradient(32, 12, 2, 32, 12, 30);
    g.addColorStop(0, 'rgba(0,0,0,0.45)');
    g.addColorStop(1, 'rgba(0,0,0,0)');
    sx.fillStyle = g;
    sx.beginPath();
    sx.ellipse(32, 12, 31, 11, 0, 0, TAU);
    sx.fill();
    this.shadow = sh;
  },

  gemTier(value) {
    for (let i = 0; i < GEM_TIERS.length; i++) if (value < GEM_TIERS[i].max) return i;
    return GEM_TIERS.length - 1;
  },

  // 스프라이트를 (x,y) 중심으로 그림. px = 월드 단위 픽셀 크기
  draw(ctx, spr, x, y, px, flip = false, flash = false) {
    const w = spr.w * px, h = spr.h * px;
    const img = flash ? spr.flash : spr.img;
    if (flip) {
      ctx.save();
      ctx.translate(x, y);
      ctx.scale(-1, 1);
      ctx.drawImage(img, -w / 2, -h / 2, w, h);
      ctx.restore();
    } else {
      ctx.drawImage(img, x - w / 2, y - h / 2, w, h);
    }
  },
};

// ─────────────────────────────────────────────
// 배경: 반복되는 잔디 타일 + 좌표 해시 기반 장식물
// ─────────────────────────────────────────────
const Background = {
  TILE: 256,
  DECO_CELL: 150,
  pattern: null,

  init(ctx) {
    const S = this.TILE;
    const c = document.createElement('canvas');
    c.width = c.height = S;
    const x = c.getContext('2d');
    const rnd = mulberry32(1337);
    x.fillStyle = '#1b271e';
    x.fillRect(0, 0, S, S);

    // 이음새 없이 반복되도록 가장자리를 넘는 요소는 반대편에도 그림
    const wrap = (fn) => {
      for (const ox of [-S, 0, S]) for (const oy of [-S, 0, S]) fn(ox, oy);
    };
    for (let i = 0; i < 26; i++) {
      const px = rnd() * S, py = rnd() * S, rx = 20 + rnd() * 40, ry = 12 + rnd() * 26;
      const col = rnd() < 0.5 ? 'rgba(38,56,40,0.55)' : 'rgba(22,32,24,0.6)';
      wrap((ox, oy) => {
        x.fillStyle = col;
        x.beginPath();
        x.ellipse(px + ox, py + oy, rx, ry, rnd() * 3, 0, TAU);
        x.fill();
      });
    }
    // 잔디 잎
    for (let i = 0; i < 420; i++) {
      const px = Math.floor(rnd() * S), py = Math.floor(rnd() * S);
      x.fillStyle = rnd() < 0.5 ? '#2c4130' : '#23362a';
      x.fillRect(px, py, 1, 3);
      x.fillRect(px + 1, py + 1, 1, 2);
    }
    // 흙 알갱이
    for (let i = 0; i < 60; i++) {
      x.fillStyle = 'rgba(60,50,40,0.5)';
      x.fillRect(Math.floor(rnd() * S), Math.floor(rnd() * S), 2, 2);
    }
    // 작은 꽃
    const flowerCols = ['#8a7ac8', '#c8b050', '#b86a8a', '#6a9ac8'];
    for (let i = 0; i < 10; i++) {
      const px = Math.floor(rnd() * (S - 4)) + 2, py = Math.floor(rnd() * (S - 4)) + 2;
      x.fillStyle = flowerCols[i % flowerCols.length];
      x.fillRect(px - 1, py, 3, 1);
      x.fillRect(px, py - 1, 1, 3);
      x.fillStyle = '#f0e8a0';
      x.fillRect(px, py, 1, 1);
    }
    this.pattern = ctx.createPattern(c, 'repeat');
  },

  drawGround(ctx, left, top, w, h) {
    ctx.fillStyle = this.pattern;
    ctx.fillRect(left, top, w, h);
  },

  // 장식물 (게임플레이에 영향 없음)
  drawDecorations(ctx, left, top, w, h, time) {
    const C = this.DECO_CELL;
    const x0 = Math.floor(left / C) - 1, x1 = Math.floor((left + w) / C) + 1;
    const y0 = Math.floor(top / C) - 1, y1 = Math.floor((top + h) / C) + 1;
    for (let cx = x0; cx <= x1; cx++) {
      for (let cy = y0; cy <= y1; cy++) {
        const h1 = hash2(cx, cy);
        if (h1 > 0.3) continue;
        const h2 = hash2(cx + 91, cy - 37);
        const h3 = hash2(cx - 17, cy + 53);
        const x = cx * C + h2 * C * 0.8;
        const y = cy * C + h3 * C * 0.8;
        const kind = Math.floor(hash2(cy, cx) * 7);
        this.drawDeco(ctx, kind, x, y, h2, time);
      }
    }
  },

  drawDeco(ctx, kind, x, y, v, time) {
    switch (kind) {
      case 0: // 묘비
        ctx.fillStyle = 'rgba(0,0,0,0.35)';
        ctx.beginPath();
        ctx.ellipse(x, y + 12, 13, 4, 0, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#5a5a68';
        ctx.fillRect(x - 9, y - 10, 18, 22);
        ctx.beginPath();
        ctx.arc(x, y - 10, 9, Math.PI, 0);
        ctx.fill();
        ctx.fillStyle = '#6e6e7e';
        ctx.fillRect(x - 9, y - 10, 4, 22);
        ctx.fillStyle = '#3a3a46';
        ctx.fillRect(x - 1, y - 12, 2, 12);
        ctx.fillRect(x - 5, y - 8, 10, 2);
        break;
      case 1: // 바위
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.beginPath();
        ctx.ellipse(x, y + 6, 16, 5, 0, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#4a4a52';
        ctx.beginPath();
        ctx.ellipse(x, y, 15, 9, 0, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#5c5c66';
        ctx.beginPath();
        ctx.ellipse(x - 3, y - 3, 9, 5, 0, 0, TAU);
        ctx.fill();
        break;
      case 2: // 덤불
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.beginPath();
        ctx.ellipse(x, y + 8, 18, 5, 0, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#1f3a24';
        for (const [ox, oy, r] of [[-8, 2, 9], [8, 2, 9], [0, -4, 11]]) {
          ctx.beginPath();
          ctx.arc(x + ox, y + oy, r, 0, TAU);
          ctx.fill();
        }
        ctx.fillStyle = '#2a4d30';
        ctx.beginPath();
        ctx.arc(x - 2, y - 6, 6, 0, TAU);
        ctx.fill();
        break;
      case 3: // 뼈 무더기
        ctx.strokeStyle = '#b8b2a0';
        ctx.lineWidth = 2.5;
        ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.moveTo(x - 8, y + 2);
        ctx.lineTo(x + 6, y - 3);
        ctx.moveTo(x - 4, y - 5);
        ctx.lineTo(x + 7, y + 4);
        ctx.stroke();
        ctx.fillStyle = '#d0cabb';
        ctx.beginPath();
        ctx.arc(x + 10, y - 6, 5, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#222';
        ctx.fillRect(x + 8, y - 7, 2, 2);
        ctx.fillRect(x + 11, y - 7, 2, 2);
        break;
      case 4: { // 버섯
        const cols = ['#b84a4a', '#8a5ab8', '#c8a040'];
        const col = cols[Math.floor(v * 3)];
        for (const [ox, oy, s] of [[0, 0, 1], [9, 4, 0.7], [-7, 5, 0.6]]) {
          ctx.fillStyle = '#d8cdb0';
          ctx.fillRect(x + ox - 1.5 * s, y + oy - 2 * s, 3 * s, 7 * s);
          ctx.fillStyle = col;
          ctx.beginPath();
          ctx.arc(x + ox, y + oy - 2 * s, 5 * s, Math.PI, 0);
          ctx.fill();
        }
        break;
      }
      case 5: { // 죽은 나무
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.beginPath();
        ctx.ellipse(x, y + 18, 16, 5, 0, 0, TAU);
        ctx.fill();
        ctx.strokeStyle = '#3a2a22';
        ctx.lineWidth = 5;
        ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.moveTo(x, y + 18);
        ctx.lineTo(x, y - 14);
        ctx.moveTo(x, y - 2);
        ctx.lineTo(x - 12, y - 14);
        ctx.moveTo(x, y - 8);
        ctx.lineTo(x + 11, y - 20);
        ctx.stroke();
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(x - 12, y - 14);
        ctx.lineTo(x - 16, y - 22);
        ctx.moveTo(x + 11, y - 20);
        ctx.lineTo(x + 17, y - 22);
        ctx.stroke();
        break;
      }
      default: { // 반딧불 풀
        ctx.fillStyle = '#2f4a33';
        ctx.fillRect(x - 6, y, 2, 6);
        ctx.fillRect(x, y - 2, 2, 8);
        ctx.fillRect(x + 5, y + 1, 2, 5);
        const a = 0.4 + 0.4 * Math.sin(time * 3 + v * 20);
        ctx.fillStyle = `rgba(200,255,140,${a})`;
        ctx.beginPath();
        ctx.arc(x + Math.sin(time + v * 9) * 10, y - 10 + Math.cos(time * 1.3 + v * 5) * 6, 1.8, 0, TAU);
        ctx.fill();
      }
    }
  },
};
