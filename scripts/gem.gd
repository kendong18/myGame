class_name Gem
extends Node2D
## 경험치 보석

var value := 1
var attracted := false
var pull_speed := 0.0
var dead := false
var t := 0.0
var _tier := -1


func _ready() -> void:
	t = randf() * TAU
	z_index = -1
	_refresh()


func add_value(v: int) -> void:
	value += v
	_refresh()


func _tier_for(v: int) -> int:
	if v < 3:
		return 0
	if v < 11:
		return 1
	if v < 41:
		return 2
	return 3


func _refresh() -> void:
	var tier := _tier_for(value)
	if tier != _tier:
		_tier = tier
		queue_redraw()


func _draw() -> void:
	var cols := [
		Color(0.3, 0.66, 1.0), Color(0.32, 0.88, 0.44),
		Color(1.0, 0.33, 0.4), Color(0.75, 0.44, 1.0),
	]
	var c: Color = cols[maxi(_tier, 0)]
	var s := 5.0 + _tier * 1.5
	var pts := PackedVector2Array([Vector2(0, -s * 1.2), Vector2(s, 0), Vector2(0, s * 1.2), Vector2(-s, 0)])
	draw_colored_polygon(pts, c.darkened(0.35))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -s * 1.2), Vector2(s, 0), Vector2(0, s * 0.2), Vector2(-s * 0.2, -s * 0.2)]), c)
	draw_circle(Vector2(-s * 0.25, -s * 0.5), 1.4, Color(1, 1, 1, 0.9))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0.05, 0.03, 0.1, 0.8), 1.0)
