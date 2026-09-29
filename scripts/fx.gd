class_name Fx
extends Node2D
## 짧게 나타났다 사라지는 이펙트와 피해 숫자. Main 이 step() 을 호출한다.

enum Kind { PUFF, RING, TEXT, SLASH, BOLT }

var kind: Kind = Kind.PUFF
var life := 0.3
var max_life := 0.3
var color := Color.WHITE
var size := 10.0
var text := ""
var rise := Vector2.ZERO
var w := 0.0
var h := 0.0
var side := 1.0
var pts := PackedVector2Array()
var dead := false


static func puff(pos: Vector2, col: Color, sz: float) -> Fx:
	var f := Fx.new()
	f.kind = Kind.PUFF
	f.position = pos
	f.color = col
	f.size = sz
	f.life = 0.28
	f.max_life = 0.28
	f.z_index = 4
	return f


static func ring(pos: Vector2, col: Color, sz: float, duration: float = 0.3) -> Fx:
	var f := Fx.new()
	f.kind = Kind.RING
	f.position = pos
	f.color = col
	f.size = sz
	f.life = duration
	f.max_life = duration
	f.z_index = 4
	return f


static func number(pos: Vector2, value: float, col: Color, big: bool = false) -> Fx:
	var f := Fx.new()
	f.kind = Kind.TEXT
	f.position = pos
	f.color = col
	f.text = str(int(round(value)))
	f.size = 22.0 if big else 16.0
	f.life = 0.6
	f.max_life = 0.6
	f.rise = Vector2(randf_range(-14.0, 14.0), -48.0)
	f.z_index = 20
	return f


## 글자 알림 (반응 이름 등). 한글이 나오므로 UI 글꼴을 쓴다
static func label(pos: Vector2, txt: String, col: Color, sz: float = 20.0) -> Fx:
	var f := Fx.new()
	f.kind = Kind.TEXT
	f.position = pos
	f.color = col
	f.text = txt
	f.size = sz
	f.life = 0.9
	f.max_life = 0.9
	f.rise = Vector2(0, -34.0)
	f.z_index = 22
	return f


## 두 점을 잇는 번개 줄기 (전도 반응)
static func arc(from: Vector2, to: Vector2, col: Color = Color(1.0, 0.95, 0.5)) -> Fx:
	var f := Fx.new()
	f.kind = Kind.BOLT
	f.position = from
	f.color = col
	f.life = 0.22
	f.max_life = 0.22
	f.z_index = 15
	var d := to - from
	var perp := Vector2(-d.y, d.x).normalized()
	var segs := 6
	for i in segs + 1:
		var t := float(i) / float(segs)
		var jitter := 0.0 if i == 0 or i == segs else randf_range(-9.0, 9.0)
		f.pts.append(d * t + perp * jitter)
	return f


## 채찍 궤적
static func slash(pos: Vector2, width: float, height: float, dir: float, col: Color) -> Fx:
	var f := Fx.new()
	f.kind = Kind.SLASH
	f.position = pos
	f.w = width
	f.h = height
	f.side = dir
	f.color = col
	f.life = 0.2
	f.max_life = 0.2
	f.z_index = 6
	return f


## 번개: pos 는 떨어지는 지점, 위쪽 화면 밖에서 내리꽂는다
static func bolt(pos: Vector2, view_h: float) -> Fx:
	var f := Fx.new()
	f.kind = Kind.BOLT
	f.position = pos
	f.color = Color(1.0, 0.95, 0.5)
	f.life = 0.25
	f.max_life = 0.25
	f.z_index = 15
	var top := -view_h * 0.7
	var cx := randf_range(-40.0, 40.0)
	var segs := 9
	for i in segs + 1:
		var t := float(i) / float(segs)
		var px := 0.0 if i == segs else lerpf(cx, 0.0, t) + randf_range(-14.0, 14.0)
		f.pts.append(Vector2(px, lerpf(top, 0.0, t)))
	return f


## 끝났으면 true
func step(delta: float) -> bool:
	life -= delta
	if kind == Kind.TEXT:
		position += rise * delta
		rise.y += 60.0 * delta
	queue_redraw()
	dead = life <= 0.0
	return dead


func _draw() -> void:
	var t := 1.0 - clampf(life / max_life, 0.0, 1.0)
	match kind:
		Kind.PUFF:
			var r := size * (0.5 + t)
			draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, (1.0 - t) * 0.7))
			for i in 5:
				var a := TAU * float(i) / 5.0 + size
				draw_circle(Vector2(cos(a), sin(a)) * r * 1.3, size * 0.18 * (1.0 - t), Color(color.r, color.g, color.b, 1.0 - t))
		Kind.RING:
			draw_arc(Vector2.ZERO, size * (0.3 + t * 0.9), 0.0, TAU, 40, Color(color.r, color.g, color.b, (1.0 - t) * 0.9), 3.0)
		Kind.TEXT:
			var font := UiTheme.get_theme().default_font
			var a := clampf(life / max_life * 1.6, 0.0, 1.0)
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x
			draw_string_outline(font, Vector2(-tw / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size), 5, Color(0, 0, 0, a))
			draw_string(font, Vector2(-tw / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size), Color(color.r, color.g, color.b, a))
		Kind.SLASH:
			var a := 1.0 - t
			var hw := w / 2.0
			var hh := h / 2.0
			# 바깥으로 갈수록 가늘어지는 초승달 모양
			var poly := PackedVector2Array([
				Vector2(-side * hw, 0), Vector2(-side * hw * 0.2, -hh), Vector2(side * hw, -hh * 0.15),
				Vector2(side * hw, hh * 0.15), Vector2(-side * hw * 0.2, hh),
			])
			draw_colored_polygon(poly, Color(color.r, color.g, color.b, a * 0.75))
			draw_line(Vector2(-side * hw, 0), Vector2(side * hw, 0), Color(1, 1, 1, a), 2.0)
		Kind.BOLT:
			var a := clampf(life / max_life * 1.5, 0.0, 1.0)
			draw_polyline(pts, Color(color.r, color.g, color.b, a * 0.35), 12.0)
			draw_polyline(pts, Color(color.r, color.g, color.b, a), 5.0)
			draw_polyline(pts, Color(1, 1, 1, a), 2.0)
