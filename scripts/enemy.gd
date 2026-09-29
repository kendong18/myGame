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
var boss := ""                 # 보스 종류 ("vampire", "demon"), 일반 적은 빈 문자열
var ranged := false
var shoot_t := 0.0
var skill_t := 0.0             # 보스 패턴 타이머
var skill2_t := 0.0
var spin := 0.0


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
		max_hp *= 10.0
		hp = max_hp
		radius *= 1.5
		damage *= 1.3
		xp *= 5
		kb_resist = minf(0.9, kb_resist + 0.5)
		speed *= 0.95


func _draw() -> void:
	var r := radius
	var c := Color.WHITE if flash > 0.0 else color
	var dark := c if flash > 0.0 else c.darkened(0.3)
	draw_colored_polygon(Util.ellipse(Vector2(0, r * 0.9), r * 0.95, r * 0.35), Color(0, 0, 0, 0.35))

	match kind:
		"bat":
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.3, -2), Vector2(-r * 1.7, -r), Vector2(-r * 1.3, r * 0.5)]), dark)
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.3, -2), Vector2(r * 1.7, -r), Vector2(r * 1.3, r * 0.5)]), dark)
			draw_circle(Vector2.ZERO, r * 0.8, c)
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.6, -r * 0.5), Vector2(-r * 0.3, -r * 1.2), Vector2(-r * 0.05, -r * 0.6)]), c)
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.6, -r * 0.5), Vector2(r * 0.3, -r * 1.2), Vector2(r * 0.05, -r * 0.6)]), c)
			draw_circle(Vector2(-r * 0.3, -r * 0.1), 1.8, Color(1, 0.2, 0.2))
			draw_circle(Vector2(r * 0.3, -r * 0.1), 1.8, Color(1, 0.2, 0.2))
		"zombie":
			draw_rect(Rect2(-r * 0.8, -r * 0.1, r * 1.6, r * 1.0), Color.WHITE if flash > 0.0 else Color(0.38, 0.33, 0.55))
			draw_circle(Vector2(0, -r * 0.5), r * 0.75, c)
			draw_rect(Rect2(r * 0.4, -r * 0.1, r * 0.9, 3), c)   # 앞으로 뻗은 팔
			draw_rect(Rect2(-r * 0.5, -r * 0.6, 3, 3), Color(1, 0.2, 0.2))
			draw_rect(Rect2(r * 0.15, -r * 0.6, 3, 3), Color(1, 0.2, 0.2))
			draw_rect(Rect2(-r * 0.3, -r * 0.15, r * 0.6, 2), dark)
		"skeleton":
			draw_rect(Rect2(-r * 0.5, -r * 0.1, r * 1.0, r * 1.0), dark)
			draw_rect(Rect2(-r * 0.4, 0, r * 0.8, 2), c)
			draw_rect(Rect2(-r * 0.4, 4, r * 0.8, 2), c)
			draw_circle(Vector2(0, -r * 0.5), r * 0.75, c)
			draw_rect(Rect2(-r * 0.5, -r * 0.7, 4, 4), Color(0.1, 0.05, 0.05))
			draw_rect(Rect2(r * 0.1, -r * 0.7, 4, 4), Color(0.1, 0.05, 0.05))
			draw_rect(Rect2(-r * 0.3, -r * 0.15, r * 0.6, 2), Color(0.1, 0.05, 0.05))
		"ghost":
			var gc := Color(c.r, c.g, c.b, 0.85)
			draw_circle(Vector2(0, -r * 0.2), r * 0.9, gc)
			draw_rect(Rect2(-r * 0.9, -r * 0.2, r * 1.8, r * 1.1), gc)
			for i in 3:
				draw_circle(Vector2(-r * 0.6 + i * r * 0.6, r * 0.9), r * 0.3, gc)
			draw_circle(Vector2(-r * 0.3, -r * 0.3), 2.2, Color(0.1, 0.1, 0.3))
			draw_circle(Vector2(r * 0.3, -r * 0.3), 2.2, Color(0.1, 0.1, 0.3))
		"mage":
			# 보라색 로브를 입은 해골 마법사
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.9, r * 0.9), Vector2(r * 0.9, r * 0.9), Vector2(r * 0.5, -r * 0.2), Vector2(-r * 0.5, -r * 0.2)]), Color.WHITE if flash > 0.0 else Color(0.35, 0.16, 0.55))
			draw_circle(Vector2(0, -r * 0.55), r * 0.72, Color.WHITE if flash > 0.0 else Color(0.9, 0.88, 0.8))
			draw_arc(Vector2(0, -r * 0.55), r * 0.85, PI, TAU, 14, Color.WHITE if flash > 0.0 else Color(0.35, 0.16, 0.55), 5.0)
			draw_rect(Rect2(-r * 0.45, -r * 0.7, 4, 4), Color(0.4, 0.9, 1.0))
			draw_rect(Rect2(r * 0.1, -r * 0.7, 4, 4), Color(0.4, 0.9, 1.0))
			draw_line(Vector2(r * 0.9, r * 0.8), Vector2(r * 0.9, -r * 0.8), Color(0.5, 0.35, 0.2), 2.0)
			draw_circle(Vector2(r * 0.9, -r * 0.95), 3.0, Color(0.4, 0.95, 1.0))
		"werewolf":
			draw_circle(Vector2(0, r * 0.1), r * 0.95, c)
			draw_circle(Vector2(r * 0.35, -r * 0.4), r * 0.6, c)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -r * 0.7), Vector2(-r * 0.2, -r * 1.4), Vector2(r * 0.3, -r * 0.9)]), dark)
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.5, -r * 0.8), Vector2(r * 0.9, -r * 1.4), Vector2(r * 1.0, -r * 0.6)]), dark)
			draw_circle(Vector2(r * 0.6, -r * 0.45), 2.2, Color(1, 0.9, 0.2))
			draw_rect(Rect2(r * 0.7, -r * 0.15, r * 0.4, 2), Color.WHITE)
		"golem":
			draw_rect(Rect2(-r, -r * 0.6, r * 2.0, r * 1.6), c)
			draw_rect(Rect2(-r * 0.7, -r * 1.1, r * 1.4, r * 0.8), dark)
			draw_rect(Rect2(-r * 1.25, -r * 0.3, r * 0.5, r * 1.1), dark)
			draw_rect(Rect2(r * 0.75, -r * 0.3, r * 0.5, r * 1.1), dark)
			draw_rect(Rect2(-r * 0.45, -r * 0.8, 5, 4), Color(1, 0.8, 0.2))
			draw_rect(Rect2(r * 0.15, -r * 0.8, 5, 4), Color(1, 0.8, 0.2))
		"vampire":
			var cloak := Color.WHITE if flash > 0.0 else Color(0.35, 0.05, 0.12)
			var skin := Color.WHITE if flash > 0.0 else Color(0.9, 0.86, 0.92)
			# 망토
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 1.5, r * 0.95), Vector2(r * 1.5, r * 0.95), Vector2(r * 0.7, -r * 0.5), Vector2(-r * 0.7, -r * 0.5),
			]), cloak)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 0.6, r * 0.9), Vector2(r * 0.6, r * 0.9), Vector2(r * 0.4, -r * 0.4), Vector2(-r * 0.4, -r * 0.4),
			]), Color.WHITE if flash > 0.0 else Color(0.1, 0.03, 0.08))
			# 깃
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 0.75, -r * 0.5), Vector2(-r * 0.4, -r * 1.25), Vector2(-r * 0.1, -r * 0.5),
			]), cloak)
			draw_colored_polygon(PackedVector2Array([
				Vector2(r * 0.75, -r * 0.5), Vector2(r * 0.4, -r * 1.25), Vector2(r * 0.1, -r * 0.5),
			]), cloak)
			draw_circle(Vector2(0, -r * 0.6), r * 0.5, skin)
			draw_arc(Vector2(0, -r * 0.7), r * 0.5, PI, TAU, 14, Color.WHITE if flash > 0.0 else Color(0.08, 0.06, 0.1), 5.0)
			draw_circle(Vector2(-r * 0.18, -r * 0.6), 2.4, Color(1, 0.15, 0.15))
			draw_circle(Vector2(r * 0.18, -r * 0.6), 2.4, Color(1, 0.15, 0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.15, -r * 0.4), Vector2(-r * 0.05, -r * 0.4), Vector2(-r * 0.1, -r * 0.25)]), Color.WHITE)
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.05, -r * 0.4), Vector2(r * 0.15, -r * 0.4), Vector2(r * 0.1, -r * 0.25)]), Color.WHITE)
		"demon":
			var body := Color.WHITE if flash > 0.0 else Color(0.62, 0.1, 0.16)
			var wing := Color.WHITE if flash > 0.0 else Color(0.3, 0.06, 0.16)
			# 날개
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 0.5, -r * 0.2), Vector2(-r * 2.1, -r * 1.2), Vector2(-r * 1.7, -r * 0.1), Vector2(-r * 1.9, r * 0.6), Vector2(-r * 0.5, r * 0.5),
			]), wing)
			draw_colored_polygon(PackedVector2Array([
				Vector2(r * 0.5, -r * 0.2), Vector2(r * 2.1, -r * 1.2), Vector2(r * 1.7, -r * 0.1), Vector2(r * 1.9, r * 0.6), Vector2(r * 0.5, r * 0.5),
			]), wing)
			draw_circle(Vector2(0, r * 0.15), r * 0.95, body)
			draw_circle(Vector2(0, -r * 0.6), r * 0.62, body)
			# 뿔
			var horn := Color.WHITE if flash > 0.0 else Color(0.92, 0.85, 0.65)
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.5, -r * 0.95), Vector2(-r * 0.85, -r * 1.7), Vector2(-r * 0.15, -r * 1.05)]), horn)
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.5, -r * 0.95), Vector2(r * 0.85, -r * 1.7), Vector2(r * 0.15, -r * 1.05)]), horn)
			draw_circle(Vector2(-r * 0.22, -r * 0.62), 3.2, Color(1, 0.9, 0.2))
			draw_circle(Vector2(r * 0.22, -r * 0.62), 3.2, Color(1, 0.9, 0.2))
			draw_rect(Rect2(-r * 0.3, -r * 0.3, r * 0.6, 3), Color(0.15, 0.02, 0.04))
		_:
			draw_circle(Vector2.ZERO, r, c)
			draw_circle(Vector2(-r * 0.3, -r * 0.2), 2, Color.BLACK)
			draw_circle(Vector2(r * 0.3, -r * 0.2), 2, Color.BLACK)

	if elite:
		draw_arc(Vector2.ZERO, r * 1.2, 0.0, TAU, 32, Color(1.0, 0.82, 0.25, 0.9), 2.5)
		draw_arc(Vector2.ZERO, r * 1.35, 0.0, TAU, 32, Color(1.0, 0.82, 0.25, 0.3), 5.0)
