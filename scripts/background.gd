class_name Background
extends Node2D
## 카메라 주변만 그리는 무한 배경 (좌표 해시로 무늬와 장식을 결정)

const CELL := 96
const BASE := Color(0.106, 0.153, 0.118)

var cam_pos := Vector2.ZERO
var view_size := Vector2(1280, 720)
var t := 0.0


func _ready() -> void:
	z_index = -10


func _draw() -> void:
	var half := view_size / 2.0 + Vector2(CELL, CELL)
	var left := cam_pos.x - half.x
	var top := cam_pos.y - half.y
	draw_rect(Rect2(left, top, half.x * 2.0, half.y * 2.0), BASE)

	var cx0 := floori(left / CELL)
	var cx1 := floori((cam_pos.x + half.x) / CELL)
	var cy0 := floori(top / CELL)
	var cy1 := floori((cam_pos.y + half.y) / CELL)

	for cx in range(cx0, cx1 + 1):
		for cy in range(cy0, cy1 + 1):
			var h := Util.hash2(cx, cy)
			var x := float(cx * CELL)
			var y := float(cy * CELL)
			# 풀밭 얼룩
			if h < 0.4:
				var col := Color(0.15, 0.22, 0.16, 0.55) if h < 0.2 else Color(0.08, 0.12, 0.09, 0.5)
				var h2 := Util.hash2(cx + 7, cy - 3)
				draw_colored_polygon(Util.ellipse(Vector2(x + h2 * CELL, y + h * 2.0 * CELL), 30 + h2 * 30, 18 + h * 25, 14), col)
			# 풀잎
			var hg := Util.hash2(cx - 11, cy + 29)
			for i in 4:
				var gx := x + fmod(hg * 977.0 + i * 31.0, float(CELL))
				var gy := y + fmod(hg * 613.0 + i * 47.0, float(CELL))
				draw_rect(Rect2(gx, gy, 2, 5), Color(0.19, 0.28, 0.2))
			# 장식물
			var hd := Util.hash2(cx + 91, cy - 37)
			if hd > 0.86:
				var ox := x + Util.hash2(cx, cy + 5) * (CELL - 20.0) + 10.0
				var oy := y + Util.hash2(cx + 3, cy) * (CELL - 20.0) + 10.0
				_deco(int(hd * 1000.0) % 5, Vector2(ox, oy), hd)


func _deco(kind: int, p: Vector2, v: float) -> void:
	match kind:
		0:  # 묘비
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 12), 13, 4), Color(0, 0, 0, 0.35))
			draw_rect(Rect2(p.x - 9, p.y - 10, 18, 22), Color(0.35, 0.35, 0.41))
			draw_circle(p + Vector2(0, -10), 9, Color(0.35, 0.35, 0.41))
			draw_rect(Rect2(p.x - 9, p.y - 10, 4, 22), Color(0.43, 0.43, 0.49))
			draw_rect(Rect2(p.x - 1, p.y - 12, 2, 12), Color(0.22, 0.22, 0.27))
			draw_rect(Rect2(p.x - 5, p.y - 8, 10, 2), Color(0.22, 0.22, 0.27))
		1:  # 바위
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 6), 16, 5), Color(0, 0, 0, 0.3))
			draw_colored_polygon(Util.ellipse(p, 15, 9), Color(0.29, 0.29, 0.32))
			draw_colored_polygon(Util.ellipse(p + Vector2(-3, -3), 9, 5), Color(0.36, 0.36, 0.4))
		2:  # 덤불
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 8), 18, 5), Color(0, 0, 0, 0.3))
			draw_circle(p + Vector2(-8, 2), 9, Color(0.12, 0.23, 0.14))
			draw_circle(p + Vector2(8, 2), 9, Color(0.12, 0.23, 0.14))
			draw_circle(p + Vector2(0, -4), 11, Color(0.12, 0.23, 0.14))
			draw_circle(p + Vector2(-2, -6), 6, Color(0.17, 0.3, 0.19))
		3:  # 뼈
			draw_line(p + Vector2(-8, 2), p + Vector2(6, -3), Color(0.72, 0.7, 0.63), 2.5)
			draw_line(p + Vector2(-4, -5), p + Vector2(7, 4), Color(0.72, 0.7, 0.63), 2.5)
			draw_circle(p + Vector2(10, -6), 5, Color(0.82, 0.8, 0.73))
			draw_rect(Rect2(p.x + 8, p.y - 7, 2, 2), Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(p.x + 11, p.y - 7, 2, 2), Color(0.1, 0.1, 0.1))
		_:  # 반딧불 풀
			draw_rect(Rect2(p.x - 6, p.y, 2, 6), Color(0.18, 0.29, 0.2))
			draw_rect(Rect2(p.x, p.y - 2, 2, 8), Color(0.18, 0.29, 0.2))
			draw_rect(Rect2(p.x + 5, p.y + 1, 2, 5), Color(0.18, 0.29, 0.2))
			var a := 0.4 + 0.4 * sin(t * 3.0 + v * 20.0)
			draw_circle(p + Vector2(sin(t + v * 9.0) * 10.0, -10.0 + cos(t * 1.3 + v * 5.0) * 6.0), 1.8, Color(0.8, 1.0, 0.55, a))
