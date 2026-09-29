'use strict';
// ─────────────────────────────────────────────
// 공용 유틸리티
// ─────────────────────────────────────────────

const TAU = Math.PI * 2;

const rand = (a, b) => a + Math.random() * (b - a);
const randInt = (a, b) => Math.floor(rand(a, b + 1));
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);
const lerp = (a, b, t) => a + (b - a) * t;
const dist2 = (ax, ay, bx, by) => {
  const dx = ax - bx, dy = ay - by;
  return dx * dx + dy * dy;
};

function fmtTime(sec) {
  const s = Math.max(0, Math.floor(sec));
  return String(Math.floor(s / 60)).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0');
}

function fmtNum(n) {
  return Math.round(n).toLocaleString('ko-KR');
}

// 가중치 랜덤 선택. items: [{weight, ...}]
function weightedPick(items) {
  let total = 0;
  for (const it of items) total += it.weight;
  let r = Math.random() * total;
  for (const it of items) {
    r -= it.weight;
    if (r <= 0) return it;
  }
  return items[items.length - 1];
}

function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

// 좌표 기반 결정적 해시 (0~1) - 맵 장식 배치용
function hash2(x, y) {
  let h = (Math.imul(x | 0, 374761393) + Math.imul(y | 0, 668265263)) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  h ^= h >>> 16;
  return (h >>> 0) / 4294967296;
}

// 시드 랜덤
function mulberry32(seed) {
  return function () {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// 배열에서 dead 플래그가 선 요소를 제자리에서 제거
function compact(arr) {
  let j = 0;
  for (let i = 0; i < arr.length; i++) {
    const o = arr[i];
    if (!o.dead) arr[j++] = o;
  }
  arr.length = j;
}

// ─────────────────────────────────────────────
// 공간 분할 그리드 (충돌 판정 최적화)
// ─────────────────────────────────────────────
class SpatialGrid {
  constructor(cell = 64) {
    this.cell = cell;
    this.map = new Map();
    this.qid = 0;
  }
  clear() {
    this.map.clear();
  }
  _key(cx, cy) {
    return (cx + 100000) * 200003 + (cy + 100000);
  }
  insert(e) {
    const c = this.cell;
    const x0 = Math.floor((e.x - e.r) / c), x1 = Math.floor((e.x + e.r) / c);
    const y0 = Math.floor((e.y - e.r) / c), y1 = Math.floor((e.y + e.r) / c);
    for (let cx = x0; cx <= x1; cx++) {
      for (let cy = y0; cy <= y1; cy++) {
        const k = this._key(cx, cy);
        let arr = this.map.get(k);
        if (!arr) {
          arr = [];
          this.map.set(k, arr);
        }
        arr.push(e);
      }
    }
  }
  // (x,y) 반경 r 안의 셀에 있는 객체들을 중복 없이 out에 담는다
  query(x, y, r, out) {
    out.length = 0;
    const c = this.cell;
    const id = ++this.qid;
    const x0 = Math.floor((x - r) / c), x1 = Math.floor((x + r) / c);
    const y0 = Math.floor((y - r) / c), y1 = Math.floor((y + r) / c);
    for (let cx = x0; cx <= x1; cx++) {
      for (let cy = y0; cy <= y1; cy++) {
        const arr = this.map.get(this._key(cx, cy));
        if (!arr) continue;
        for (let i = 0; i < arr.length; i++) {
          const e = arr[i];
          if (e._q !== id) {
            e._q = id;
            out.push(e);
          }
        }
      }
    }
    return out;
  }
}

// 이모지를 캔버스에 미리 그려서 캐싱 (fillText 비용 절감)
const EmojiCache = {
  cache: new Map(),
  get(emoji, size) {
    const key = emoji + '|' + size;
    let c = this.cache.get(key);
    if (!c) {
      const s = Math.ceil(size * 2.4);
      c = document.createElement('canvas');
      c.width = c.height = s;
      const x = c.getContext('2d');
      x.textAlign = 'center';
      x.textBaseline = 'middle';
      x.font = `${size * 2}px "Segoe UI Emoji","Apple Color Emoji","Noto Color Emoji",sans-serif`;
      x.fillText(emoji, s / 2, s / 2 + size * 0.12);
      this.cache.set(key, c);
    }
    return c;
  },
};
