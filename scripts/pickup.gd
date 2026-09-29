class_name Pickup
extends Node2D
## 바닥에 떨어진 아이템: 치킨(회복), 자석(보석 흡수), 폭탄(화면 공격), 동전(골드)

var kind := "chicken"
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
	draw_colored_polygon(Util.ellipse(Vector2(0, 11), 9, 3), Color(0, 0, 0, 0.35))
	match kind:
		"chicken":
			draw_circle(Vector2(-2, -2 + bob), 8, Color(0.85, 0.5, 0.2))
			draw_circle(Vector2(-4, -4 + bob), 3.5, Color(0.95, 0.68, 0.35))
			draw_line(Vector2(3, 3 + bob), Vector2(10, 9 + bob), Color(0.95, 0.9, 0.8), 4.0)
			draw_circle(Vector2(11, 10 + bob), 2.6, Color(0.95, 0.9, 0.8))
			draw_circle(Vector2(8, 12 + bob), 2.6, Color(0.95, 0.9, 0.8))
		"magnet":
			draw_arc(Vector2(0, 2 + bob), 7.0, PI, TAU, 14, Color(0.85, 0.15, 0.2), 5.0)
			draw_line(Vector2(-7, 2 + bob), Vector2(-7, 9 + bob), Color(0.85, 0.15, 0.2), 5.0)
			draw_line(Vector2(7, 2 + bob), Vector2(7, 9 + bob), Color(0.85, 0.15, 0.2), 5.0)
			draw_rect(Rect2(-9.5, 7 + bob, 5, 4), Color(0.85, 0.88, 0.95))
			draw_rect(Rect2(4.5, 7 + bob, 5, 4), Color(0.85, 0.88, 0.95))
		"bomb":
			draw_circle(Vector2(0, 1 + bob), 8, Color(0.12, 0.12, 0.16))
			draw_circle(Vector2(-3, -2 + bob), 2.5, Color(0.4, 0.4, 0.5))
			draw_line(Vector2(3, -6 + bob), Vector2(7, -11 + bob), Color(0.6, 0.45, 0.25), 2.0)
			var spark := 0.5 + 0.5 * sin(t * 20.0)
			draw_circle(Vector2(8, -12 + bob), 2.5 + spark, Color(1.0, 0.75, 0.2))
		"coin":
			var w := absf(cos(t * 3.0)) * 7.0 + 1.5
			draw_colored_polygon(Util.ellipse(Vector2(0, bob), w, 7.5, 14), Color(0.95, 0.75, 0.15))
			draw_colored_polygon(Util.ellipse(Vector2(0, bob), maxf(w - 2.0, 0.5), 5.5, 14), Color(1.0, 0.88, 0.35))
