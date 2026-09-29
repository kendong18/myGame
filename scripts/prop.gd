class_name Prop
extends Node2D
## 부술 수 있는 보급 캡슐. 부수면 아이템이 나온다.

var dead := false
var t := 0.0


func _ready() -> void:
	z_index = 1
	t = randf() * TAU


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(Util.ellipse(Vector2(0, 16), 14, 4), Color(0, 0, 0, 0.3))
	# 받침
	draw_rect(Rect2(-11, 9, 22, 7), Color(0.4, 0.45, 0.6))
	draw_rect(Rect2(-11, 9, 22, 2), Color(0.6, 0.66, 0.82))
	# 유리 캡슐
	var glass := Color(0.6, 0.9, 1.0, 0.38)
	draw_rect(Rect2(-9, -8, 18, 18), glass)
	draw_circle(Vector2(0, -8), 9.0, glass)
	draw_arc(Vector2(0, -8), 9.0, PI, TAU, 14, Color(0.85, 0.97, 1.0, 0.85), 1.5)
	draw_line(Vector2(-9, -8), Vector2(-9, 10), Color(0.85, 0.97, 1.0, 0.85), 1.5)
	draw_line(Vector2(9, -8), Vector2(9, 10), Color(0.85, 0.97, 1.0, 0.85), 1.5)
	# 안에서 빛나는 에너지 구슬
	var pulse := 1.0 + 0.12 * sin(t * 4.0)
	draw_circle(Vector2(0, 0), 8.0 * pulse, Color(1.0, 0.85, 0.35, 0.22))
	draw_circle(Vector2(0, 0), 5.0 * pulse, Color(1.0, 0.85, 0.35))
	draw_circle(Vector2(0, 0), 2.5, Color(1.0, 1.0, 0.85))
	draw_circle(Vector2(-4, -6), 1.6, Color(1, 1, 1, 0.8))
	# 안테나
	draw_line(Vector2(0, -17), Vector2(0, -22), Color(0.5, 0.55, 0.7), 1.5)
	draw_circle(Vector2(0, -23), 1.8, Color(1.0, 0.4, 0.5) if int(t * 3.0) % 2 == 0 else Color(1.0, 0.8, 0.85))
