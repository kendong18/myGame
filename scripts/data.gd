class_name GameData
extends RefCounted
## 게임 데이터 정의. 밸런스 조절은 대부분 이 파일의 숫자만 바꾸면 됩니다.

const FINAL_BOSS_TIME := 600.0   # 이 시간(초)에 마왕이 등장. 마왕을 쓰러뜨리면 승리
const MAX_WEAPONS := 6
const MAX_PASSIVES := 6
const BASE_SPEED := 150.0        # 플레이어 기본 이동 속도
const BASE_MAGNET := 60.0        # 경험치 보석 기본 획득 범위
const BASE_HP := 100.0

# ── 무기 ────────────────────────────────────
# base: 1레벨 수치 / levels: 2레벨부터 레벨업마다 더해지는 수치 / evolve: 진화 조건
# type 종류: wand, whip, knife, axe, aura, bible, zone, lightning, spiral
const WEAPONS := {
	"whip": {
		"name": "채찍", "type": "whip",
		"desc": "좌우로 적을 후려칩니다.",
		"base": {"damage": 12.0, "cooldown": 1.3, "amount": 1, "area": 1.0, "knockback": 1.2},
		"levels": [
			{"amount": 1, "text": "반대쪽도 공격"},
			{"damage": 6.0, "text": "피해 +6"},
			{"area": 0.1, "damage": 5.0, "text": "범위 +10%, 피해 +5"},
			{"damage": 6.0, "text": "피해 +6"},
			{"area": 0.1, "damage": 5.0, "text": "범위 +10%, 피해 +5"},
			{"damage": 6.0, "text": "피해 +6"},
			{"damage": 8.0, "text": "피해 +8"},
		],
		"evolve": {"passive": "heart", "into": "bloodwhip"},
	},
	"wand": {
		"name": "마법 지팡이", "type": "wand",
		"desc": "가장 가까운 적에게 마법탄을 쏩니다.",
		"base": {"damage": 10.0, "cooldown": 1.0, "amount": 1, "speed": 380.0, "pierce": 1, "duration": 2.0, "area": 1.0},
		"levels": [
			{"amount": 1, "text": "투사체 +1"},
			{"cooldown": -0.2, "text": "쿨타임 -0.2초"},
			{"amount": 1, "text": "투사체 +1"},
			{"damage": 10.0, "text": "피해 +10"},
			{"amount": 1, "text": "투사체 +1"},
			{"pierce": 1, "text": "관통 +1"},
			{"damage": 10.0, "text": "피해 +10"},
		],
		"evolve": {"passive": "tome", "into": "holywand"},
	},
	"knife": {
		"name": "단검", "type": "knife",
		"desc": "바라보는 방향으로 단검을 던집니다.",
		"base": {"damage": 7.0, "cooldown": 0.9, "amount": 1, "speed": 520.0, "pierce": 1, "duration": 1.2},
		"levels": [
			{"amount": 1, "text": "투사체 +1"},
			{"amount": 1, "damage": 5.0, "text": "투사체 +1, 피해 +5"},
			{"amount": 1, "text": "투사체 +1"},
			{"pierce": 1, "text": "관통 +1"},
			{"amount": 1, "text": "투사체 +1"},
			{"amount": 1, "damage": 5.0, "text": "투사체 +1, 피해 +5"},
			{"pierce": 1, "text": "관통 +1"},
		],
		"evolve": {"passive": "bracer", "into": "thousandedge"},
	},
	"axe": {
		"name": "도끼", "type": "axe",
		"desc": "높이 던져 올려 떨어지는 길목의 적을 관통합니다.",
		"base": {"damage": 20.0, "cooldown": 3.5, "amount": 1, "speed": 1.0, "pierce": 3, "area": 1.0, "duration": 3.0},
		"levels": [
			{"amount": 1, "text": "투사체 +1"},
			{"damage": 20.0, "text": "피해 +20"},
			{"pierce": 2, "text": "관통 +2"},
			{"amount": 1, "text": "투사체 +1"},
			{"damage": 20.0, "text": "피해 +20"},
			{"pierce": 2, "text": "관통 +2"},
			{"damage": 20.0, "text": "피해 +20"},
		],
		"evolve": {"passive": "candle", "into": "deathspiral"},
	},
	"garlic": {
		"name": "마늘", "type": "aura",
		"desc": "주변의 적에게 지속 피해를 줍니다.",
		"base": {"damage": 5.0, "interval": 0.45, "radius": 60.0, "knockback": 0.35},
		"levels": [
			{"radius": 12.0, "damage": 2.0, "text": "범위 +20%, 피해 +2"},
			{"damage": 2.0, "interval": -0.05, "text": "피해 +2, 공격 주기 단축"},
			{"radius": 12.0, "damage": 2.0, "text": "범위 +20%, 피해 +2"},
			{"damage": 2.0, "interval": -0.05, "text": "피해 +2, 공격 주기 단축"},
			{"radius": 12.0, "damage": 2.0, "text": "범위 +20%, 피해 +2"},
			{"damage": 3.0, "text": "피해 +3"},
			{"radius": 12.0, "damage": 3.0, "text": "범위 +20%, 피해 +3"},
		],
		"evolve": {"passive": "tomato", "into": "souleater"},
	},
	"bible": {
		"name": "성서", "type": "bible",
		"desc": "주위를 도는 책이 적을 공격합니다.",
		"base": {"damage": 10.0, "cooldown": 3.0, "amount": 1, "speed": 1.0, "area": 1.0, "duration": 3.0, "interval": 0.5, "knockback": 0.8},
		"levels": [
			{"amount": 1, "text": "책 +1"},
			{"speed": 0.3, "area": 0.25, "text": "회전 속도 +30%, 범위 +25%"},
			{"duration": 0.5, "damage": 10.0, "text": "지속 +0.5초, 피해 +10"},
			{"amount": 1, "text": "책 +1"},
			{"speed": 0.3, "area": 0.25, "text": "회전 속도 +30%, 범위 +25%"},
			{"duration": 0.5, "damage": 10.0, "text": "지속 +0.5초, 피해 +10"},
			{"amount": 1, "text": "책 +1"},
		],
		"evolve": {"passive": "hourglass", "into": "vespers"},
	},
	"holywater": {
		"name": "성수", "type": "zone",
		"desc": "적 근처에 성스러운 불꽃 지대를 만듭니다.",
		"base": {"damage": 10.0, "cooldown": 4.5, "amount": 1, "area": 1.0, "duration": 2.0, "interval": 0.3},
		"levels": [
			{"amount": 1, "area": 0.2, "text": "투사체 +1, 범위 +20%"},
			{"damage": 10.0, "duration": 0.5, "text": "피해 +10, 지속 +0.5초"},
			{"amount": 1, "area": 0.2, "text": "투사체 +1, 범위 +20%"},
			{"damage": 10.0, "duration": 0.3, "text": "피해 +10, 지속 +0.3초"},
			{"amount": 1, "area": 0.2, "text": "투사체 +1, 범위 +20%"},
			{"damage": 5.0, "duration": 0.3, "text": "피해 +5, 지속 +0.3초"},
			{"damage": 5.0, "area": 0.2, "text": "피해 +5, 범위 +20%"},
		],
		"evolve": {"passive": "magnet", "into": "fountain"},
	},
	"lightning": {
		"name": "번개 반지", "type": "lightning",
		"desc": "무작위 적에게 번개를 내리칩니다.",
		"base": {"damage": 15.0, "cooldown": 4.5, "amount": 2, "area": 1.0},
		"levels": [
			{"amount": 1, "text": "번개 +1"},
			{"area": 0.3, "damage": 10.0, "text": "범위 +30%, 피해 +10"},
			{"amount": 1, "text": "번개 +1"},
			{"area": 0.3, "damage": 20.0, "text": "범위 +30%, 피해 +20"},
			{"amount": 1, "text": "번개 +1"},
			{"area": 0.3, "damage": 20.0, "text": "범위 +30%, 피해 +20"},
			{"amount": 1, "text": "번개 +1"},
		],
		"evolve": {"passive": "duplicator", "into": "thunderstorm"},
	},

	# ── 진화 무기 (레벨업 선택지에는 나오지 않고, 보물상자로만 얻음) ──
	"bloodwhip": {
		"name": "피의 채찍", "type": "whip", "evolved": true,
		"desc": "적을 벨 때마다 체력을 흡수합니다.",
		"base": {"damage": 55.0, "cooldown": 1.1, "amount": 2, "area": 1.35, "knockback": 1.5, "lifesteal": 1.0},
		"levels": [],
	},
	"holywand": {
		"name": "성스러운 지팡이", "type": "wand", "evolved": true,
		"desc": "쉴 새 없이 마법탄을 난사합니다.",
		"base": {"damage": 22.0, "cooldown": 0.16, "amount": 1, "speed": 520.0, "pierce": 2, "duration": 2.0, "area": 1.2},
		"levels": [],
	},
	"thousandedge": {
		"name": "천 개의 칼날", "type": "knife", "evolved": true,
		"desc": "끝없이 이어지는 칼날의 폭풍.",
		"base": {"damage": 16.0, "cooldown": 0.22, "amount": 3, "speed": 640.0, "pierce": 3, "duration": 1.2},
		"levels": [],
	},
	"deathspiral": {
		"name": "죽음의 나선", "type": "spiral", "evolved": true,
		"desc": "사방으로 회전하는 낫을 날립니다.",
		"base": {"damage": 40.0, "cooldown": 2.6, "amount": 9, "speed": 1.0, "area": 1.5, "duration": 2.5},
		"levels": [],
	},
	"souleater": {
		"name": "영혼 포식자", "type": "aura", "evolved": true,
		"desc": "거대한 오라가 적의 생명력을 빨아들입니다.",
		"base": {"damage": 16.0, "interval": 0.3, "radius": 132.0, "knockback": 0.5, "heal": 1.0},
		"levels": [],
	},
	"vespers": {
		"name": "끝없는 기도", "type": "bible", "evolved": true,
		"desc": "성서가 멈추지 않고 영원히 회전합니다.",
		"base": {"damage": 26.0, "cooldown": 0.0, "amount": 4, "speed": 1.4, "area": 1.45, "duration": INF, "interval": 0.35, "knockback": 1.0},
		"levels": [],
	},
	"fountain": {
		"name": "축복의 샘", "type": "zone", "evolved": true,
		"desc": "거대한 성수 지대가 오래 지속됩니다.",
		"base": {"damage": 25.0, "cooldown": 3.5, "amount": 4, "area": 1.9, "duration": 4.0, "interval": 0.25},
		"levels": [],
	},
	"thunderstorm": {
		"name": "천둥 폭풍", "type": "lightning", "evolved": true,
		"desc": "하늘이 분노하여 번개를 쏟아붓습니다.",
		"base": {"damage": 45.0, "cooldown": 2.8, "amount": 7, "area": 2.2},
		"levels": [],
	},
}

# ── 패시브 아이템 ───────────────────────────
# stat: 플레이어 스탯 이름 / per: 레벨당 증가량
const PASSIVES := {
	"spinach": {"name": "시금치", "desc": "공격력 +10%", "max": 5, "stat": "might", "per": 0.1},
	"armor": {"name": "갑옷", "desc": "받는 피해 -1", "max": 5, "stat": "armor", "per": 1.0},
	"heart": {"name": "생명의 심장", "desc": "최대 체력 +20%", "max": 5, "stat": "max_hp_mul", "per": 0.2},
	"tomato": {"name": "토마토", "desc": "초당 체력 회복 +0.2", "max": 5, "stat": "recovery", "per": 0.2},
	"boots": {"name": "가벼운 신발", "desc": "이동 속도 +10%", "max": 5, "stat": "move_speed", "per": 0.1},
	"tome": {"name": "마법서", "desc": "쿨타임 -8%", "max": 5, "stat": "cooldown", "per": -0.08},
	"candle": {"name": "촛대", "desc": "공격 범위 +10%", "max": 5, "stat": "area", "per": 0.1},
	"duplicator": {"name": "복제 반지", "desc": "투사체 수 +1", "max": 2, "stat": "amount", "per": 1.0},
	"magnet": {"name": "자석", "desc": "획득 범위 +25%", "max": 5, "stat": "magnet", "per": 0.25},
	"crown": {"name": "왕관", "desc": "경험치 획득 +8%", "max": 5, "stat": "growth", "per": 0.08},
	"clover": {"name": "네잎클로버", "desc": "행운 +10% (아이템 드롭 증가)", "max": 5, "stat": "luck", "per": 0.1},
	"bracer": {"name": "팔찌", "desc": "투사체 속도 +10%", "max": 5, "stat": "proj_speed", "per": 0.1},
	"hourglass": {"name": "모래시계", "desc": "무기 지속 시간 +10%", "max": 5, "stat": "duration", "per": 0.1},
}

# ── 적 ──────────────────────────────────────
# ranged: 멀리서 탄을 쏨 / boss: 보스 종류
const ENEMIES := {
	"bat": {"name": "박쥐", "hp": 3.0, "speed": 95.0, "damage": 3.0, "radius": 9.0, "xp": 1, "kb_resist": 0.0, "color": Color(0.62, 0.36, 0.86)},
	"zombie": {"name": "좀비", "hp": 9.0, "speed": 42.0, "damage": 5.0, "radius": 11.0, "xp": 1, "kb_resist": 0.1, "color": Color(0.42, 0.68, 0.31)},
	"skeleton": {"name": "해골", "hp": 18.0, "speed": 58.0, "damage": 6.0, "radius": 11.0, "xp": 2, "kb_resist": 0.2, "color": Color(0.92, 0.9, 0.82)},
	"ghost": {"name": "유령", "hp": 12.0, "speed": 100.0, "damage": 5.0, "radius": 10.0, "xp": 2, "kb_resist": 0.0, "color": Color(0.7, 0.85, 1.0)},
	"mage": {"name": "해골 마법사", "hp": 30.0, "speed": 52.0, "damage": 5.0, "radius": 11.0, "xp": 4, "kb_resist": 0.3, "color": Color(0.5, 0.25, 0.75), "ranged": true},
	"werewolf": {"name": "늑대인간", "hp": 55.0, "speed": 88.0, "damage": 9.0, "radius": 13.0, "xp": 6, "kb_resist": 0.4, "color": Color(0.55, 0.36, 0.2)},
	"golem": {"name": "골렘", "hp": 110.0, "speed": 32.0, "damage": 12.0, "radius": 18.0, "xp": 10, "kb_resist": 0.85, "color": Color(0.5, 0.5, 0.58)},
	# 보스
	"vampire": {"name": "흡혈귀 백작", "hp": 3500.0, "speed": 72.0, "damage": 20.0, "radius": 26.0, "xp": 200, "kb_resist": 0.97, "color": Color(0.55, 0.1, 0.18), "boss": "vampire"},
	"demon": {"name": "마왕", "hp": 18000.0, "speed": 66.0, "damage": 30.0, "radius": 36.0, "xp": 0, "kb_resist": 1.0, "color": Color(0.72, 0.12, 0.18), "boss": "demon"},
}

# 분(minute)별 웨이브: 등장 적 종류 / 초당 스폰 수 / 최대 동시 적 수
const WAVES := [
	{"types": ["bat", "zombie", "zombie"], "rate": 1.3, "max": 60},
	{"types": ["bat", "zombie", "zombie", "skeleton"], "rate": 2.2, "max": 90},
	{"types": ["zombie", "skeleton", "bat", "ghost"], "rate": 3.0, "max": 120},
	{"types": ["skeleton", "ghost", "bat", "skeleton"], "rate": 3.8, "max": 150},
	{"types": ["skeleton", "ghost", "mage", "werewolf"], "rate": 4.6, "max": 180},
	{"types": ["werewolf", "ghost", "skeleton", "mage"], "rate": 5.5, "max": 220},
	{"types": ["werewolf", "golem", "mage", "ghost"], "rate": 6.5, "max": 260},
	{"types": ["golem", "werewolf", "ghost", "mage", "skeleton"], "rate": 7.8, "max": 300},
	{"types": ["golem", "werewolf", "skeleton", "mage", "bat"], "rate": 9.0, "max": 340},
	{"types": ["golem", "werewolf", "ghost", "mage", "bat"], "rate": 10.5, "max": 380},
]

# 시간별 이벤트. elite: 엘리트 / ring: 포위 / stream: 돌진 / boss: 보스
const EVENTS := [
	{"time": 55.0, "type": "elite", "count": 1},
	{"time": 100.0, "type": "ring", "enemy": "bat", "count": 36, "text": "박쥐 떼가 몰려온다!"},
	{"time": 120.0, "type": "elite", "count": 1},
	{"time": 170.0, "type": "stream", "enemy": "bat", "count": 40},
	{"time": 180.0, "type": "elite", "count": 1},
	{"time": 230.0, "type": "ring", "enemy": "zombie", "count": 40, "text": "좀비들에게 포위당했다!"},
	{"time": 240.0, "type": "elite", "count": 1},
	{"time": 300.0, "type": "boss", "enemy": "vampire"},
	{"time": 350.0, "type": "ring", "enemy": "ghost", "count": 44, "text": "유령들이 떠돈다..."},
	{"time": 360.0, "type": "elite", "count": 1},
	{"time": 400.0, "type": "stream", "enemy": "werewolf", "count": 24},
	{"time": 420.0, "type": "elite", "count": 2},
	{"time": 460.0, "type": "ring", "enemy": "skeleton", "count": 50, "text": "해골 군단이 포위했다!"},
	{"time": 480.0, "type": "elite", "count": 2},
	{"time": 520.0, "type": "stream", "enemy": "bat", "count": 60},
	{"time": 540.0, "type": "elite", "count": 3},
	{"time": 560.0, "type": "ring", "enemy": "golem", "count": 24, "text": "골렘들이 땅을 울린다!"},
	{"time": 600.0, "type": "boss", "enemy": "demon"},
]


static func wave_for(time: float) -> Dictionary:
	return WAVES[mini(WAVES.size() - 1, int(time / 60.0))]


## 레벨업에 필요한 경험치
static func xp_for_level(level: int) -> float:
	var req := 4.0 + (level - 1) * 8.0
	if level >= 20:
		req += (level - 19) * 6.0
	if level >= 40:
		req += (level - 39) * 10.0
	return req
