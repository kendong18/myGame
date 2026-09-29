'use strict';
// ─────────────────────────────────────────────
// 게임 데이터 정의 (밸런스 조절은 대부분 이 파일에서)
// ─────────────────────────────────────────────

const CONFIG = {
  FINAL_BOSS_TIME: 600, // 10분에 마왕 등장
  MAX_WEAPONS: 6,
  MAX_PASSIVES: 6,
  MAX_GEMS: 300,
  BASE_SPEED: 140,
  BASE_MAGNET: 55,
  PLAYER_RADIUS: 12,
};

// ── 무기 ─────────────────────────────────────
// base: 1레벨 수치, levels: 2~8레벨에서 더해지는 수치
// type: weapons.js 의 동작 종류
const WEAPONS = {
  whip: {
    name: '채찍', icon: '🪢', type: 'whip',
    desc: '좌우로 적을 후려칩니다.',
    base: { damage: 12, cooldown: 1.3, amount: 1, area: 1, knockback: 1.2 },
    levels: [
      { amount: 1, text: '반대쪽도 공격' },
      { damage: 6, text: '피해 +6' },
      { area: 0.1, damage: 5, text: '범위 +10%, 피해 +5' },
      { damage: 6, text: '피해 +6' },
      { area: 0.1, damage: 5, text: '범위 +10%, 피해 +5' },
      { damage: 6, text: '피해 +6' },
      { damage: 8, text: '피해 +8' },
    ],
    evolve: { passive: 'heart', into: 'bloodwhip' },
  },
  wand: {
    name: '마법 지팡이', icon: '🪄', type: 'wand',
    desc: '가장 가까운 적에게 마법탄을 쏩니다.',
    base: { damage: 10, cooldown: 1.2, amount: 1, speed: 380, pierce: 1, duration: 2, area: 1 },
    levels: [
      { amount: 1, text: '투사체 +1' },
      { cooldown: -0.2, text: '쿨타임 -0.2초' },
      { amount: 1, text: '투사체 +1' },
      { damage: 10, text: '피해 +10' },
      { amount: 1, text: '투사체 +1' },
      { pierce: 1, text: '관통 +1' },
      { damage: 10, text: '피해 +10' },
    ],
    evolve: { passive: 'tome', into: 'holywand' },
  },
  knife: {
    name: '단검', icon: '🗡️', type: 'knife',
    desc: '바라보는 방향으로 단검을 던집니다.',
    base: { damage: 7, cooldown: 0.9, amount: 1, speed: 520, pierce: 1, duration: 1.2 },
    levels: [
      { amount: 1, text: '투사체 +1' },
      { amount: 1, damage: 5, text: '투사체 +1, 피해 +5' },
      { amount: 1, text: '투사체 +1' },
      { pierce: 1, text: '관통 +1' },
      { amount: 1, text: '투사체 +1' },
      { amount: 1, damage: 5, text: '투사체 +1, 피해 +5' },
      { pierce: 1, text: '관통 +1' },
    ],
    evolve: { passive: 'bracer', into: 'thousandedge' },
  },
  axe: {
    name: '도끼', icon: '🪓', type: 'axe',
    desc: '높이 던져 올려 떨어지는 적을 관통합니다.',
    base: { damage: 20, cooldown: 3.5, amount: 1, speed: 1, pierce: 3, area: 1, duration: 3 },
    levels: [
      { amount: 1, text: '투사체 +1' },
      { damage: 20, text: '피해 +20' },
      { pierce: 2, text: '관통 +2' },
      { amount: 1, text: '투사체 +1' },
      { damage: 20, text: '피해 +20' },
      { pierce: 2, text: '관통 +2' },
      { damage: 20, text: '피해 +20' },
    ],
    evolve: { passive: 'candle', into: 'deathspiral' },
  },
  garlic: {
    name: '마늘', icon: '🧄', type: 'garlic',
    desc: '주변의 적에게 지속 피해를 줍니다.',
    base: { damage: 5, area: 1, interval: 0.45, knockback: 0.35 },
    levels: [
      { area: 0.2, damage: 2, text: '범위 +20%, 피해 +2' },
      { damage: 2, interval: -0.05, text: '피해 +2, 공격 주기 단축' },
      { area: 0.2, damage: 2, text: '범위 +20%, 피해 +2' },
      { damage: 2, interval: -0.05, text: '피해 +2, 공격 주기 단축' },
      { area: 0.2, damage: 2, text: '범위 +20%, 피해 +2' },
      { damage: 3, text: '피해 +3' },
      { area: 0.2, damage: 3, text: '범위 +20%, 피해 +3' },
    ],
    evolve: { passive: 'tomato', into: 'souleater' },
  },
  bible: {
    name: '성서', icon: '📖', type: 'bible',
    desc: '주위를 도는 책이 적을 공격합니다.',
    base: { damage: 10, cooldown: 3, amount: 1, speed: 1, area: 1, duration: 3, interval: 0.5, knockback: 0.8 },
    levels: [
      { amount: 1, text: '책 +1' },
      { speed: 0.3, area: 0.25, text: '회전 속도 +30%, 범위 +25%' },
      { duration: 0.5, damage: 10, text: '지속 +0.5초, 피해 +10' },
      { amount: 1, text: '책 +1' },
      { speed: 0.3, area: 0.25, text: '회전 속도 +30%, 범위 +25%' },
      { duration: 0.5, damage: 10, text: '지속 +0.5초, 피해 +10' },
      { amount: 1, text: '책 +1' },
    ],
    evolve: { passive: 'hourglass', into: 'vespers' },
  },
  holywater: {
    name: '성수', icon: '💧', type: 'zone',
    desc: '적 근처에 성스러운 불꽃 지대를 만듭니다.',
    base: { damage: 10, cooldown: 4.5, amount: 1, area: 1, duration: 2, interval: 0.3 },
    levels: [
      { amount: 1, area: 0.2, text: '투사체 +1, 범위 +20%' },
      { damage: 10, duration: 0.5, text: '피해 +10, 지속 +0.5초' },
      { amount: 1, area: 0.2, text: '투사체 +1, 범위 +20%' },
      { damage: 10, duration: 0.3, text: '피해 +10, 지속 +0.3초' },
      { amount: 1, area: 0.2, text: '투사체 +1, 범위 +20%' },
      { damage: 5, duration: 0.3, text: '피해 +5, 지속 +0.3초' },
      { damage: 5, area: 0.2, text: '피해 +5, 범위 +20%' },
    ],
    evolve: { passive: 'magnet', into: 'fountain' },
  },
  lightning: {
    name: '번개 반지', icon: '⚡', type: 'lightning',
    desc: '무작위 적에게 번개를 내리칩니다.',
    base: { damage: 15, cooldown: 4.5, amount: 2, area: 1 },
    levels: [
      { amount: 1, text: '번개 +1' },
      { area: 0.3, damage: 10, text: '범위 +30%, 피해 +10' },
      { amount: 1, text: '번개 +1' },
      { area: 0.3, damage: 20, text: '범위 +30%, 피해 +20' },
      { amount: 1, text: '번개 +1' },
      { area: 0.3, damage: 20, text: '범위 +30%, 피해 +20' },
      { amount: 1, text: '번개 +1' },
    ],
    evolve: { passive: 'duplicator', into: 'thunderstorm' },
  },

  // ── 진화 무기 ──
  bloodwhip: {
    name: '피의 채찍', icon: '🩸', type: 'whip', evolved: true, from: 'whip',
    desc: '적을 벨 때마다 체력을 흡수합니다.',
    base: { damage: 55, cooldown: 1.1, amount: 2, area: 1.35, knockback: 1.5, lifesteal: 1 },
    levels: [],
  },
  holywand: {
    name: '성스러운 지팡이', icon: '✨', type: 'wand', evolved: true, from: 'wand',
    desc: '쉴 새 없이 마법탄을 난사합니다.',
    base: { damage: 22, cooldown: 0.16, amount: 1, speed: 520, pierce: 2, duration: 2, area: 1.2 },
    levels: [],
  },
  thousandedge: {
    name: '천 개의 칼날', icon: '🔪', type: 'knife', evolved: true, from: 'knife',
    desc: '끝없이 이어지는 칼날의 폭풍.',
    base: { damage: 16, cooldown: 0.22, amount: 3, speed: 640, pierce: 3, duration: 1.2 },
    levels: [],
  },
  deathspiral: {
    name: '죽음의 나선', icon: '🌀', type: 'spiral', evolved: true, from: 'axe',
    desc: '사방으로 회전하는 낫을 날립니다.',
    base: { damage: 55, cooldown: 2.6, amount: 9, speed: 1, pierce: 999, area: 1.5, duration: 2.5 },
    levels: [],
  },
  souleater: {
    name: '영혼 포식자', icon: '👻', type: 'garlic', evolved: true, from: 'garlic',
    desc: '거대한 오라가 적의 생명력을 빨아들입니다.',
    base: { damage: 16, area: 2.2, interval: 0.3, knockback: 0.5, heal: 1 },
    levels: [],
  },
  vespers: {
    name: '끝없는 기도', icon: '📚', type: 'bible', evolved: true, from: 'bible',
    desc: '성서가 멈추지 않고 영원히 회전합니다.',
    base: { damage: 26, cooldown: 0, amount: 4, speed: 1.4, area: 1.45, duration: Infinity, interval: 0.35, knockback: 1 },
    levels: [],
  },
  fountain: {
    name: '축복의 샘', icon: '⛲', type: 'zone', evolved: true, from: 'holywater',
    desc: '거대한 성수 지대가 오래 지속됩니다.',
    base: { damage: 25, cooldown: 3.5, amount: 4, area: 1.9, duration: 4, interval: 0.25 },
    levels: [],
  },
  thunderstorm: {
    name: '천둥 폭풍', icon: '🌩️', type: 'lightning', evolved: true, from: 'lightning',
    desc: '하늘이 분노하여 번개를 쏟아붓습니다.',
    base: { damage: 45, cooldown: 2.8, amount: 7, area: 2.2 },
    levels: [],
  },
};
for (const id in WEAPONS) {
  WEAPONS[id].id = id;
  WEAPONS[id].maxLevel = WEAPONS[id].levels.length + 1;
}

// ── 패시브 아이템 ────────────────────────────
const PASSIVES = {
  spinach:    { name: '시금치',     icon: '🥬', desc: '공격력 +10%',          maxLevel: 5, apply: (s, l) => (s.might += 0.1 * l) },
  armor:      { name: '갑옷',       icon: '🛡️', desc: '받는 피해 -1',         maxLevel: 5, apply: (s, l) => (s.armor += l) },
  heart:      { name: '생명의 심장', icon: '❤️', desc: '최대 체력 +20%',       maxLevel: 5, apply: (s, l) => (s.maxHpMul += 0.2 * l) },
  tomato:     { name: '토마토',     icon: '🍅', desc: '초당 체력 회복 +0.2',   maxLevel: 5, apply: (s, l) => (s.recovery += 0.2 * l) },
  boots:      { name: '가벼운 신발', icon: '👟', desc: '이동 속도 +10%',       maxLevel: 5, apply: (s, l) => (s.moveSpeed += 0.1 * l) },
  tome:       { name: '마법서',     icon: '📕', desc: '쿨타임 -8%',            maxLevel: 5, apply: (s, l) => (s.cooldown -= 0.08 * l) },
  candle:     { name: '촛대',       icon: '🕯️', desc: '공격 범위 +10%',       maxLevel: 5, apply: (s, l) => (s.area += 0.1 * l) },
  duplicator: { name: '복제 반지',  icon: '💍', desc: '투사체 수 +1',          maxLevel: 2, apply: (s, l) => (s.amount += l) },
  magnet:     { name: '자석',       icon: '🧲', desc: '획득 범위 +25%',        maxLevel: 5, apply: (s, l) => (s.magnet += 0.25 * l) },
  crown:      { name: '왕관',       icon: '👑', desc: '경험치 획득 +8%',       maxLevel: 5, apply: (s, l) => (s.growth += 0.08 * l) },
  clover:     { name: '네잎클로버', icon: '🍀', desc: '행운 +10%',             maxLevel: 5, apply: (s, l) => (s.luck += 0.1 * l) },
  bracer:     { name: '팔찌',       icon: '💪', desc: '투사체 속도 +10%',      maxLevel: 5, apply: (s, l) => (s.projSpeed += 0.1 * l) },
  hourglass:  { name: '모래시계',   icon: '⏳', desc: '무기 지속 시간 +10%',   maxLevel: 5, apply: (s, l) => (s.duration += 0.1 * l) },
};
for (const id in PASSIVES) PASSIVES[id].id = id;

// ── 캐릭터 ───────────────────────────────────
const CHARACTERS = [
  {
    id: 'knight', name: '기사 레온', weapon: 'whip',
    desc: '최대 체력 +20, 방어 +1',
    bonus: { maxHp: 20, armor: 1 },
    palette: { H: '#8a5a2b', B: '#5b7bb5', A: '#c0c8d8', c: '#e8c040', L: '#3b3f58', D: '#5a3a22' },
  },
  {
    id: 'mage', name: '마법사 루나', weapon: 'wand',
    desc: '쿨타임 -10%, 경험치 +10%',
    bonus: { cooldown: -0.1, growth: 0.1 },
    palette: { H: '#f0d060', B: '#7a3fb0', A: '#b080e0', c: '#40e0d0', L: '#3a2350', D: '#2a1a3a' },
  },
  {
    id: 'hunter', name: '사냥꾼 카인', weapon: 'knife',
    desc: '이동 속도 +20%, 투사체 속도 +10%',
    bonus: { moveSpeed: 0.2, projSpeed: 0.1 },
    palette: { H: '#2a2a2a', B: '#3f8f4a', A: '#7a5a30', c: '#c0a060', L: '#4a3a2a', D: '#3a2a1a' },
  },
  {
    id: 'priest', name: '성직자 세라', weapon: 'garlic',
    desc: '초당 체력 회복 +0.5, 범위 +10%',
    bonus: { recovery: 0.5, area: 0.1 },
    palette: { H: '#e07a30', B: '#e8e8f0', A: '#e0b840', c: '#d04040', L: '#8a8aa0', D: '#5a5a70' },
  },
  {
    id: 'warrior', name: '전사 브란', weapon: 'axe',
    desc: '공격력 +20%, 이동 속도 -10%',
    bonus: { might: 0.2, moveSpeed: -0.1 },
    palette: { H: '#c03020', B: '#8a3a2a', A: '#6a6a6a', c: '#d0a040', L: '#3a2a2a', D: '#2a1a1a' },
  },
  {
    id: 'sage', name: '현자 오린', weapon: 'lightning',
    desc: '행운 +20%, 획득 범위 +30%',
    bonus: { luck: 0.2, magnet: 0.3 },
    palette: { H: '#d8d8e8', B: '#2a4a8a', A: '#4a7ad0', c: '#f0e060', L: '#1a2a4a', D: '#1a1a2a' },
  },
];

// ── 적 ──────────────────────────────────────
const ENEMIES = {
  bat:      { name: '박쥐',        sprite: 'bat',      hp: 5,   speed: 95,  damage: 3,  r: 9,  xp: 1,  kbResist: 0,   px: 1.6, erratic: true },
  zombie:   { name: '좀비',        sprite: 'zombie',   hp: 14,  speed: 42,  damage: 5,  r: 11, xp: 1,  kbResist: 0.1, px: 2 },
  skeleton: { name: '해골',        sprite: 'skeleton', hp: 25,  speed: 58,  damage: 6,  r: 11, xp: 2,  kbResist: 0.2, px: 2 },
  ghost:    { name: '유령',        sprite: 'ghost',    hp: 18,  speed: 100, damage: 5,  r: 10, xp: 2,  kbResist: 0,   px: 2, alpha: 0.78 },
  mage:     { name: '해골 마법사', sprite: 'mage',     hp: 40,  speed: 50,  damage: 5,  r: 11, xp: 4,  kbResist: 0.3, px: 2, ranged: true },
  werewolf: { name: '늑대인간',    sprite: 'werewolf', hp: 70,  speed: 88,  damage: 9,  r: 13, xp: 6,  kbResist: 0.4, px: 2.2 },
  golem:    { name: '골렘',        sprite: 'golem',    hp: 130, speed: 32,  damage: 12, r: 18, xp: 10, kbResist: 0.85, px: 3 },
  // 보스
  vampire:  { name: '흡혈귀 백작', sprite: 'vampire',  hp: 3500,  speed: 72, damage: 20, r: 26, xp: 200, kbResist: 0.97, px: 4.5, boss: 'vampire' },
  demon:    { name: '마왕',        sprite: 'demon',    hp: 18000, speed: 66, damage: 30, r: 36, xp: 0,   kbResist: 1,    px: 6,   boss: 'demon' },
};
for (const id in ENEMIES) ENEMIES[id].id = id;

// 분(minute)별 웨이브: 등장 적 종류, 초당 스폰 수, 최대 동시 적 수
const WAVES = [
  { types: ['bat', 'zombie', 'zombie'], rate: 1.3, max: 60 },
  { types: ['bat', 'zombie', 'zombie', 'skeleton'], rate: 2.2, max: 90 },
  { types: ['zombie', 'skeleton', 'bat', 'ghost'], rate: 3.0, max: 120 },
  { types: ['skeleton', 'ghost', 'bat', 'skeleton'], rate: 3.8, max: 150 },
  { types: ['skeleton', 'ghost', 'mage', 'werewolf'], rate: 4.6, max: 180 },
  { types: ['werewolf', 'ghost', 'skeleton', 'mage'], rate: 5.5, max: 220 },
  { types: ['werewolf', 'golem', 'mage', 'ghost'], rate: 6.5, max: 260 },
  { types: ['golem', 'werewolf', 'ghost', 'mage', 'skeleton'], rate: 7.8, max: 300 },
  { types: ['golem', 'werewolf', 'skeleton', 'mage', 'bat'], rate: 9.0, max: 340 },
  { types: ['golem', 'werewolf', 'ghost', 'mage', 'bat'], rate: 10.5, max: 380 },
];

// ── 영구 강화 상점 ───────────────────────────
const SHOP = [
  { id: 'might',    name: '힘',        icon: '💥', desc: '공격력 +5%',        max: 5, cost: 200,  apply: (s, l) => (s.might += 0.05 * l) },
  { id: 'armor',    name: '방어',      icon: '🛡️', desc: '받는 피해 -1',      max: 3, cost: 600,  apply: (s, l) => (s.armor += l) },
  { id: 'maxhp',    name: '최대 체력', icon: '❤️', desc: '최대 체력 +10%',    max: 3, cost: 200,  apply: (s, l) => (s.maxHpMul += 0.1 * l) },
  { id: 'recovery', name: '회복',      icon: '🍅', desc: '초당 회복 +0.1',    max: 5, cost: 160,  apply: (s, l) => (s.recovery += 0.1 * l) },
  { id: 'cooldown', name: '쿨타임',    icon: '📕', desc: '쿨타임 -2.5%',      max: 2, cost: 900,  apply: (s, l) => (s.cooldown -= 0.025 * l) },
  { id: 'area',     name: '범위',      icon: '🕯️', desc: '공격 범위 +5%',     max: 2, cost: 300,  apply: (s, l) => (s.area += 0.05 * l) },
  { id: 'speed',    name: '이동 속도', icon: '👟', desc: '이동 속도 +5%',     max: 2, cost: 300,  apply: (s, l) => (s.moveSpeed += 0.05 * l) },
  { id: 'magnet',   name: '자력',      icon: '🧲', desc: '획득 범위 +25%',    max: 2, cost: 300,  apply: (s, l) => (s.magnet += 0.25 * l) },
  { id: 'growth',   name: '성장',      icon: '👑', desc: '경험치 +3%',        max: 5, cost: 900,  apply: (s, l) => (s.growth += 0.03 * l) },
  { id: 'greed',    name: '탐욕',      icon: '💰', desc: '골드 획득 +10%',    max: 5, cost: 200,  apply: (s, l) => (s.greed += 0.1 * l) },
  { id: 'luck',     name: '행운',      icon: '🍀', desc: '행운 +10%',         max: 3, cost: 600,  apply: (s, l) => (s.luck += 0.1 * l) },
  { id: 'revival',  name: '부활',      icon: '💫', desc: '사망 시 1회 부활',  max: 1, cost: 1500, apply: (s, l) => (s.revival += l) },
];
const shopCost = (item, level) => item.cost * (level + 1);

// 기본 플레이어 스탯
function baseStats() {
  return {
    maxHp: 100, maxHpMul: 1, moveSpeed: 1, might: 1, area: 1, cooldown: 1, amount: 0,
    armor: 0, recovery: 0, growth: 1, luck: 1, magnet: 1, projSpeed: 1, duration: 1,
    greed: 1, revival: 0,
  };
}

// 레벨업에 필요한 경험치
function xpForLevel(level) {
  let req = 5 + (level - 1) * 10;
  if (level >= 20) req += (level - 19) * 6;
  if (level >= 40) req += (level - 39) * 10;
  return req;
}
