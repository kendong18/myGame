class_name Projectile
extends Node2D
## 무기가 만들어내는 오브젝트: 마법탄, 단검, 도끼, 낫, 책, 성수 지대

var kind := "bolt"
var vel := Vector2.ZERO
var damage := 1.0
var pierce := 1
var life := 1.0
var age := 0.0
var radius := 6.0
var color := Color.WHITE
var weapon: Weapon = null
var hit_ids := {}          # 적 id -> 다시 맞출 수 있는 시각 (INF 면 한 번만)
var dead := false
var gravity := 0.0
var spin := 0.0            # 초당 회전 각도
var curve := 0.0           # 초당 진행 방향 회전 각도
var delay := 0.0           # 이 시간이 지나야 피해를 줌 (성수 낙하 시간)
var hit_interval := 0.0    # 0보다 크면 같은 적을 이 간격으로 다시 공격
var kb := 1.0
var managed := false       # true 면 무기가 위치를 직접 지정 (성서)
var evolved := false
var fade := 1.0


static func make(p_kind: String, pos: Vector2, p_vel: Vector2, dmg: float, p_pierce: int, p_life: float, p_radius: float, p_weapon: Weapon) -> Projectile:
	var pr := Projectile.new()
	pr.kind = p_kind
	pr.position = pos
	pr.vel = p_vel
	pr.damage = dmg
	pr.pierce = p_pierce
	pr.life = p_life
	pr.radius = p_radius
	pr.weapon = p_weapon
	pr.color = Color(0.48, 0.85, 1.0)
	if p_kind == "bolt" or p_kind == "knife":
		pr.rotation = p_vel.angle()
	pr.z_index = 3 if p_kind != "zone" else -2
	return pr


func _draw() -> void:
	match kind:
		"bolt":
			_draw_bolt()
		"knife":
			_draw_knife()
		"axe":
			_draw_axe()
		"scythe":
			_draw_scythe()
		"book":
			_draw_book()
		"zone":
			_draw_zone()


func _draw_bolt() -> void:
	var r := radius
	draw_circle(Vector2.ZERO, r * 1.9, Color(color.r, color.g, color.b, 0.18))
	draw_circle(Vector2.ZERO, r * 1.3, Color(color.r, color.g, color.b, 0.4))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 3.2, 0), Vector2(-r * 0.2, -r * 0.8), Vector2(-r * 0.2, r * 0.8),
	]), Color(color.r, color.g, color.b, 0.5))
	draw_circle(Vector2.ZERO, r, color)
	draw_circle(Vector2.ZERO, r * 0.5, Color(1, 1, 1, 0.95))


func _draw_knife() -> void:
	draw_rect(Rect2(-13, -2, 6, 4), Color(0.45, 0.28, 0.15))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -3), Vector2(6, -3), Vector2(14, 0), Vector2(6, 3), Vector2(-8, 3),
	]), Color(0.85, 0.9, 1.0))
	draw_line(Vector2(-7, -1), Vector2(10, -1), Color(1, 1, 1, 0.9), 1.0)
	draw_polyline(PackedVector2Array([Vector2(-8, -3), Vector2(6, -3), Vector2(14, 0), Vector2(6, 3), Vector2(-8, 3), Vector2(-8, -3)]), Color(0.1, 0.1, 0.2, 0.8), 1.0)


func _draw_axe() -> void:
	var k := radius / 14.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	draw_line(Vector2(-12, 12), Vector2(10, -10), Color(0.5, 0.32, 0.16), 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -16), Vector2(16, -14), Vector2(14, 2), Vector2(4, -4),
	]), Color(0.78, 0.8, 0.86))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -16), Vector2(16, -14), Vector2(13, -10), Vector2(3, -11),
	]), Color(1, 1, 1, 0.8))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_scythe() -> void:
	var r := radius
	draw_arc(Vector2.ZERO, r * 0.8, -0.4, 2.6, 18, Color(0.25, 0.05, 0.35, 0.5), r * 0.6)
	draw_arc(Vector2.ZERO, r * 0.8, -0.4, 2.6, 18, Color(0.85, 0.5, 1.0), 3.5)
	draw_arc(Vector2.ZERO, r * 0.8, -0.2, 2.2, 18, Color(1, 1, 1, 0.9), 1.5)
	draw_circle(Vector2.ZERO, 3, Color(0.5, 0.3, 0.2))


func _draw_book() -> void:
	var r := radius
	var glow := Color(1.0, 0.9, 0.5, 0.25) if evolved else Color(0.6, 0.8, 1.0, 0.22)
	draw_circle(Vector2.ZERO, r * 1.6, glow)
	var cover := Color(0.75, 0.2, 0.25) if evolved else Color(0.2, 0.4, 0.75)
	draw_rect(Rect2(-r * 0.85, -r * 0.7, r * 1.7, r * 1.4), cover)
	draw_rect(Rect2(-r * 0.7, -r * 0.55, r * 1.4, r * 1.1), Color(0.95, 0.92, 0.8))
	draw_line(Vector2(0, -r * 0.55), Vector2(0, r * 0.55), Color(0.4, 0.3, 0.2), 1.5)
	draw_rect(Rect2(-r * 0.85, -r * 0.7, r * 1.7, r * 1.4), Color(0.05, 0.05, 0.15), false, 1.5)
	for i in 3:
		draw_line(Vector2(-r * 0.5, -r * 0.3 + i * r * 0.3), Vector2(-r * 0.1, -r * 0.3 + i * r * 0.3), Color(0.4, 0.35, 0.3), 1.0)


func _draw_zone() -> void:
	var r := radius
	var base := Color(1.0, 0.8, 0.3) if evolved else Color(0.35, 0.65, 1.0)
	var flame := Color(1.0, 0.95, 0.6) if evolved else Color(0.75, 0.95, 1.0)
	if age < delay:
		# 떨어지는 물병과 착지 예고
		var t := age / delay
		draw_arc(Vector2.ZERO, r * t, 0.0, TAU, 32, Color(base.r, base.g, base.b, 0.7), 2.0)
		draw_circle(Vector2(0, -200.0 * (1.0 - t)), 6.0, base)
		return
	var fade_t := clampf((life) / 0.4, 0.0, 1.0)
	var pulse := 0.85 + 0.15 * sin(age * 9.0)
	draw_colored_polygon(Util.ellipse(Vector2.ZERO, r * pulse, r * pulse * 0.78, 28), Color(base.r, base.g, base.b, 0.30 * fade_t))
	draw_arc(Vector2.ZERO, r * pulse, 0.0, TAU, 32, Color(base.r, base.g, base.b, 0.8 * fade_t), 2.0)
	for i in 9:
		var a := float(i) / 9.0 * TAU + age * 0.7
		var d := r * (0.25 + 0.6 * fmod(float(i) * 0.37, 1.0))
		var h := 10.0 + 8.0 * sin(age * 8.0 + float(i) * 2.1)
		var bp := Vector2(cos(a) * d, sin(a) * d * 0.78)
		draw_colored_polygon(PackedVector2Array([
			bp + Vector2(-4, 0), bp + Vector2(4, 0), bp + Vector2(0, -h),
		]), Color(flame.r, flame.g, flame.b, 0.75 * fade_t))
