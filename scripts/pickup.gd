class_name Pickup
extends Node2D
## 바닥에 떨어진 아이템: 배터리(회복), 자석(보석 흡수), 펄스탄(화면 공격), 동전(골드)

var kind := "battery"
var t := 0.0
var dead := false


func _ready() -> void:
	z_index = 1
	t = randf() * TAU


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(t * 4.0) * 2.0
	draw_colored_polygon(Util.ellipse(Vector2(0, 11), 9, 3), Color(0, 0, 0, 0.3))
	match kind:
		"battery":
			draw_circle(Vector2(0, bob), 13.0, Color(0.4, 1.0, 0.55, 0.16 + 0.06 * sin(t * 5.0)))
			draw_rect(Rect2(-3, -11 + bob, 6, 3), Color(0.75, 0.8, 0.9))
			draw_rect(Rect2(-7, -8 + bob, 14, 18), Color(0.4, 0.9, 0.5))
			draw_rect(Rect2(-7, -8 + bob, 14, 5), Color(0.6, 1.0, 0.7))
			draw_rect(Rect2(-7, -8 + bob, 14, 18), Color(0.1, 0.35, 0.2), false, 1.5)
			draw_polyline(PackedVector2Array([Vector2(1, -4 + bob), Vector2(-3, 2 + bob), Vector2(1, 2 + bob), Vector2(-1, 8 + bob)]), Color(1.0, 0.95, 0.4), 2.0)
			draw_circle(Vector2(-3, -5 + bob), 1.2, Color(1, 1, 1, 0.8))
		"magnet":
			draw_circle(Vector2(0, bob), 13.0, Color(0.5, 0.7, 1.0, 0.14))
			draw_arc(Vector2(0, 2 + bob), 7.0, PI, TAU, 14, Color(0.9, 0.3, 0.4), 5.0)
			draw_line(Vector2(-7, 2 + bob), Vector2(-7, 9 + bob), Color(0.9, 0.3, 0.4), 5.0)
			draw_line(Vector2(7, 2 + bob), Vector2(7, 9 + bob), Color(0.9, 0.3, 0.4), 5.0)
			draw_rect(Rect2(-9.5, 7 + bob, 5, 4), Color(0.88, 0.92, 1.0))
			draw_rect(Rect2(4.5, 7 + bob, 5, 4), Color(0.88, 0.92, 1.0))
		"pulse":
			var pl := 1.0 + 0.12 * sin(t * 6.0)
			draw_circle(Vector2(0, bob), 14.0 * pl, Color(0.5, 0.8, 1.0, 0.16))
			draw_arc(Vector2(0, bob), 11.0 * pl, 0.0, TAU, 20, Color(0.7, 0.9, 1.0, 0.6), 1.5)
			draw_circle(Vector2(0, bob), 8.0, Color(0.35, 0.6, 0.95))
			draw_circle(Vector2(0, bob), 5.0, Color(0.6, 0.85, 1.0))
			draw_circle(Vector2(-2.5, -3 + bob), 2.0, Color(1, 1, 1, 0.9))
			draw_circle(Vector2(-2.5, 0 + bob), 1.1, Color(0.1, 0.15, 0.3))
			draw_circle(Vector2(2.5, 0 + bob), 1.1, Color(0.1, 0.15, 0.3))
		"coin":
			var w := absf(cos(t * 3.0)) * 7.0 + 1.5
			draw_colored_polygon(Util.ellipse(Vector2(0, bob), w, 8.0, 14), Color(1.0, 0.78, 0.2))
			draw_colored_polygon(Util.ellipse(Vector2(0, bob), maxf(w - 2.0, 0.5), 6.0, 14), Color(1.0, 0.9, 0.45))
			if w > 5.0:
				draw_colored_polygon(PackedVector2Array([
					Vector2(0, -3.5 + bob), Vector2(1.2, -1 + bob), Vector2(3.5, -0.8 + bob), Vector2(1.6, 1 + bob),
					Vector2(2.2, 3.5 + bob), Vector2(0, 2.2 + bob), Vector2(-2.2, 3.5 + bob), Vector2(-1.6, 1 + bob),
					Vector2(-3.5, -0.8 + bob), Vector2(-1.2, -1 + bob),
				]), Color(1.0, 0.7, 0.15))
