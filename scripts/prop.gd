class_name Prop
extends Node2D
## 부술 수 있는 화로. 부수면 아이템이 나온다.

var dead := false
var t := 0.0


func _ready() -> void:
	z_index = 1
	t = randf() * TAU


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(Util.ellipse(Vector2(0, 16), 14, 4), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(-2, 0, 4, 16), Color(0.32, 0.26, 0.24))
	draw_rect(Rect2(-8, 14, 16, 3), Color(0.32, 0.26, 0.24))
	# 그릇
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -6), Vector2(12, -6), Vector2(8, 4), Vector2(-8, 4)]), Color(0.42, 0.34, 0.3))
	draw_rect(Rect2(-13, -8, 26, 3), Color(0.55, 0.45, 0.4))
	# 불꽃
	var f1 := 11.0 + 4.0 * sin(t * 9.0)
	var f2 := 8.0 + 3.0 * sin(t * 12.0 + 1.0)
	draw_circle(Vector2(0, -9), 14.0, Color(1.0, 0.55, 0.1, 0.16))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(2, -8 - f1), Vector2(-2, -8 - f1 * 0.4)]), Color(1.0, 0.5, 0.12, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -8), Vector2(4, -8), Vector2(0, -8 - f2)]), Color(1.0, 0.85, 0.3, 0.95))
