class_name Background
extends Node2D
## 카메라 주변만 그리는 무한 배경. 우주 정거장 바닥 (좌표 해시로 무늬와 장식을 결정)

const CELL := 96
const SEAM := Color(0.055, 0.065, 0.115)

var cam_pos := Vector2.ZERO
var view_size := Vector2(1280, 720)
var t := 0.0


func _ready() -> void:
	z_index = -10


func _draw() -> void:
	var half := view_size / 2.0 + Vector2(CELL, CELL)
	var left := cam_pos.x - half.x
	var top := cam_pos.y - half.y
	draw_rect(Rect2(left, top, half.x * 2.0, half.y * 2.0), SEAM)

	var cx0 := floori(left / CELL)
	var cx1 := floori((cam_pos.x + half.x) / CELL)
	var cy0 := floori(top / CELL)
	var cy1 := floori((cam_pos.y + half.y) / CELL)

	for cx in range(cx0, cx1 + 1):
		for cy in range(cy0, cy1 + 1):
			var h := Util.hash2(cx, cy)
			var x := float(cx * CELL)
			var y := float(cy * CELL)
			# 바닥 패널 (칸마다 살짝 다른 색)
			var shade := 0.10 + 0.035 * Util.hash2(cx + 5, cy + 9)
			draw_rect(Rect2(x + 2, y + 2, CELL - 4, CELL - 4), Color(shade, shade + 0.02, shade + 0.085))
			draw_rect(Rect2(x + 2, y + 2, CELL - 4, 3), Color(1, 1, 1, 0.035))
			# 나사
			if h > 0.5:
				for p in [Vector2(9, 9), Vector2(CELL - 9, CELL - 9)]:
					draw_circle(Vector2(x, y) + p, 2.0, Color(0.05, 0.06, 0.11, 0.7))
					draw_circle(Vector2(x, y) + p + Vector2(-0.5, -0.5), 0.8, Color(1, 1, 1, 0.18))
			# 빛나는 안내선
			if h < 0.06:
				var horizontal := Util.hash2(cy, cx) < 0.5
				var glow := Color(0.35, 0.9, 1.0) if h < 0.03 else Color(1.0, 0.55, 0.85)
				var pulse := 0.3 + 0.12 * sin(t * 2.0 + h * 40.0)
				if horizontal:
					draw_rect(Rect2(x, y + CELL / 2.0 - 3, CELL, 6), Color(glow.r, glow.g, glow.b, pulse * 0.6))
					draw_rect(Rect2(x, y + CELL / 2.0 - 1, CELL, 2), Color(glow.r, glow.g, glow.b, pulse + 0.4))
				else:
					draw_rect(Rect2(x + CELL / 2.0 - 3, y, 6, CELL), Color(glow.r, glow.g, glow.b, pulse * 0.6))
					draw_rect(Rect2(x + CELL / 2.0 - 1, y, 2, CELL), Color(glow.r, glow.g, glow.b, pulse + 0.4))
			# 주의 줄무늬
			elif h < 0.085:
				for i in 6:
					var sx := x + 4.0 + float(i) * 16.0
					draw_colored_polygon(PackedVector2Array([
						Vector2(sx, y + CELL - 4), Vector2(sx + 8, y + CELL - 4), Vector2(sx + 16, y + CELL - 14), Vector2(sx + 8, y + CELL - 14),
					]), Color(1.0, 0.82, 0.25, 0.32))
			# 장식물
			var hd := Util.hash2(cx + 91, cy - 37)
			if hd > 0.87:
				var ox := x + Util.hash2(cx, cy + 5) * (CELL - 44.0) + 22.0
				var oy := y + Util.hash2(cx + 3, cy) * (CELL - 44.0) + 22.0
				_deco(int(hd * 1000.0) % 6, Vector2(ox, oy), hd)


func _deco(kind: int, p: Vector2, v: float) -> void:
	match kind:
		0:  # 보급 상자 (테이프와 웃는 라벨)
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 14), 17, 5), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(p.x - 14, p.y - 10, 28, 24), Color(0.62, 0.48, 0.34))
			draw_rect(Rect2(p.x - 14, p.y - 10, 28, 6), Color(0.74, 0.6, 0.44))
			draw_rect(Rect2(p.x - 3, p.y - 10, 6, 24), Color(0.9, 0.85, 0.7, 0.8))
			draw_rect(Rect2(p.x - 14, p.y - 10, 28, 24), Color(0.25, 0.18, 0.12), false, 1.5)
			draw_circle(Vector2(p.x + 8, p.y + 5), 3.2, Color(1, 1, 1, 0.85))
			draw_arc(Vector2(p.x + 8, p.y + 5), 1.8, 0.2, PI - 0.2, 5, Color(0.3, 0.2, 0.2), 1.0)
		1:  # 화분 (웃는 얼굴이 있는 식물)
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 14), 14, 4), Color(0, 0, 0, 0.3))
			for a in [-0.9, -0.3, 0.3, 0.9]:
				var tip := p + Vector2(sin(a) * 15.0, -17.0 - cos(a) * 5.0)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -4), p + Vector2(2, -4), tip]), Color(0.3, 0.75, 0.45))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-10, -3), p + Vector2(10, -3), p + Vector2(7, 14), p + Vector2(-7, 14)]), Color(0.95, 0.6, 0.5))
			draw_rect(Rect2(p.x - 11, p.y - 5, 22, 4), Color(1.0, 0.72, 0.62))
			draw_circle(Vector2(p.x - 3, p.y + 5), 1.3, Color(0.2, 0.1, 0.15))
			draw_circle(Vector2(p.x + 3, p.y + 5), 1.3, Color(0.2, 0.1, 0.15))
			draw_arc(Vector2(p.x, p.y + 7), 2.2, 0.2, PI - 0.2, 5, Color(0.2, 0.1, 0.15), 1.0)
		2:  # 관제 콘솔
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 14), 19, 5), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(p.x - 17, p.y - 4, 34, 18), Color(0.3, 0.34, 0.48))
			draw_rect(Rect2(p.x - 14, p.y - 15, 28, 14), Color(0.12, 0.16, 0.28))
			draw_rect(Rect2(p.x - 12, p.y - 13, 24, 10), Color(0.08, 0.22, 0.3))
			for i in 4:
				var bar := 3.0 + 6.0 * absf(sin(t * 2.0 + v * 30.0 + float(i)))
				draw_rect(Rect2(p.x - 10 + i * 5.5, p.y - 4 - bar, 4, bar), Color(0.4, 0.95, 0.8))
			draw_circle(Vector2(p.x - 9, p.y + 6), 1.8, Color(1.0, 0.4, 0.5) if int(t * 2.0 + v * 9.0) % 2 == 0 else Color(0.5, 0.2, 0.25))
			draw_circle(Vector2(p.x, p.y + 6), 1.8, Color(0.4, 1.0, 0.6))
			draw_circle(Vector2(p.x + 9, p.y + 6), 1.8, Color(1.0, 0.9, 0.4))
		3:  # 환기구
			draw_rect(Rect2(p.x - 15, p.y - 11, 30, 22), Color(0.17, 0.2, 0.3))
			for i in 4:
				draw_rect(Rect2(p.x - 12, p.y - 8 + i * 5, 24, 2.5), Color(0.06, 0.07, 0.12))
			draw_rect(Rect2(p.x - 15, p.y - 11, 30, 22), Color(0.4, 0.45, 0.6), false, 1.5)
		4:  # 동글동글 쿠션
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 11), 17, 5), Color(0, 0, 0, 0.3))
			var cush := Color(1.0, 0.65, 0.8) if v > 0.93 else Color(0.6, 0.8, 1.0)
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 2), 17, 11, 18), cush)
			draw_colored_polygon(Util.ellipse(p + Vector2(-3, -1), 9, 5, 12), cush.lightened(0.3))
			draw_circle(Vector2(p.x - 4, p.y + 3), 1.4, Color(0.2, 0.15, 0.3))
			draw_circle(Vector2(p.x + 4, p.y + 3), 1.4, Color(0.2, 0.15, 0.3))
		_:  # 바닥 조명
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 12), 10, 3.5), Color(0, 0, 0, 0.3))
			draw_line(p + Vector2(0, 12), p + Vector2(0, -14), Color(0.4, 0.45, 0.6), 3.0)
			var flick := 0.55 + 0.2 * sin(t * 3.0 + v * 20.0)
			draw_circle(p + Vector2(0, -16), 14.0, Color(1.0, 0.9, 0.5, 0.12 * flick))
			draw_circle(p + Vector2(0, -16), 6.5, Color(1.0, 0.92, 0.55, 0.9))
			draw_circle(p + Vector2(-2, -18), 2.0, Color(1, 1, 1, 0.9))
