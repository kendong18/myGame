class_name Chest
extends Node2D
## 보급 상자. 엘리트와 보스가 떨어뜨린다. tier 는 보상 개수.

var tier := 1
var t := 0.0
var dead := false


func _ready() -> void:
	z_index = 2


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(t * 3.0) * 2.0
	var glow := 0.25 + 0.15 * sin(t * 4.0)
	draw_circle(Vector2(0, bob), 26.0, Color(0.5, 0.95, 1.0, glow))
	draw_colored_polygon(Util.ellipse(Vector2(0, 12), 16, 5), Color(0, 0, 0, 0.35))
	# 상자 본체 (푸른 금속 상자)
	draw_rect(Rect2(-14, -6 + bob, 28, 18), Color(0.35, 0.55, 0.85))
	draw_rect(Rect2(-14, -6 + bob, 28, 5), Color(0.5, 0.72, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -6 + bob), Vector2(-11, -13 + bob), Vector2(11, -13 + bob), Vector2(14, -6 + bob),
	]), Color(0.45, 0.66, 0.95))
	draw_rect(Rect2(-14, 3 + bob, 28, 2), Color(0.2, 0.32, 0.55))
	draw_rect(Rect2(-14, -6 + bob, 28, 18), Color(0.1, 0.16, 0.32), false, 1.5)
	# 별 모양 잠금 장치
	var c := Vector2(0, -1 + bob)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -5), c + Vector2(1.5, -1.5), c + Vector2(5, -1.2), c + Vector2(2.2, 1.2),
		c + Vector2(3.2, 5), c + Vector2(0, 2.8), c + Vector2(-3.2, 5), c + Vector2(-2.2, 1.2),
		c + Vector2(-5, -1.2), c + Vector2(-1.5, -1.5),
	]), Color(1.0, 0.9, 0.35))
	# 반짝임
	var sp := fmod(t * 1.5, 1.0)
	draw_circle(Vector2(-9 + sp * 18.0, -14 + bob), 1.8 * (1.0 - sp), Color(1, 1, 0.9))
	if tier >= 3:
		draw_arc(Vector2(0, bob), 30.0, 0.0, TAU, 32, Color(1.0, 0.6, 0.9, 0.7), 2.0)
