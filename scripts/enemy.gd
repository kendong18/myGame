class_name Enemy
extends Node2D
## 적 한 마리. 이동/충돌은 Main 이 일괄 처리한다.

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
