class_name Enemy
extends Node2D
## 적 한 마리. 이동/충돌은 Main 이 일괄 처리한다.

const BOMB_RADIUS := 78.0      # 폭탄 열매가 터지는 범위

var kind := ""
var hp := 1.0
var max_hp := 1.0
var speed := 50.0
var damage := 1.0
var radius := 10.0
var xp := 1
var kb_resist := 0.0
var color := Color.WHITE
var flash := 0.0
var knock := Vector2.ZERO
var dead := false
var straight := Vector2.ZERO   # 0이 아니면 플레이어를 무시하고 직진
var wobble := 0.0
var face := 1.0
var push := Vector2.ZERO       # 겹침 방지 밀어내기 (프레임 절약을 위해 재사용)

var elite := false
var boss := ""                 # 보스 종류 ("jellyking", "core"), 일반 적은 빈 문자열
var ranged := false
var shoot_t := 0.0
var skill_t := 0.0             # 보스 패턴 타이머
var skill2_t := 0.0
var spin := 0.0
var skill3_t := 0.0
var rage := false              # 보스가 화가 난 상태 (그림이 바뀐다)

# 스테이지 적의 특성 (data.gd 의 ENEMIES 에서 읽는다)
var move := ""                 # zigzag / bomber / charger
var pattern := ""              # 원거리 탄 모양 (fan)
var weak: Array = []
var resist: Array = []
var fuse := -1.0               # 폭탄 열매: 0 이상이면 심지가 타는 중
var charge_state := 0          # 돌진: 0 걷기 / 1 준비 / 2 돌진
var charge_t := 0.0
var charge_dir := Vector2.RIGHT
var use_override := false      # 보스가 이동을 직접 정할 때 (돌진 등)
var vel_override := Vector2.ZERO

# 속성 상태 (원소 이름 -> 남은 시간), 정지, 화상
var status: Dictionary = {}
var stun := 0.0
var suction := 0.0              # 진공청소기에 붙잡혀 느려지는 시간
var burn_dps := 0.0
var burn_tick := 0.0
var burn_src: Weapon = null


func setup(k: String, hp_mul: float, is_elite: bool = false) -> void:
	kind = k
	var d: Dictionary = GameData.ENEMIES[k]
	max_hp = float(d.hp) * hp_mul
	hp = max_hp
	speed = float(d.speed) * randf_range(0.92, 1.08)
	damage = float(d.damage)
	radius = float(d.radius)
	xp = int(d.xp)
	kb_resist = float(d.kb_resist)
	color = d.color
	wobble = randf() * TAU
	ranged = d.get("ranged", false)
	boss = d.get("boss", "")
	shoot_t = randf_range(0.5, 2.0)
	skill_t = 2.0
	skill2_t = 5.0
	skill3_t = 9.0
	move = d.get("move", "")
	pattern = d.get("pattern", "")
	weak = d.get("weak", [])
	resist = d.get("resist", [])
	charge_t = randf_range(1.5, 4.0)
	if boss != "":
		max_hp = float(d.hp)     # 보스 체력은 시간에 따라 늘지 않음
		hp = max_hp
		speed = float(d.speed)
	elif is_elite:
		elite = true
		max_hp *= GameData.ELITE_HP_MUL
		hp = max_hp
		radius *= 1.5
		damage *= 1.3
		xp *= 5
		kb_resist = minf(0.9, kb_resist + 0.5)
		speed *= 0.95


## 상태에 따른 이동 속도 배율. 보스는 효과가 절반만 적용된다.
func speed_mult() -> float:
	if stun > 0.0:
		return 0.0
	var m := 1.0
	if status.has("gel"):
		m *= 0.65
	if status.has("cold"):
		m *= 0.5
	if suction > 0.0:
		m *= 0.55
	if boss != "":
		m = 1.0 - (1.0 - m) * 0.5
	return m


func _draw() -> void:
	var r := radius
	var white := flash > 0.0
	var c := Color.WHITE if white else color
	var dark := Color.WHITE if white else color.darkened(0.35)
	var light := Color.WHITE if white else color.lightened(0.3)
	draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.95), r * 0.95, r * 0.3), Color(0, 0, 0, 0.3))

	match kind:
		"moth":
			var wing := Color(light.r, light.g, light.b, 0.9)
			draw_colored_polygon(Util.ellipse(Vector2(-r * 1.05, -r * 0.25), r * 0.95, r * 0.7, 14), wing)
			draw_colored_polygon(Util.ellipse(Vector2(r * 1.05, -r * 0.25), r * 0.95, r * 0.7, 14), wing)
			draw_circle(Vector2.ZERO, r * 0.85, c)
			draw_circle(Vector2(0, r * 0.25), r * 0.55, light)
			for sx in [-1.0, 1.0]:
				draw_line(Vector2(sx * r * 0.3, -r * 0.7), Vector2(sx * r * 0.65, -r * 1.25), dark, 1.5)
				draw_circle(Vector2(sx * r * 0.65, -r * 1.3), r * 0.16, Color(1.0, 0.85, 0.4))
			Util.eye(self, Vector2(-r * 0.33, -r * 0.1), r * 0.3)
			Util.eye(self, Vector2(r * 0.33, -r * 0.1), r * 0.3)
			Util.cheek(self, Vector2(-r * 0.6, r * 0.25), r * 0.15)
			Util.cheek(self, Vector2(r * 0.6, r * 0.25), r * 0.15)
		"jelly":
			var pts := Util.blob(Vector2(0, r * 0.1), r * 1.0, r * 1.05)
			draw_colored_polygon(pts, c)
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.5), r * 0.8, r * 0.3, 14), light)
			Util.outline(self, pts, dark, 1.5)
			draw_colored_polygon(Util.ellipse(Vector2(-r * 0.42, -r * 0.62), r * 0.28, r * 0.15, 10), Color(1, 1, 1, 0.6))
			Util.eye(self, Vector2(-r * 0.36, -r * 0.1), r * 0.3)
			Util.eye(self, Vector2(r * 0.36, -r * 0.1), r * 0.3)
			draw_arc(Vector2(0, r * 0.12), r * 0.22, 0.25, PI - 0.25, 8, dark, 1.5)
			Util.cheek(self, Vector2(-r * 0.66, r * 0.12), r * 0.15)
			Util.cheek(self, Vector2(r * 0.66, r * 0.12), r * 0.15)
		"drone":
			draw_line(Vector2(-r * 0.85, -r * 1.05), Vector2(r * 0.85, -r * 1.05), dark, 2.0)
			draw_line(Vector2(0, -r * 1.05), Vector2(0, -r * 0.8), dark, 2.0)
			draw_circle(Vector2.ZERO, r, c)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, dark, 1.5)
			draw_circle(Vector2(0, -r * 0.05), r * 0.62, Color.WHITE if white else Color(0.14, 0.18, 0.3))
			draw_circle(Vector2(0, -r * 0.05), r * 0.44, Color.WHITE if white else Color(0.3, 0.85, 1.0))
			draw_circle(Vector2(0, -r * 0.05), r * 0.22, Color(0.05, 0.1, 0.2))
			draw_circle(Vector2(-r * 0.15, -r * 0.22), r * 0.12, Color.WHITE)
			draw_circle(Vector2(-r * 0.85, r * 0.3), r * 0.13, Color(1.0, 0.45, 0.55))
			draw_circle(Vector2(r * 0.85, r * 0.3), r * 0.13, Color(0.5, 1.0, 0.6))
		"bubble":
			var bc := Color(c.r, c.g, c.b, 0.6)
			draw_circle(Vector2.ZERO, r, bc)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(1, 1, 1, 0.85), 1.5)
			draw_arc(Vector2.ZERO, r * 0.72, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.9), 2.0)
			Util.eye(self, Vector2(-r * 0.3, r * 0.0), r * 0.27)
			Util.eye(self, Vector2(r * 0.3, r * 0.0), r * 0.27)
			draw_arc(Vector2(0, r * 0.32), r * 0.18, 0.25, PI - 0.25, 6, Color(0.7, 0.25, 0.45), 1.3)
			Util.cheek(self, Vector2(-r * 0.55, r * 0.25), r * 0.13)
			Util.cheek(self, Vector2(r * 0.55, r * 0.25), r * 0.13)
		"turret":
			draw_circle(Vector2(-r * 0.55, r * 0.85), r * 0.28, dark)
			draw_circle(Vector2(r * 0.55, r * 0.85), r * 0.28, dark)
			draw_rect(Rect2(-r * 0.85, -r * 0.2, r * 1.7, r * 1.0), c)
			draw_circle(Vector2(0, -r * 0.2), r * 0.85, c)
			draw_rect(Rect2(-r * 0.85, r * 0.55, r * 1.7, r * 0.25), dark)
			draw_rect(Rect2(r * 0.5, -r * 0.5, r * 1.0, r * 0.42), dark)
			draw_circle(Vector2(r * 1.5, -r * 0.29), r * 0.3, Color(1.0, 0.92, 0.6))
			draw_line(Vector2(0, -r * 1.0), Vector2(0, -r * 1.5), dark, 1.5)
			draw_circle(Vector2(0, -r * 1.55), r * 0.2, Color(1.0, 0.35, 0.4))
			Util.eye(self, Vector2(-r * 0.32, -r * 0.2), r * 0.27)
			Util.eye(self, Vector2(r * 0.1, -r * 0.2), r * 0.27)
		"hound":
			for lx in [-0.7, -0.15, 0.4]:
				draw_rect(Rect2(r * lx, r * 0.55, r * 0.26, r * 0.4), dark)
			draw_line(Vector2(-r * 0.85, -r * 0.05), Vector2(-r * 1.35, -r * 0.6), dark, 3.0)
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.15), r * 1.0, r * 0.68, 16), c)
			draw_colored_polygon(Util.ellipse(Vector2(-r * 0.1, r * 0.4), r * 0.65, r * 0.3, 12), light)
			draw_circle(Vector2(r * 0.55, -r * 0.35), r * 0.62, c)
			draw_rect(Rect2(r * 0.85, -r * 0.35, r * 0.5, r * 0.36), light)
			draw_circle(Vector2(r * 1.35, -r * 0.2), r * 0.13, Color(0.15, 0.15, 0.25))
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.15, -r * 0.7), Vector2(r * 0.25, -r * 1.3), Vector2(r * 0.6, -r * 0.85)]), dark)
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.6, -r * 0.85), Vector2(r * 0.9, -r * 1.3), Vector2(r * 1.0, -r * 0.6)]), dark)
			Util.eye(self, Vector2(r * 0.55, -r * 0.5), r * 0.25)
			Util.eye(self, Vector2(r * 0.15, -r * 0.4), r * 0.2)
			draw_line(Vector2(r * 0.15, -r * 0.02), Vector2(r * 0.5, r * 0.15), Color(1.0, 0.4, 0.5), 3.0)
			draw_circle(Vector2(r * 0.35, r * 0.2), r * 0.13, Color(1.0, 0.85, 0.3))
		"cube":
			draw_rect(Rect2(-r * 0.6, r * 0.65, r * 0.4, r * 0.3), dark)
			draw_rect(Rect2(r * 0.2, r * 0.65, r * 0.4, r * 0.3), dark)
			draw_rect(Rect2(-r * 1.2, -r * 0.3, r * 0.35, r * 0.9), dark)
			draw_rect(Rect2(r * 0.85, -r * 0.3, r * 0.35, r * 0.9), dark)
			draw_circle(Vector2(-r * 1.02, r * 0.68), r * 0.24, light)
			draw_circle(Vector2(r * 1.02, r * 0.68), r * 0.24, light)
			draw_rect(Rect2(-r * 0.85, -r * 0.8, r * 1.7, r * 1.5), c)
			draw_rect(Rect2(-r * 0.85, -r * 0.8, r * 1.7, r * 0.3), light)
			draw_rect(Rect2(-r * 0.85, -r * 0.8, r * 1.7, r * 1.5), dark, false, 2.0)
			draw_rect(Rect2(-r * 0.62, -r * 0.42, r * 1.24, r * 0.85), Color.WHITE if white else Color(0.1, 0.16, 0.28))
			draw_rect(Rect2(-r * 0.4, -r * 0.25, r * 0.22, r * 0.32), Color.WHITE if white else Color(0.4, 0.95, 1.0))
			draw_rect(Rect2(r * 0.18, -r * 0.25, r * 0.22, r * 0.32), Color.WHITE if white else Color(0.4, 0.95, 1.0))
			draw_polyline(PackedVector2Array([Vector2(-r * 0.3, r * 0.18), Vector2(-r * 0.15, r * 0.3), Vector2(r * 0.15, r * 0.3), Vector2(r * 0.3, r * 0.18)]), Color(0.4, 0.95, 1.0), 2.0)
			draw_line(Vector2(0, -r * 0.8), Vector2(0, -r * 1.15), dark, 2.0)
			draw_circle(Vector2(0, -r * 1.2), r * 0.13, Color(1.0, 0.85, 0.3))
			for rp in [Vector2(-0.72, -0.68), Vector2(0.72, -0.68), Vector2(-0.72, 0.58), Vector2(0.72, 0.58)]:
				draw_circle(rp * r, r * 0.06, dark)
		"sprout":
			# 새싹이: 통통한 몸에 잎사귀 두 장
			draw_line(Vector2(0, -r * 0.75), Vector2(0, -r * 1.2), dark, 2.0)
			var leaf := Color.WHITE if white else Color(0.42, 0.82, 0.32)
			for sx in [-1.0, 1.0]:
				_petal(Vector2(sx * r * 0.62, -r * 1.3), sx * -0.5, r * 0.6, r * 0.3, leaf)
			draw_circle(Vector2(0, r * 0.05), r * 0.95, c)
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.55), r * 0.7, r * 0.28, 12), light)
			draw_rect(Rect2(-r * 0.5, r * 0.8, r * 0.3, r * 0.22), dark)
			draw_rect(Rect2(r * 0.2, r * 0.8, r * 0.3, r * 0.22), dark)
			Util.eye(self, Vector2(-r * 0.36, -r * 0.05), r * 0.3)
			Util.eye(self, Vector2(r * 0.36, -r * 0.05), r * 0.3)
			draw_arc(Vector2(0, r * 0.15), r * 0.2, 0.25, PI - 0.25, 8, dark, 1.5)
			Util.cheek(self, Vector2(-r * 0.66, r * 0.17), r * 0.16)
			Util.cheek(self, Vector2(r * 0.66, r * 0.17), r * 0.16)
		"bee":
			# 꿀벌 드론: 동글동글한 몸에 줄무늬와 작은 날개 (오른쪽을 바라보는 그림)
			var wing_c := Color(1, 1, 1, 0.8)
			_petal(Vector2(-r * 0.15, -r * 0.95), -0.3, r * 0.55, r * 0.95, wing_c)
			_petal(Vector2(r * 0.45, -r * 0.95), 0.3, r * 0.5, r * 0.85, wing_c)
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 1.0, -r * 0.15), Vector2(-r * 1.5, 0), Vector2(-r * 1.0, r * 0.2)]), dark)
			draw_colored_polygon(Util.ellipse(Vector2.ZERO, r * 1.05, r * 0.85, 18), c)
			var stripe := Color.WHITE if white else Color(0.3, 0.18, 0.1)
			draw_colored_polygon(Util.ellipse(Vector2(-r * 0.35, 0), r * 0.17, r * 0.78, 10), stripe)
			draw_colored_polygon(Util.ellipse(Vector2(-r * 0.75, 0), r * 0.12, r * 0.55, 10), stripe)
			Util.eye(self, Vector2(r * 0.45, -r * 0.12), r * 0.3)
			Util.cheek(self, Vector2(r * 0.6, r * 0.3), r * 0.15)
			draw_line(Vector2(r * 0.4, -r * 0.7), Vector2(r * 0.7, -r * 1.2), dark, 1.2)
			draw_circle(Vector2(r * 0.72, -r * 1.25), r * 0.14, Color(1.0, 0.5, 0.4))
		"mushroom":
			# 포자 버섯: 하얀 기둥에 동그란 분홍 갓
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.4), r * 0.66, r * 0.68, 14), Color.WHITE if white else Color(0.98, 0.93, 0.83))
			draw_rect(Rect2(-r * 0.45, r * 0.9, r * 0.3, r * 0.2), dark)
			draw_rect(Rect2(r * 0.15, r * 0.9, r * 0.3, r * 0.2), dark)
			var cap := PackedVector2Array()
			for i in 17:
				var a := PI + PI * float(i) / 16.0
				cap.append(Vector2(cos(a) * r * 1.3, sin(a) * r * 1.0 - r * 0.1))
			draw_colored_polygon(cap, c)
			draw_colored_polygon(Util.ellipse(Vector2(0, -r * 0.1), r * 1.3, r * 0.22, 14), dark)
			for sp in [Vector3(-0.62, -0.62, 0.24), Vector3(0.28, -0.88, 0.19), Vector3(0.78, -0.4, 0.16), Vector3(-0.15, -0.35, 0.12)]:
				draw_circle(Vector2(sp.x, sp.y) * r, sp.z * r, Color(1, 1, 1, 0.9))
			Util.eye(self, Vector2(-r * 0.27, r * 0.38), r * 0.24)
			Util.eye(self, Vector2(r * 0.27, r * 0.38), r * 0.24)
			draw_arc(Vector2(0, r * 0.55), r * 0.14, 0.25, PI - 0.25, 6, dark, 1.3)
			Util.cheek(self, Vector2(-r * 0.5, r * 0.6), r * 0.12)
			Util.cheek(self, Vector2(r * 0.5, r * 0.6), r * 0.12)
		"bulb":
			# 폭탄 열매: 도망치지 않고 달려와서 터지는 빨간 열매. 심지가 타면 폭발 범위가 보인다
			var lit := fuse >= 0.0
			var bc := c
			if lit and not white:
				bc = c.lerp(Color(1.0, 0.15, 0.15), 0.5 + 0.5 * sin(fuse * 34.0))
			if lit:
				draw_circle(Vector2.ZERO, BOMB_RADIUS, Color(1.0, 0.3, 0.2, 0.12))
				draw_arc(Vector2.ZERO, BOMB_RADIUS, 0.0, TAU, 40, Color(1.0, 0.45, 0.3, 0.75), 2.5)
			draw_circle(Vector2(0, r * 0.1), r, bc)
			draw_colored_polygon(Util.ellipse(Vector2(-r * 0.35, -r * 0.35), r * 0.3, r * 0.17, 10), Color(1, 1, 1, 0.5))
			var lf := Color.WHITE if white else Color(0.35, 0.72, 0.3)
			var star := PackedVector2Array()
			for i in 10:
				var a := TAU * float(i) / 10.0 - PI / 2.0
				var rr := r * (0.6 if i % 2 == 0 else 0.25)
				star.append(Vector2(cos(a) * rr, -r * 0.85 + sin(a) * rr * 0.5))
			draw_colored_polygon(star, lf)
			draw_line(Vector2(0, -r * 0.9), Vector2(r * 0.15, -r * 1.3), dark, 1.6)
			draw_circle(Vector2(r * 0.17, -r * 1.35), r * 0.13, Color(1.0, 0.9, 0.3) if not lit else Color(1.0, 0.95, 0.7))
			Util.eye(self, Vector2(-r * 0.34, 0), r * 0.28)
			Util.eye(self, Vector2(r * 0.34, 0), r * 0.28)
			draw_line(Vector2(-r * 0.62, -r * 0.34), Vector2(-r * 0.12, -r * 0.2), dark, 1.6)
			draw_line(Vector2(r * 0.62, -r * 0.34), Vector2(r * 0.12, -r * 0.2), dark, 1.6)
			if lit:
				draw_circle(Vector2(0, r * 0.5), r * 0.2, Color(0.25, 0.05, 0.1))
			else:
				draw_arc(Vector2(0, r * 0.38), r * 0.2, 0.25, PI - 0.25, 8, dark, 1.5)
		"sunflower":
			# 해바라기 사수: 노란 꽃잎 가운데 얼굴이 있다
			draw_rect(Rect2(-r * 0.55, r * 0.85, r * 0.35, r * 0.3), dark)
			draw_rect(Rect2(r * 0.2, r * 0.85, r * 0.35, r * 0.3), dark)
			var leafg := Color.WHITE if white else Color(0.35, 0.7, 0.3)
			_petal(Vector2(-r * 0.95, r * 0.6), 0.6, r * 0.5, r * 0.22, leafg)
			_petal(Vector2(r * 0.95, r * 0.6), -0.6, r * 0.5, r * 0.22, leafg)
			for i in 12:
				_petal(Vector2.from_angle(TAU * float(i) / 12.0) * r * 0.95, TAU * float(i) / 12.0, r * 0.5, r * 0.25, c)
			for i in 12:
				_petal(Vector2.from_angle(TAU * float(i) / 12.0 + 0.26) * r * 0.78, TAU * float(i) / 12.0 + 0.26, r * 0.36, r * 0.2, light)
			draw_circle(Vector2.ZERO, r * 0.7, Color.WHITE if white else Color(0.55, 0.36, 0.2))
			draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 20, Color(0.35, 0.22, 0.12), 1.5)
			Util.eye(self, Vector2(-r * 0.27, -r * 0.1), r * 0.22)
			Util.eye(self, Vector2(r * 0.27, -r * 0.1), r * 0.22)
			draw_arc(Vector2(0, r * 0.12), r * 0.16, 0.25, PI - 0.25, 6, Color(0.95, 0.85, 0.7), 1.4)
			Util.cheek(self, Vector2(-r * 0.46, r * 0.15), r * 0.11)
			Util.cheek(self, Vector2(r * 0.46, r * 0.15), r * 0.11)
		"pumpkin":
			# 돌진 호박: 돌진하기 전에 눈썹이 사나워진다
			var angry := charge_state >= 1
			draw_rect(Rect2(-r * 0.7, r * 0.8, r * 0.4, r * 0.3), dark)
			draw_rect(Rect2(r * 0.3, r * 0.8, r * 0.4, r * 0.3), dark)
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.1), r * 1.15, r * 0.95, 22), c)
			for lobe in [0.62, 0.22]:
				var ring := Util.ellipse(Vector2(0, r * 0.1), r * lobe * 1.15, r * 0.95, 18)
				ring.append(ring[0])
				draw_polyline(ring, dark, 1.4)
			draw_colored_polygon(Util.ellipse(Vector2(-r * 0.5, -r * 0.5), r * 0.3, r * 0.15, 10), Color(1, 1, 1, 0.4))
			draw_rect(Rect2(-r * 0.15, -r * 1.25, r * 0.3, r * 0.4), Color.WHITE if white else Color(0.32, 0.55, 0.25))
			draw_arc(Vector2(r * 0.2, -r * 1.2), r * 0.22, PI, TAU * 0.95, 8, Color(0.32, 0.55, 0.25), 2.0)
			Util.eye(self, Vector2(-r * 0.42, -r * 0.02), r * 0.28, Vector2(0.4, 0.0) if angry else Vector2.ZERO, Color(0.55, 0.05, 0.05) if angry else Color(0.1, 0.1, 0.2))
			Util.eye(self, Vector2(r * 0.42, -r * 0.02), r * 0.28, Vector2(0.4, 0.0) if angry else Vector2.ZERO, Color(0.55, 0.05, 0.05) if angry else Color(0.1, 0.1, 0.2))
			if angry:
				draw_line(Vector2(-r * 0.75, -r * 0.42), Vector2(-r * 0.15, -r * 0.24), Color(0.25, 0.08, 0.05), 3.0)
				draw_line(Vector2(r * 0.75, -r * 0.42), Vector2(r * 0.15, -r * 0.24), Color(0.25, 0.08, 0.05), 3.0)
				draw_polyline(PackedVector2Array([Vector2(-r * 0.4, r * 0.55), Vector2(-r * 0.2, r * 0.4), Vector2(0, r * 0.55), Vector2(r * 0.2, r * 0.4), Vector2(r * 0.4, r * 0.55)]), Color(0.25, 0.08, 0.05), 2.0)
			else:
				draw_arc(Vector2(0, r * 0.3), r * 0.25, 0.25, PI - 0.25, 8, dark, 1.6)
			Util.cheek(self, Vector2(-r * 0.78, r * 0.3), r * 0.17)
			Util.cheek(self, Vector2(r * 0.78, r * 0.3), r * 0.17)
		"jellyking":
			var pts := Util.blob(Vector2(0, r * 0.15), r * 1.1, r * 1.0, 26)
			draw_colored_polygon(pts, c)
			for dx in [-0.75, -0.25, 0.3, 0.8]:
				draw_circle(Vector2(r * dx, r * 0.7), r * 0.2, c)
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.5), r * 0.85, r * 0.3, 16), light)
			Util.outline(self, pts, dark, 2.0)
			draw_colored_polygon(Util.ellipse(Vector2(-r * 0.5, -r * 0.55), r * 0.3, r * 0.14, 10), Color(1, 1, 1, 0.55))
			Util.eye(self, Vector2(-r * 0.4, -r * 0.05), r * 0.3, Vector2(0.3, 0.2))
			Util.eye(self, Vector2(r * 0.4, -r * 0.05), r * 0.3, Vector2(0.3, 0.2))
			draw_arc(Vector2(0, r * 0.22), r * 0.3, 0.2, PI - 0.2, 10, dark, 2.5)
			Util.cheek(self, Vector2(-r * 0.75, r * 0.15), r * 0.16)
			Util.cheek(self, Vector2(r * 0.75, r * 0.15), r * 0.16)
			var gold := Color.WHITE if white else Color(1.0, 0.82, 0.25)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 0.5, -r * 0.8), Vector2(-r * 0.5, -r * 1.3), Vector2(-r * 0.25, -r * 1.05), Vector2(0, -r * 1.45),
				Vector2(r * 0.25, -r * 1.05), Vector2(r * 0.5, -r * 1.3), Vector2(r * 0.5, -r * 0.8),
			]), gold)
			draw_circle(Vector2(0, -r * 1.0), r * 0.09, Color(1.0, 0.3, 0.4))
			draw_circle(Vector2(-r * 0.3, -r * 0.92), r * 0.06, Color(0.4, 0.7, 1.0))
			draw_circle(Vector2(r * 0.3, -r * 0.92), r * 0.06, Color(0.4, 0.7, 1.0))
		"core":
			var metal := Color.WHITE if white else Color(0.55, 0.58, 0.7)
			var metal_dark := Color.WHITE if white else Color(0.32, 0.34, 0.46)
			var glow := Color(1.0, 0.3, 0.4)
			# 선과 떠다니는 구슬
			for sx in [-1.0, 1.0]:
				draw_line(Vector2(sx * r * 0.5, -r * 0.85), Vector2(sx * r * 0.75, -r * 1.35), metal_dark, 3.0)
				draw_circle(Vector2(sx * r * 0.78, -r * 1.4), r * 0.12, glow)
				draw_circle(Vector2(sx * r * 1.3, -r * 0.15), r * 0.2, Color(0.75, 0.4, 1.0, 0.85))
				draw_circle(Vector2(sx * r * 1.2, r * 0.5), r * 0.14, Color(0.75, 0.4, 1.0, 0.85))
				draw_line(Vector2(sx * r * 0.4, r * 0.75), Vector2(sx * r * 0.7, r * 1.05), metal_dark, 3.0)
			draw_rect(Rect2(-r * 0.78, -r * 0.85, r * 1.56, r * 1.6), metal)
			draw_rect(Rect2(-r * 1.0, -r * 0.63, r * 2.0, r * 1.16), metal)
			for cx in [-0.78, 0.78]:
				draw_circle(Vector2(r * cx, -r * 0.63), r * 0.22, metal)
				draw_circle(Vector2(r * cx, r * 0.53), r * 0.22, metal)
			draw_rect(Rect2(-r * 0.82, -r * 0.6, r * 1.64, r * 1.05), Color.WHITE if white else Color(0.1, 0.06, 0.16))
			for ex in [-0.38, 0.38]:
				draw_circle(Vector2(r * ex, -r * 0.1), r * 0.27, glow)
				draw_circle(Vector2(r * ex, -r * 0.1), r * 0.15, Color(1.0, 0.9, 0.5))
			draw_line(Vector2(-r * 0.7, -r * 0.5), Vector2(-r * 0.15, -r * 0.3), Color(0.9, 0.2, 0.3), 4.0)
			draw_line(Vector2(r * 0.7, -r * 0.5), Vector2(r * 0.15, -r * 0.3), Color(0.9, 0.2, 0.3), 4.0)
			draw_polyline(PackedVector2Array([
				Vector2(-r * 0.55, r * 0.22), Vector2(-r * 0.33, r * 0.36), Vector2(-r * 0.11, r * 0.22), Vector2(r * 0.11, r * 0.36),
				Vector2(r * 0.33, r * 0.22), Vector2(r * 0.55, r * 0.36),
			]), Color(1.0, 0.5, 0.6), 2.5)
			draw_rect(Rect2(-r * 1.0, -r * 0.63, r * 2.0, r * 1.16), metal_dark, false, 2.5)
		"queenbee":
			# 여왕벌: 큰 날개와 왕관
			var wingq := Color(1, 1, 1, 0.75)
			_petal(Vector2(-r * 0.95, -r * 0.7), -0.5, r * 0.8, r * 1.05, wingq)
			_petal(Vector2(r * 0.95, -r * 0.7), 0.5, r * 0.8, r * 1.05, wingq)
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.25, r * 0.85), Vector2(r * 0.25, r * 0.85), Vector2(0, r * 1.4)]), dark)
			var body := Util.ellipse(Vector2(0, r * 0.05), r * 1.05, r * 0.98, 26)
			draw_colored_polygon(body, c)
			var band := Color.WHITE if white else Color(0.32, 0.2, 0.12)
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.55), r * 0.92, r * 0.13, 16), band)
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.82), r * 0.6, r * 0.1, 14), band)
			draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.2), r * 0.85, r * 0.55, 18), light)
			Util.outline(self, body, dark, 2.0)
			Util.eye(self, Vector2(-r * 0.36, -r * 0.1), r * 0.3, Vector2(0.2, 0.2))
			Util.eye(self, Vector2(r * 0.36, -r * 0.1), r * 0.3, Vector2(0.2, 0.2))
			draw_arc(Vector2(0, r * 0.15), r * 0.26, 0.2, PI - 0.2, 10, dark, 2.2)
			Util.cheek(self, Vector2(-r * 0.72, r * 0.15), r * 0.15)
			Util.cheek(self, Vector2(r * 0.72, r * 0.15), r * 0.15)
			for sx in [-1.0, 1.0]:
				draw_line(Vector2(sx * r * 0.3, -r * 0.85), Vector2(sx * r * 0.55, -r * 1.35), dark, 2.0)
				draw_circle(Vector2(sx * r * 0.58, -r * 1.4), r * 0.1, Color(1.0, 0.5, 0.45))
			var crown := Color.WHITE if white else Color(1.0, 0.95, 0.5)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 0.4, -r * 0.8), Vector2(-r * 0.4, -r * 1.2), Vector2(-r * 0.2, -r * 0.98), Vector2(0, -r * 1.3),
				Vector2(r * 0.2, -r * 0.98), Vector2(r * 0.4, -r * 1.2), Vector2(r * 0.4, -r * 0.8),
			]), crown)
			draw_circle(Vector2(0, -r * 0.95), r * 0.08, Color(1.0, 0.3, 0.45))
		"greentree":
			# 폭주 온실 나무: 커다란 나무 몸통에 얼굴. 화가 나면 눈이 붉어진다
			var bark := Color.WHITE if white else Color(0.55, 0.38, 0.24)
			var bark_d := Color.WHITE if white else Color(0.38, 0.25, 0.15)
			for sx in [-1.0, 1.0]:
				draw_line(Vector2(sx * r * 0.4, r * 0.75), Vector2(sx * r * 1.0, r * 1.0), bark_d, 5.0)
				draw_line(Vector2(sx * r * 0.55, r * 0.15), Vector2(sx * r * 1.15, -r * 0.3), bark, 6.0)
				draw_circle(Vector2(sx * r * 1.2, -r * 0.35), r * 0.2, Color.WHITE if white else Color(0.4, 0.75, 0.35))
				draw_circle(Vector2(sx * r * 1.32, -r * 0.5), r * 0.13, Color.WHITE if white else Color(0.55, 0.85, 0.4))
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 0.6, -r * 0.5), Vector2(r * 0.6, -r * 0.5), Vector2(r * 0.72, r * 0.5), Vector2(r * 0.95, r * 0.95),
				Vector2(-r * 0.95, r * 0.95), Vector2(-r * 0.72, r * 0.5),
			]), bark)
			for bx in [-0.35, 0.05, 0.42]:
				draw_line(Vector2(r * bx, -r * 0.4), Vector2(r * (bx + 0.05), r * 0.4), bark_d, 1.6)
			var leaf_d := Color.WHITE if white else Color(0.2, 0.55, 0.3)
			var leaf_m := Color.WHITE if white else Color(0.32, 0.7, 0.38)
			var leaf_l := Color.WHITE if white else Color(0.5, 0.85, 0.45)
			for cp in [Vector3(-0.85, -0.6, 0.62), Vector3(0.85, -0.6, 0.62), Vector3(0, -1.05, 0.78), Vector3(-0.4, -0.35, 0.62), Vector3(0.4, -0.35, 0.62)]:
				draw_circle(Vector2(cp.x, cp.y) * r, cp.z * r, leaf_d)
			for cp in [Vector3(-0.85, -0.66, 0.52), Vector3(0.85, -0.66, 0.52), Vector3(0, -1.12, 0.66), Vector3(-0.4, -0.42, 0.5), Vector3(0.4, -0.42, 0.5)]:
				draw_circle(Vector2(cp.x, cp.y) * r, cp.z * r, leaf_m)
			for cp in [Vector3(-0.95, -0.85, 0.16), Vector3(-0.15, -1.35, 0.18), Vector3(0.7, -1.0, 0.15), Vector3(0.2, -0.6, 0.14)]:
				draw_circle(Vector2(cp.x, cp.y) * r, cp.z * r, leaf_l)
			for fp in [Vector2(-0.7, -0.95), Vector2(0.5, -1.4), Vector2(0.95, -0.4), Vector2(-0.25, -0.75)]:
				draw_circle(fp * r, r * 0.11, Color(1.0, 0.6, 0.75))
				draw_circle(fp * r, r * 0.05, Color(1.0, 0.92, 0.5))
			var eye_c := Color(1.0, 0.2, 0.2) if rage else Color(0.1, 0.1, 0.2)
			Util.eye(self, Vector2(-r * 0.27, r * 0.0), r * 0.26, Vector2(0.2, 0.2), eye_c)
			Util.eye(self, Vector2(r * 0.27, r * 0.0), r * 0.26, Vector2(0.2, 0.2), eye_c)
			if rage:
				draw_line(Vector2(-r * 0.55, -r * 0.3), Vector2(-r * 0.08, -r * 0.14), Color(0.15, 0.06, 0.04), 4.0)
				draw_line(Vector2(r * 0.55, -r * 0.3), Vector2(r * 0.08, -r * 0.14), Color(0.15, 0.06, 0.04), 4.0)
				draw_polyline(PackedVector2Array([
					Vector2(-r * 0.3, r * 0.42), Vector2(-r * 0.15, r * 0.3), Vector2(0, r * 0.42), Vector2(r * 0.15, r * 0.3), Vector2(r * 0.3, r * 0.42),
				]), Color(0.15, 0.06, 0.04), 3.0)
			else:
				draw_arc(Vector2(0, r * 0.25), r * 0.22, 0.2, PI - 0.2, 10, Color(0.2, 0.1, 0.08), 3.0)
			Util.cheek(self, Vector2(-r * 0.5, r * 0.28), r * 0.13)
			Util.cheek(self, Vector2(r * 0.5, r * 0.28), r * 0.13)
		_:
			draw_circle(Vector2.ZERO, r, c)
			Util.eye(self, Vector2(-r * 0.3, -r * 0.2), r * 0.28)
			Util.eye(self, Vector2(r * 0.3, -r * 0.2), r * 0.28)

	_draw_status(r)
	if elite:
		draw_arc(Vector2.ZERO, r * 1.2, 0.0, TAU, 32, Color(1.0, 0.82, 0.25, 0.9), 2.5)
		draw_arc(Vector2.ZERO, r * 1.35, 0.0, TAU, 32, Color(1.0, 0.82, 0.25, 0.3), 5.0)


## 속성 상태 표시: 몸에 붙은 젤, 얼음 조각, 불꽃, 전기 불꽃, 정지 별
func _draw_status(r: float) -> void:
	if status.has("gel"):
		draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.8), r * 1.15, r * 0.4, 14), Color(0.5, 0.95, 0.4, 0.55))
		draw_circle(Vector2(-r * 0.7, -r * 0.3), r * 0.2, Color(0.5, 0.95, 0.4, 0.75))
		draw_circle(Vector2(r * 0.75, r * 0.1), r * 0.15, Color(0.5, 0.95, 0.4, 0.75))
	if status.has("cold"):
		draw_circle(Vector2.ZERO, r * 1.05, Color(0.55, 0.85, 1.0, 0.28))
		for a in [-2.2, -1.2, -0.3, 0.7]:
			var d := Vector2.from_angle(a) * r * 1.1
			draw_colored_polygon(PackedVector2Array([d + Vector2(0, -r * 0.35), d + Vector2(r * 0.16, 0), d + Vector2(0, r * 0.35), d + Vector2(-r * 0.16, 0)]), Color(0.75, 0.95, 1.0, 0.9))
	if status.has("heat"):
		draw_circle(Vector2.ZERO, r * 1.05, Color(1.0, 0.45, 0.15, 0.22))
		for fx in [-0.5, 0.0, 0.5]:
			var b := Vector2(r * fx, -r * 0.95)
			draw_colored_polygon(PackedVector2Array([b + Vector2(-r * 0.2, 0), b + Vector2(r * 0.2, 0), b + Vector2(0, -r * 0.6)]), Color(1.0, 0.6, 0.2, 0.9))
	if status.has("shock"):
		var zz := PackedVector2Array([
			Vector2(-r * 0.2, -r * 1.7), Vector2(r * 0.15, -r * 1.35), Vector2(-r * 0.1, -r * 1.25), Vector2(r * 0.25, -r * 0.9),
		])
		draw_polyline(zz, Color(1.0, 0.95, 0.3), 2.5)
	if stun > 0.0:
		for i in 3:
			var a := TAU * float(i) / 3.0
			draw_circle(Vector2(cos(a) * r * 0.7, -r * 1.5 + sin(a) * r * 0.2), r * 0.13, Color(1.0, 0.95, 0.4))


## 잎사귀나 꽃잎 같은 기울어진 타원 하나
func _petal(center: Vector2, ang: float, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry).rotated(ang))
	draw_colored_polygon(pts, col)
