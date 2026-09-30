class_name Hazard
extends Node2D
## 바닥에 생기는 위험 지대와 지형.
## thorns: 잠시 예고한 뒤 가시가 솟는다 / spore: 한동안 머무는 포자 구름 / puddle: 물웅덩이 (안의 적은 전기에 약하다)

const THORN_STAY := 0.45      # 가시가 솟은 뒤 남아 있는 시간
const PUDDLE_SQUASH := 0.75   # 물웅덩이는 세로로 납작한 타원

var kind := "thorns"
var radius := 55.0
var delay := 1.2              # thorns: 예고 시간
var duration := 4.0           # spore / puddle: 지속 시간
var damage := 10.0
var source := ""
var age := 0.0
var dead := false
var just_fired := false       # thorns: 이번 프레임에 솟았다 (Main 이 피해를 판정하고 되돌린다)
var tick := 0.0               # spore: 다음 피해까지 남은 시간
var seed_v := 0.0


static func thorns(pos: Vector2, r: float, wait: float, dmg: float, src: String) -> Hazard:
	var h := Hazard.new()
	h.kind = "thorns"
	h.position = pos
	h.radius = r
	h.delay = wait
	h.damage = dmg
	h.source = src
	return h


static func spore(pos: Vector2, r: float, dur: float, dmg: float, src: String) -> Hazard:
	var h := Hazard.new()
	h.kind = "spore"
	h.position = pos
	h.radius = r
	h.duration = dur
	h.damage = dmg
	h.source = src
	return h


static func puddle(pos: Vector2, r: float, dur: float) -> Hazard:
	var h := Hazard.new()
	h.kind = "puddle"
	h.position = pos
	h.radius = r
	h.duration = dur
	return h


func _ready() -> void:
	seed_v = randf() * TAU
	z_index = -5 if kind != "thorns" else 1


## 시간을 진행시킨다. 사라져야 하면 dead 가 true 가 된다.
func step(delta: float) -> void:
	age += delta
	match kind:
		"thorns":
			if not just_fired and age >= delay and age - delta < delay:
				just_fired = true
			if age >= delay + THORN_STAY:
				dead = true
		"spore":
			tick -= delta
			if age >= duration:
				dead = true
		"puddle":
			if age >= duration:
				dead = true
	queue_redraw()


func contains(p: Vector2, extra: float = 0.0) -> bool:
	var d := p - position
	if kind == "puddle":
		var rx := radius + extra
		var ry := radius * PUDDLE_SQUASH + extra
		return (d.x * d.x) / (rx * rx) + (d.y * d.y) / (ry * ry) < 1.0
	return d.length_squared() < (radius + extra) * (radius + extra)


func _draw() -> void:
	match kind:
		"thorns":
			_draw_thorns()
		"spore":
			_draw_spore()
		"puddle":
			_draw_puddle()


func _draw_thorns() -> void:
	if age < delay:
		# 예고: 점점 진해지는 경고 원과 조금씩 올라오는 싹
		var t := clampf(age / delay, 0.0, 1.0)
		var blink := 0.75 + 0.25 * sin(age * 18.0)
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.75, 0.2, (0.12 + 0.22 * t) * blink))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.85, 0.3, 0.55 + 0.4 * t), 3.0)
		draw_arc(Vector2.ZERO, radius * t, 0.0, TAU, 32, Color(1.0, 0.6, 0.2, 0.7), 2.0)
		if t > 0.55:
			var grow := (t - 0.55) / 0.45
			for i in 8:
				var a := TAU * float(i) / 8.0 + seed_v
				var base := Vector2.from_angle(a) * radius * 0.6
				_spike(base, a, radius * 0.16 * grow, Color(0.4, 0.75, 0.35, 0.8))
	else:
		# 솟아오른 가시
		var t := clampf((age - delay) / THORN_STAY, 0.0, 1.0)
		var a := 1.0 - t * t
		var rise := minf(1.0, (age - delay) / 0.08)
		draw_circle(Vector2.ZERO, radius, Color(0.35, 0.65, 0.3, 0.25 * a))
		for ring in 2:
			var n := 9 if ring == 0 else 5
			var rr := radius * (0.72 if ring == 0 else 0.34)
			for i in n:
				var ang := TAU * float(i) / float(n) + seed_v + float(ring) * 0.4
				_spike(Vector2.from_angle(ang) * rr, ang, radius * 0.42 * rise, Color(0.3, 0.7, 0.35, a))
		_spike(Vector2.ZERO, seed_v, radius * 0.5 * rise, Color(0.35, 0.8, 0.4, a))


## 뾰족한 가시 하나: 바닥에서 위로 솟은 모양 (끝이 분홍색이라 귀엽게 보인다)
func _spike(base: Vector2, _ang: float, h: float, col: Color) -> void:
	var w := maxf(2.0, h * 0.28)
	var tip := base + Vector2(0, -h)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(w, 0), tip]), col)
	draw_circle(tip, maxf(1.2, w * 0.4), Color(1.0, 0.6, 0.75, col.a))


func _draw_spore() -> void:
	var left := duration - age
	var fade := clampf(left / 0.8, 0.0, 1.0) * clampf(age / 0.25, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.75, 0.35, 0.7, 0.16 * fade))
	for i in 7:
		var a := seed_v + TAU * float(i) / 7.0 + age * 0.5
		var d := radius * (0.35 + 0.4 * fmod(float(i) * 0.37, 1.0))
		var p := Vector2.from_angle(a) * d + Vector2(0, sin(age * 2.0 + float(i)) * 4.0)
		draw_circle(p, radius * 0.3, Color(0.85, 0.45, 0.8, 0.2 * fade))
		draw_circle(p + Vector2(-2, -2), radius * 0.1, Color(1.0, 0.8, 0.95, 0.3 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(0.95, 0.55, 0.85, 0.5 * fade), 2.0)
	for i in 5:
		var a := seed_v * 2.0 + TAU * float(i) / 5.0
		var rise := fmod(age * 0.6 + float(i) * 0.2, 1.0)
		var sp := Vector2.from_angle(a) * radius * 0.6 + Vector2(0, -rise * radius * 0.9)
		draw_circle(sp, 2.0, Color(1.0, 0.9, 1.0, (1.0 - rise) * 0.8 * fade))


func _draw_puddle() -> void:
	var left := duration - age
	var fade := clampf(left / 1.0, 0.0, 1.0) * clampf(age / 0.4, 0.0, 1.0)
	var rx := radius
	var ry := radius * PUDDLE_SQUASH
	draw_colored_polygon(Util.ellipse(Vector2.ZERO, rx, ry, 28), Color(0.3, 0.6, 0.95, 0.4 * fade))
	draw_colored_polygon(Util.ellipse(Vector2(-rx * 0.12, -ry * 0.12), rx * 0.78, ry * 0.7, 24), Color(0.5, 0.8, 1.0, 0.22 * fade))
	for i in 2:
		var t := fmod(age * 0.5 + float(i) * 0.5 + seed_v, 1.0)
		var pts := Util.ellipse(Vector2.ZERO, rx * (0.3 + 0.6 * t), ry * (0.3 + 0.6 * t), 26)
		pts.append(pts[0])
		draw_polyline(pts, Color(0.85, 0.95, 1.0, (1.0 - t) * 0.6 * fade), 1.6)
	var edge := Util.ellipse(Vector2.ZERO, rx, ry, 28)
	edge.append(edge[0])
	draw_polyline(edge, Color(0.75, 0.92, 1.0, 0.7 * fade), 2.0)
	# 전기 표시: 깜빡이는 작은 번개 무늬
	var zap := Color(1.0, 0.95, 0.4, (0.5 + 0.3 * sin(age * 5.0)) * fade)
	draw_polyline(PackedVector2Array([Vector2(-4, -9), Vector2(2, -2), Vector2(-2, -1), Vector2(4, 8)]), zap, 2.0)
