class_name Projectile
extends Node2D
## 무기가 만들어내는 오브젝트: 젤, 볼트, 냉각 캔, 얼음 날, 위성 구슬, 열판

var kind := "bolt"
var vel := Vector2.ZERO
var damage := 1.0
var pierce := 1
var life := 1.0
var age := 0.0
var radius := 6.0
var color := Color(0.5, 0.95, 0.4)
var weapon: Weapon = null
var hit_ids := {}          # 적 id -> 다시 맞출 수 있는 시각 (INF 면 한 번만)
var dead := false
var gravity := 0.0
var spin := 0.0            # 초당 회전 각도
var curve := 0.0           # 초당 진행 방향 회전 각도
var delay := 0.0           # 이 시간이 지나야 피해를 줌 (열판 낙하 시간)
var hit_interval := 0.0    # 0보다 크면 같은 적을 이 간격으로 다시 공격
var kb := 1.0
var managed := false       # true 면 무기가 위치를 직접 지정 (위성 구슬)
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
	if p_kind == "bolt" or p_kind == "knife":
		pr.rotation = p_vel.angle()
	pr.z_index = 3 if p_kind != "zone" else -2
	return pr


func _draw() -> void:
	match kind:
		"bolt":
			_draw_gel()
		"knife":
			_draw_bolt()
		"axe":
			_draw_canister()
		"scythe":
			_draw_ice_blade()
		"book":
			_draw_orb()
		"zone":
			_draw_hotplate()


## 젤 덩어리: 눈이 달린 말랑한 방울
func _draw_gel() -> void:
	var r := radius
	var col := color
	draw_circle(Vector2.ZERO, r * 1.9, Color(col.r, col.g, col.b, 0.16))
	for i in 3:
		draw_circle(Vector2(-r * (1.3 + i * 0.95), 0), r * (0.62 - i * 0.16), Color(col.r, col.g, col.b, 0.5 - i * 0.14))
	draw_circle(Vector2.ZERO, r, col)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 16, col.darkened(0.4), 1.5)
	draw_circle(Vector2(-r * 0.25, -r * 0.4), r * 0.3, Color(1, 1, 1, 0.85))
	draw_circle(Vector2(r * 0.32, -r * 0.3), r * 0.15, Color(0.08, 0.1, 0.16))
	draw_circle(Vector2(r * 0.32, r * 0.3), r * 0.15, Color(0.08, 0.1, 0.16))
	if evolved:
		draw_arc(Vector2.ZERO, r * 1.35, 0.0, TAU, 20, Color(1.0, 0.95, 0.6, 0.6), 1.5)


## 전기 볼트: 육각 볼트 머리와 튀는 전기
func _draw_bolt() -> void:
	var col := color
	draw_circle(Vector2(6, 0), 9.0, Color(col.r, col.g, col.b, 0.22))
	draw_polyline(PackedVector2Array([Vector2(-16, 2), Vector2(-12, -3), Vector2(-9, 2), Vector2(-5, -2)]), Color(col.r, col.g, col.b, 0.85), 2.0)
	draw_rect(Rect2(-6, -1.8, 10, 3.6), Color(0.72, 0.76, 0.85))
	for i in 3:
		draw_line(Vector2(-4 + i * 3.0, -2.4), Vector2(-3 + i * 3.0, 2.4), Color(0.45, 0.5, 0.6), 1.0)
	var hex := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0
		hex.append(Vector2(7 + cos(a) * 5.0, sin(a) * 5.0))
	draw_colored_polygon(hex, col)
	Util.outline(self, hex, col.darkened(0.45), 1.2)
	draw_circle(Vector2(7, 0), 2.0, Color(1, 1, 1, 0.9))


## 냉각 캔: 빙글빙글 도는 소화기 모양 통
func _draw_canister() -> void:
	var k := radius / 14.0
	var col := color
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	draw_circle(Vector2.ZERO, 22.0, Color(col.r, col.g, col.b, 0.18))
	draw_rect(Rect2(-6, -11, 12, 23), Color(0.92, 0.96, 1.0))
	draw_rect(Rect2(-6, -3, 12, 8), col)
	draw_rect(Rect2(-4, -16, 8, 5), Color(0.5, 0.55, 0.68))
	draw_rect(Rect2(-1.5, -20, 7, 4), Color(0.4, 0.45, 0.58))
	draw_rect(Rect2(-4.5, -9, 2, 17), Color(1, 1, 1, 0.65))
	draw_rect(Rect2(-6, -11, 12, 23), Color(0.2, 0.3, 0.5), false, 1.5)
	draw_circle(Vector2(5, -21), 3.0, Color(1, 1, 1, 0.7))
	draw_circle(Vector2(9, -18), 2.0, Color(1, 1, 1, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 얼음 날: 사방으로 도는 초승달 모양 얼음
func _draw_ice_blade() -> void:
	var r := radius
	var col := color
	draw_arc(Vector2.ZERO, r * 0.8, -0.4, 2.6, 18, Color(col.r, col.g, col.b, 0.3), r * 0.7)
	draw_arc(Vector2.ZERO, r * 0.8, -0.4, 2.6, 18, col, 3.5)
	draw_arc(Vector2.ZERO, r * 0.8, -0.2, 2.2, 18, Color(1, 1, 1, 0.95), 1.5)
	for a in [0.3, 1.2, 2.0]:
		var d := Vector2.from_angle(a) * r * 0.95
		draw_colored_polygon(PackedVector2Array([d + Vector2(0, -4), d + Vector2(2.5, 0), d + Vector2(0, 4), d + Vector2(-2.5, 0)]), Color(1, 1, 1, 0.9))


## 위성 구슬: 얼굴이 있는 플라즈마 구슬
func _draw_orb() -> void:
	var r := radius
	var col := color
	draw_circle(Vector2.ZERO, r * 1.9, Color(col.r, col.g, col.b, 0.2))
	draw_arc(Vector2.ZERO, r * 1.45, 0.4, 2.3, 10, Color(1, 1, 1, 0.55), 1.5)
	if evolved:
		draw_arc(Vector2.ZERO, r * 1.45, 3.6, 5.4, 10, Color(1.0, 0.95, 0.6, 0.7), 1.5)
	draw_circle(Vector2.ZERO, r, col)
	draw_circle(Vector2.ZERO, r * 0.7, col.lightened(0.35))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 18, col.darkened(0.35), 1.5)
	draw_circle(Vector2(-r * 0.3, -r * 0.45), r * 0.25, Color(1, 1, 1, 0.8))
	draw_circle(Vector2(-r * 0.28, -r * 0.05), r * 0.14, Color(0.1, 0.05, 0.2))
	draw_circle(Vector2(r * 0.28, -r * 0.05), r * 0.14, Color(0.1, 0.05, 0.2))
	draw_arc(Vector2(0, r * 0.2), r * 0.25, 0.3, PI - 0.3, 6, Color(0.1, 0.05, 0.2), 1.3)


## 핫플레이트: 달궈진 바닥. 처음에는 떨어지는 열판과 착지 예고선이 보인다
func _draw_hotplate() -> void:
	var r := radius
	var col := color
	if age < delay:
		var t := age / delay
		draw_arc(Vector2.ZERO, r * t, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.7), 2.0)
		draw_rect(Rect2(-9, -200.0 * (1.0 - t) - 9, 18, 18), col.darkened(0.3))
		draw_rect(Rect2(-9, -200.0 * (1.0 - t) - 9, 18, 18), col, false, 2.0)
		return
	var fade_t := clampf(life / 0.4, 0.0, 1.0)
	var pulse := 0.9 + 0.1 * sin(age * 9.0)
	draw_colored_polygon(Util.ellipse(Vector2.ZERO, r * pulse, r * pulse * 0.78, 28), Color(col.r, col.g, col.b, 0.28 * fade_t))
	for i in 3:
		var rr := r * pulse * (0.35 + 0.3 * i)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 28, Color(1.0, 0.85, 0.5, (0.8 - 0.15 * i) * fade_t), 2.0)
	draw_arc(Vector2.ZERO, r * pulse, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.85 * fade_t), 2.5)
	for i in 8:
		var a := float(i) / 8.0 * TAU + age * 0.4
		var d := r * (0.2 + 0.65 * fmod(float(i) * 0.37, 1.0))
		var h := 9.0 + 7.0 * sin(age * 8.0 + float(i) * 2.1)
		var bp := Vector2(cos(a) * d, sin(a) * d * 0.78)
		draw_colored_polygon(PackedVector2Array([bp + Vector2(-3.5, 0), bp + Vector2(3.5, 0), bp + Vector2(0, -h)]), Color(1.0, 0.9, 0.6, 0.7 * fade_t))
