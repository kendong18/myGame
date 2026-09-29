class_name Chest
extends Node2D
## 보물상자. 엘리트와 보스가 떨어뜨린다. tier 는 보상 개수.

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
	draw_circle(Vector2(0, bob), 26.0, Color(1.0, 0.85, 0.3, glow))
	draw_colored_polygon(Util.ellipse(Vector2(0, 12), 16, 5), Color(0, 0, 0, 0.4))
	# 상자 본체
	draw_rect(Rect2(-14, -6 + bob, 28, 18), Color(0.66, 0.42, 0.16))
	draw_rect(Rect2(-14, -6 + bob, 28, 5), Color(0.8, 0.55, 0.22))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -6 + bob), Vector2(-11, -13 + bob), Vector2(11, -13 + bob), Vector2(14, -6 + bob),
	]), Color(0.75, 0.5, 0.2))
	draw_rect(Rect2(-14, 3 + bob, 28, 2), Color(0.35, 0.2, 0.08))
	draw_rect(Rect2(-3, -8 + bob, 6, 8), Color(1.0, 0.86, 0.25))
	draw_rect(Rect2(-14, -6 + bob, 28, 18), Color(0.15, 0.08, 0.03), false, 1.5)
	# 반짝임
	var sp := fmod(t * 1.5, 1.0)
	draw_circle(Vector2(-9 + sp * 18.0, -14 + bob), 1.8 * (1.0 - sp), Color(1, 1, 0.8))
	if tier >= 3:
		draw_arc(Vector2(0, bob), 30.0, 0.0, TAU, 32, Color(1.0, 0.5, 0.9, 0.7), 2.0)
