class_name GameData
extends RefCounted
## 게임 데이터 정의. 밸런스 조절은 대부분 이 파일의 숫자만 바꾸면 됩니다.

const TITLE := "꼬물 정거장"          # 임시 제목 (확정 아님)
const TITLE_EN := "KKOMUL\nSTATION"
const SUBTITLE := "우 주   청 소 대"

const FINAL_BOSS_TIME := 600.0   # 이 시간(초)에 최종 보스가 등장. 쓰러뜨리면 승리
const MAX_WEAPONS := 6
const MAX_PASSIVES := 6
const BASE_SPEED := 150.0        # 플레이어 기본 이동 속도
const BASE_MAGNET := 60.0        # 경험치 보석 기본 획득 범위
const BASE_HP := 100.0

# ── 속성과 반응 ─────────────────────────────
# 무기마다 속성이 있고, 적에게 맞히면 상태가 붙는다.
# 이미 다른 속성의 상태가 붙어 있는 적을 맞히면 반응이 터진다.
const ELEMENTS := {
	"heat": {"name": "열", "color": Color(1.0, 0.5, 0.2)},
	"cold": {"name": "냉각", "color": Color(0.5, 0.85, 1.0)},
	"shock": {"name": "전기", "color": Color(1.0, 0.92, 0.3)},
	"gel": {"name": "젤", "color": Color(0.5, 0.95, 0.4)},
	"plasma": {"name": "플라즈마", "color": Color(0.8, 0.45, 1.0)},
}

# 키는 두 속성 이름을 알파벳 순으로 "+" 로 이은 것
const REACTIONS := {
	"gel+shock": {"name": "전도", "desc": "젤 + 전기: 주변 적 4마리에게 전기가 퍼진다", "color": Color(1.0, 0.92, 0.3)},
	"cold+heat": {"name": "열충격", "desc": "냉각 + 열: 큰 피해로 박살 낸다", "color": Color(1.0, 0.75, 0.55)},
	"gel+heat": {"name": "점화", "desc": "젤 + 열: 범위 폭발하고 주변을 태운다", "color": Color(1.0, 0.5, 0.2)},
	"cold+shock": {"name": "정지", "desc": "냉각 + 전기: 적이 잠시 멈춘다", "color": Color(0.6, 0.9, 1.0)},
	"overload": {"name": "과부하", "desc": "플라즈마 + 아무 상태: 모두 터뜨린다", "color": Color(0.85, 0.5, 1.0)},
}

# 상태가 유지되는 시간(초)
const STATUS_TIME := {"gel": 4.0, "cold": 3.0, "heat": 3.0, "shock": 2.0}

# ── 무기 ────────────────────────────────────
# base: 1레벨 수치 / levels: 2레벨부터 레벨업마다 더해지는 수치 / evolve: 진화 조건 / element: 속성
# type 종류: wand, whip, knife, axe, aura, bible, zone, lightning, spiral
const WEAPONS := {
	"torch": {
		"name": "토치", "type": "whip", "element": "heat",
		"desc": "양옆으로 뜨거운 불꽃을 휘둘러 적을 태웁니다.",
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
		"evolve": {"passive": "tank", "into": "plasma_torch"},
	},
	"gelgun": {
		"name": "젤 건", "type": "wand", "element": "gel",
		"desc": "가까운 적에게 끈적한 젤을 쏩니다. 젤에 맞은 적은 느려집니다.",
		"base": {"damage": 10.0, "cooldown": 1.0, "amount": 1, "speed": 380.0, "pierce": 1, "duration": 2.0, "area": 1.0},
		"levels": [
			{"amount": 1, "text": "젤 +1발"},
			{"cooldown": -0.2, "text": "쿨타임 -0.2초"},
			{"amount": 1, "text": "젤 +1발"},
			{"damage": 10.0, "text": "피해 +10"},
			{"amount": 1, "text": "젤 +1발"},
			{"pierce": 1, "text": "관통 +1"},
			{"damage": 10.0, "text": "피해 +10"},
		],
		"evolve": {"passive": "fan", "into": "gel_cannon"},
	},
	"bolt": {
		"name": "전자 볼트", "type": "knife", "element": "shock",
		"desc": "바라보는 방향으로 전기 볼트를 던집니다.",
		"base": {"damage": 7.0, "cooldown": 0.9, "amount": 1, "speed": 520.0, "pierce": 1, "duration": 1.2},
		"levels": [
			{"amount": 1, "text": "볼트 +1개"},
			{"amount": 1, "damage": 5.0, "text": "볼트 +1개, 피해 +5"},
			{"amount": 1, "text": "볼트 +1개"},
			{"pierce": 1, "text": "관통 +1"},
			{"amount": 1, "text": "볼트 +1개"},
			{"amount": 1, "damage": 5.0, "text": "볼트 +1개, 피해 +5"},
			{"pierce": 1, "text": "관통 +1"},
		],
		"evolve": {"passive": "booster", "into": "bolt_storm"},
	},
	"canister": {
		"name": "냉각 캔", "type": "axe", "element": "cold",
		"desc": "냉각 캔을 높이 던져 떨어지는 길목의 적을 얼립니다.",
		"base": {"damage": 20.0, "cooldown": 3.5, "amount": 1, "speed": 1.0, "pierce": 3, "area": 1.0, "duration": 3.0},
		"levels": [
			{"amount": 1, "text": "캔 +1개"},
			{"damage": 20.0, "text": "피해 +20"},
			{"pierce": 2, "text": "관통 +2"},
			{"amount": 1, "text": "캔 +1개"},
			{"damage": 20.0, "text": "피해 +20"},
			{"pierce": 2, "text": "관통 +2"},
			{"damage": 20.0, "text": "피해 +20"},
		],
		"evolve": {"passive": "lens", "into": "ice_spiral"},
	},
	"vacuum": {
		"name": "진공청소기", "type": "aura",
		"desc": "주변의 적을 빨아들이며 지속 피해를 줍니다. (속성 없음)",
		"base": {"damage": 5.0, "interval": 0.45, "radius": 60.0, "knockback": 1.2},
		"levels": [
			{"radius": 12.0, "damage": 2.0, "text": "범위 +20%, 피해 +2"},
			{"damage": 2.0, "interval": -0.05, "text": "피해 +2, 공격 주기 단축"},
			{"radius": 12.0, "damage": 2.0, "text": "범위 +20%, 피해 +2"},
			{"damage": 2.0, "interval": -0.05, "text": "피해 +2, 공격 주기 단축"},
			{"radius": 12.0, "damage": 2.0, "text": "범위 +20%, 피해 +2"},
			{"damage": 3.0, "text": "피해 +3"},
			{"radius": 12.0, "damage": 3.0, "text": "범위 +20%, 피해 +3"},
		],
		"evolve": {"passive": "repair", "into": "super_vacuum"},
	},
	"satellite": {
		"name": "위성 구슬", "type": "bible", "element": "plasma",
		"desc": "플라즈마 구슬이 주위를 돌며 붙어 있는 상태를 폭발시킵니다.",
		"base": {"damage": 10.0, "cooldown": 3.0, "amount": 1, "speed": 1.0, "area": 1.0, "duration": 3.0, "interval": 0.5, "knockback": 0.8},
		"levels": [
			{"amount": 1, "text": "구슬 +1개"},
			{"speed": 0.3, "area": 0.25, "text": "회전 속도 +30%, 범위 +25%"},
			{"duration": 0.5, "damage": 10.0, "text": "지속 +0.5초, 피해 +10"},
			{"amount": 1, "text": "구슬 +1개"},
			{"speed": 0.3, "area": 0.25, "text": "회전 속도 +30%, 범위 +25%"},
			{"duration": 0.5, "damage": 10.0, "text": "지속 +0.5초, 피해 +10"},
			{"amount": 1, "text": "구슬 +1개"},
		],
		"evolve": {"passive": "module", "into": "orbit_system"},
	},
	"hotplate": {
		"name": "핫플레이트", "type": "zone", "element": "heat",
		"desc": "적 근처에 뜨겁게 달궈진 바닥을 만듭니다.",
		"base": {"damage": 10.0, "cooldown": 4.5, "amount": 1, "area": 1.0, "duration": 2.0, "interval": 0.3},
		"levels": [
			{"amount": 1, "area": 0.2, "text": "열판 +1개, 범위 +20%"},
			{"damage": 10.0, "duration": 0.5, "text": "피해 +10, 지속 +0.5초"},
			{"amount": 1, "area": 0.2, "text": "열판 +1개, 범위 +20%"},
			{"damage": 10.0, "duration": 0.3, "text": "피해 +10, 지속 +0.3초"},
			{"amount": 1, "area": 0.2, "text": "열판 +1개, 범위 +20%"},
			{"damage": 5.0, "duration": 0.3, "text": "피해 +5, 지속 +0.3초"},
			{"damage": 5.0, "area": 0.2, "text": "피해 +5, 범위 +20%"},
		],
		"evolve": {"passive": "field", "into": "mega_hotplate"},
	},
	"tesla": {
		"name": "테슬라 코일", "type": "lightning", "element": "shock",
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
		"evolve": {"passive": "cloner", "into": "tesla_storm"},
	},

	# ── 진화 무기 (레벨업 선택지에는 나오지 않고, 보급 상자로만 얻음) ──
	"plasma_torch": {
		"name": "플라즈마 토치", "type": "whip", "element": "heat", "evolved": true,
		"desc": "초고온 불꽃이 적을 태우고 에너지를 흡수합니다.",
		"base": {"damage": 55.0, "cooldown": 1.1, "amount": 2, "area": 1.35, "knockback": 1.5, "lifesteal": 1.0},
		"levels": [],
	},
	"gel_cannon": {
		"name": "젤 캐논", "type": "wand", "element": "gel", "evolved": true,
		"desc": "끈적한 젤을 쉴 새 없이 난사합니다.",
		"base": {"damage": 22.0, "cooldown": 0.16, "amount": 1, "speed": 520.0, "pierce": 2, "duration": 2.0, "area": 1.2},
		"levels": [],
	},
	"bolt_storm": {
		"name": "볼트 폭풍", "type": "knife", "element": "shock", "evolved": true,
		"desc": "끝없이 이어지는 전기 볼트의 폭풍.",
		"base": {"damage": 16.0, "cooldown": 0.22, "amount": 3, "speed": 640.0, "pierce": 3, "duration": 1.2},
		"levels": [],
	},
	"ice_spiral": {
		"name": "냉동 회전날", "type": "spiral", "element": "cold", "evolved": true,
		"desc": "사방으로 회전하는 얼음 날을 날립니다.",
		"base": {"damage": 40.0, "cooldown": 2.6, "amount": 9, "speed": 1.0, "area": 1.5, "duration": 2.5},
		"levels": [],
	},
	"super_vacuum": {
		"name": "초강력 청소기", "type": "aura", "evolved": true,
		"desc": "거대한 흡입력으로 적을 빨아들이고 에너지를 회수합니다.",
		"base": {"damage": 16.0, "interval": 0.3, "radius": 132.0, "knockback": 1.6, "heal": 1.0},
		"levels": [],
	},
	"orbit_system": {
		"name": "위성 궤도 시스템", "type": "bible", "element": "plasma", "evolved": true,
		"desc": "위성이 멈추지 않고 영원히 돕니다.",
		"base": {"damage": 26.0, "cooldown": 0.0, "amount": 4, "speed": 1.4, "area": 1.45, "duration": INF, "interval": 0.35, "knockback": 1.0},
		"levels": [],
	},
	"mega_hotplate": {
		"name": "대형 핫플레이트", "type": "zone", "element": "heat", "evolved": true,
		"desc": "거대한 열판이 오래 지속됩니다.",
		"base": {"damage": 25.0, "cooldown": 3.5, "amount": 4, "area": 1.9, "duration": 4.0, "interval": 0.25},
		"levels": [],
	},
	"tesla_storm": {
		"name": "테슬라 폭풍", "type": "lightning", "element": "shock", "evolved": true,
		"desc": "번개를 쏟아붓습니다.",
		"base": {"damage": 45.0, "cooldown": 2.8, "amount": 7, "area": 2.2},
		"levels": [],
	},
}

# ── 패시브 아이템 ───────────────────────────
# stat: 플레이어 스탯 이름 / per: 레벨당 증가량
const PASSIVES := {
	"cell": {"name": "에너지 셀", "desc": "공격력 +10%", "max": 5, "stat": "might", "per": 0.1},
	"suit": {"name": "방호복", "desc": "받는 피해 -1", "max": 5, "stat": "armor", "per": 1.0},
	"tank": {"name": "산소 탱크", "desc": "최대 체력 +20%", "max": 5, "stat": "max_hp_mul", "per": 0.2},
	"repair": {"name": "수리 키트", "desc": "초당 체력 회복 +0.2", "max": 5, "stat": "recovery", "per": 0.2},
	"jet": {"name": "제트 부츠", "desc": "이동 속도 +10%", "max": 5, "stat": "move_speed", "per": 0.1},
	"fan": {"name": "냉각 팬", "desc": "쿨타임 -8%", "max": 5, "stat": "cooldown", "per": -0.08},
	"lens": {"name": "확장 렌즈", "desc": "공격 범위 +10%", "max": 5, "stat": "area", "per": 0.1},
	"cloner": {"name": "복제 장치", "desc": "투사체 수 +1", "max": 2, "stat": "amount", "per": 1.0},
	"field": {"name": "자기장 발생기", "desc": "획득 범위 +25%", "max": 5, "stat": "magnet", "per": 0.25},
	"chip": {"name": "데이터 칩", "desc": "경험치 획득 +8%", "max": 5, "stat": "growth", "per": 0.08},
	"screw": {"name": "행운의 나사", "desc": "행운 +10% (아이템 드롭 증가)", "max": 5, "stat": "luck", "per": 0.1},
	"booster": {"name": "가속기", "desc": "투사체 속도 +10%", "max": 5, "stat": "proj_speed", "per": 0.1},
	"module": {"name": "타임 모듈", "desc": "무기 지속 시간 +10%", "max": 5, "stat": "duration", "per": 0.1},
	"catalyst": {"name": "촉매 장치", "desc": "속성 반응 피해 +25%", "max": 5, "stat": "reaction", "per": 0.25},
}

# ── 적 ──────────────────────────────────────
# ranged: 멀리서 탄을 쏨 / boss: 보스 종류
const ENEMIES := {
	"moth": {"name": "솜털 나방", "hp": 3.0, "speed": 95.0, "damage": 3.0, "radius": 9.0, "xp": 1, "kb_resist": 0.0, "color": Color(0.72, 0.6, 0.95)},
	"jelly": {"name": "말랑 젤리", "hp": 9.0, "speed": 42.0, "damage": 5.0, "radius": 11.0, "xp": 1, "kb_resist": 0.1, "color": Color(0.5, 0.85, 0.5)},
	"drone": {"name": "정찰 드론", "hp": 18.0, "speed": 58.0, "damage": 6.0, "radius": 11.0, "xp": 2, "kb_resist": 0.2, "color": Color(0.65, 0.72, 0.85)},
	"bubble": {"name": "둥둥 버블", "hp": 12.0, "speed": 100.0, "damage": 5.0, "radius": 10.0, "xp": 2, "kb_resist": 0.0, "color": Color(1.0, 0.7, 0.85)},
	"turret": {"name": "포탑 봇", "hp": 30.0, "speed": 52.0, "damage": 5.0, "radius": 11.0, "xp": 4, "kb_resist": 0.3, "color": Color(1.0, 0.65, 0.3), "ranged": true},
	"hound": {"name": "로봇 멍멍이", "hp": 55.0, "speed": 88.0, "damage": 9.0, "radius": 13.0, "xp": 6, "kb_resist": 0.4, "color": Color(0.55, 0.85, 0.85)},
	"cube": {"name": "박스 로봇", "hp": 110.0, "speed": 32.0, "damage": 12.0, "radius": 18.0, "xp": 10, "kb_resist": 0.85, "color": Color(0.55, 0.62, 0.75)},
	# 보스
	"jellyking": {"name": "젤리 킹", "hp": 3500.0, "speed": 72.0, "damage": 20.0, "radius": 26.0, "xp": 200, "kb_resist": 0.97, "color": Color(0.45, 0.9, 0.65), "boss": "jellyking"},
	"core": {"name": "폭주 메인 컴퓨터", "hp": 18000.0, "speed": 66.0, "damage": 30.0, "radius": 36.0, "xp": 0, "kb_resist": 1.0, "color": Color(0.8, 0.3, 0.5), "boss": "core"},
}

# 분(minute)별 웨이브: 등장 적 종류 / 초당 스폰 수 / 최대 동시 적 수
const WAVES := [
	{"types": ["moth", "jelly", "jelly"], "rate": 1.3, "max": 60},
	{"types": ["moth", "jelly", "jelly", "drone"], "rate": 2.2, "max": 90},
	{"types": ["jelly", "drone", "moth", "bubble"], "rate": 3.0, "max": 120},
	{"types": ["drone", "bubble", "moth", "drone"], "rate": 3.8, "max": 150},
	{"types": ["drone", "bubble", "turret", "hound"], "rate": 4.6, "max": 180},
	{"types": ["hound", "bubble", "drone", "turret"], "rate": 5.5, "max": 220},
	{"types": ["hound", "cube", "turret", "bubble"], "rate": 6.5, "max": 260},
	{"types": ["cube", "hound", "bubble", "turret", "drone"], "rate": 7.8, "max": 300},
	{"types": ["cube", "hound", "drone", "turret", "moth"], "rate": 9.0, "max": 340},
	{"types": ["cube", "hound", "bubble", "turret", "moth"], "rate": 10.5, "max": 380},
]

# 시간별 이벤트. elite: 엘리트 / ring: 포위 / stream: 돌진 / boss: 보스
const EVENTS := [
	{"time": 55.0, "type": "elite", "count": 1},
	{"time": 100.0, "type": "ring", "enemy": "moth", "count": 36, "text": "나방 떼가 몰려온다!"},
	{"time": 120.0, "type": "elite", "count": 1},
	{"time": 170.0, "type": "stream", "enemy": "moth", "count": 40},
	{"time": 180.0, "type": "elite", "count": 1},
	{"time": 230.0, "type": "ring", "enemy": "jelly", "count": 40, "text": "젤리들에게 포위당했다!"},
	{"time": 240.0, "type": "elite", "count": 1},
	{"time": 300.0, "type": "boss", "enemy": "jellyking"},
	{"time": 350.0, "type": "ring", "enemy": "bubble", "count": 44, "text": "버블들이 떠오른다!"},
	{"time": 360.0, "type": "elite", "count": 1},
	{"time": 400.0, "type": "stream", "enemy": "hound", "count": 24},
	{"time": 420.0, "type": "elite", "count": 2},
	{"time": 460.0, "type": "ring", "enemy": "drone", "count": 50, "text": "드론 편대가 포위했다!"},
	{"time": 480.0, "type": "elite", "count": 2},
	{"time": 520.0, "type": "stream", "enemy": "moth", "count": 60},
	{"time": 540.0, "type": "elite", "count": 3},
	{"time": 560.0, "type": "ring", "enemy": "cube", "count": 24, "text": "박스 로봇들이 행진한다!"},
	{"time": 600.0, "type": "boss", "enemy": "core"},
]

# ── 캐릭터 ──────────────────────────────────
# bonus: 플레이어 스탯에 더해지는 값 / cost: 해금 비용(0이면 처음부터 사용 가능)
# palette: style(생김새), suit(옷), suit_dark(옷 그늘), helmet(헬멧), accent(포인트 색)
const CHARACTERS := [
	{
		"id": "coco", "name": "우주인 코코", "weapon": "torch", "cost": 0,
		"desc": "최대 체력 +20%, 방어 +1",
		"bonus": {"max_hp_mul": 0.2, "armor": 1.0},
		"palette": {"style": "human", "suit": Color(0.38, 0.6, 0.95), "suit_dark": Color(0.25, 0.42, 0.75), "helmet": Color(0.95, 0.96, 1.0), "accent": Color(1.0, 0.55, 0.35)},
	},
	{
		"id": "miyu", "name": "고양이 우주인 미유", "weapon": "gelgun", "cost": 0,
		"desc": "쿨타임 -10%, 경험치 +10%",
		"bonus": {"cooldown": -0.1, "growth": 0.1},
		"palette": {"style": "cat", "suit": Color(0.78, 0.55, 0.95), "suit_dark": Color(0.58, 0.36, 0.78), "helmet": Color(1.0, 0.95, 1.0), "accent": Color(1.0, 0.7, 0.85)},
	},
	{
		"id": "scout", "name": "탐사 로봇 삐삐", "weapon": "bolt", "cost": 300,
		"desc": "이동 속도 +20%, 투사체 속도 +10%",
		"bonus": {"move_speed": 0.2, "proj_speed": 0.1},
		"palette": {"style": "robot", "suit": Color(0.45, 0.85, 0.6), "suit_dark": Color(0.28, 0.62, 0.42), "helmet": Color(0.85, 0.95, 0.9), "accent": Color(1.0, 0.9, 0.3)},
	},
	{
		"id": "ppo", "name": "청소 로봇 뽀송", "weapon": "vacuum", "cost": 500,
		"desc": "초당 체력 회복 +0.5, 범위 +10%",
		"bonus": {"recovery": 0.5, "area": 0.1},
		"palette": {"style": "round", "suit": Color(1.0, 0.78, 0.35), "suit_dark": Color(0.9, 0.6, 0.2), "helmet": Color(1.0, 0.95, 0.8), "accent": Color(0.4, 0.85, 1.0)},
	},
	{
		"id": "buru", "name": "곰돌이 정비사 부루", "weapon": "canister", "cost": 800,
		"desc": "공격력 +20%, 이동 속도 -10%",
		"bonus": {"might": 0.2, "move_speed": -0.1},
		"palette": {"style": "bear", "suit": Color(0.95, 0.55, 0.4), "suit_dark": Color(0.75, 0.38, 0.28), "helmet": Color(0.98, 0.93, 0.85), "accent": Color(0.55, 0.38, 0.28)},
	},
	{
		"id": "owl", "name": "올빼미 박사 오린", "weapon": "tesla", "cost": 1200,
		"desc": "행운 +20%, 획득 범위 +30%",
		"bonus": {"luck": 0.2, "magnet": 0.3},
		"palette": {"style": "owl", "suit": Color(0.35, 0.45, 0.85), "suit_dark": Color(0.22, 0.3, 0.62), "helmet": Color(0.92, 0.93, 1.0), "accent": Color(1.0, 0.85, 0.35)},
	},
]

# ── 영구 강화 상점 ───────────────────────────
# 가격 = cost × (현재 단계 + 1)
const SHOP := [
	{"id": "might", "name": "힘", "desc": "공격력 +5%", "max": 5, "cost": 150, "stat": "might", "per": 0.05},
	{"id": "armor", "name": "방어", "desc": "받는 피해 -1", "max": 3, "cost": 400, "stat": "armor", "per": 1.0},
	{"id": "maxhp", "name": "최대 체력", "desc": "최대 체력 +10%", "max": 3, "cost": 150, "stat": "max_hp_mul", "per": 0.1},
	{"id": "recovery", "name": "회복", "desc": "초당 회복 +0.1", "max": 5, "cost": 120, "stat": "recovery", "per": 0.1},
	{"id": "cooldown", "name": "쿨타임", "desc": "쿨타임 -2.5%", "max": 2, "cost": 600, "stat": "cooldown", "per": -0.025},
	{"id": "area", "name": "범위", "desc": "공격 범위 +5%", "max": 2, "cost": 200, "stat": "area", "per": 0.05},
	{"id": "speed", "name": "이동 속도", "desc": "이동 속도 +5%", "max": 2, "cost": 200, "stat": "move_speed", "per": 0.05},
	{"id": "magnet", "name": "자력", "desc": "획득 범위 +25%", "max": 2, "cost": 200, "stat": "magnet", "per": 0.25},
	{"id": "growth", "name": "성장", "desc": "경험치 +3%", "max": 5, "cost": 600, "stat": "growth", "per": 0.03},
	{"id": "greed", "name": "탐욕", "desc": "골드 획득 +10%", "max": 5, "cost": 150, "stat": "greed", "per": 0.1},
	{"id": "luck", "name": "행운", "desc": "행운 +10%", "max": 3, "cost": 400, "stat": "luck", "per": 0.1},
	{"id": "revival", "name": "부활", "desc": "사망 시 1회 부활", "max": 1, "cost": 1000, "stat": "revival", "per": 1.0},
]


static func character(id: String) -> Dictionary:
	for c: Dictionary in CHARACTERS:
		if c.id == id:
			return c
	return CHARACTERS[0]


static func is_valid_character(id: String) -> bool:
	for c: Dictionary in CHARACTERS:
		if c.id == id:
			return true
	return false


static func shop_cost(item: Dictionary, level: int) -> int:
	return int(item.cost) * (level + 1)


## 한 판이 끝났을 때 받는 골드: 주운 동전 + 처치 수 + 생존 시간 + 승리 보너스
static func run_reward(coins: int, kills: int, time: float, won: bool) -> int:
	return coins + int(kills / 5.0) + int(time / 60.0) * 15 + (500 if won else 0)


static func element_color(element: String) -> Color:
	if ELEMENTS.has(element):
		return ELEMENTS[element].color
	return Color(0.85, 0.88, 0.95)


static func element_name(element: String) -> String:
	if ELEMENTS.has(element):
		return ELEMENTS[element].name
	return "없음"


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
