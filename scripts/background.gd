class_name Background
extends Node2D
## 카메라 주변만 그리는 무한 배경. 스테이지마다 다른 바닥 (좌표 해시로 무늬와 장식을 결정)

const CELL := 96
const SEAM := Color(0.055, 0.065, 0.115)

var cam_pos := Vector2.ZERO
var view_size := Vector2(1280, 720)
var t := 0.0
var style := "station"    # station / greenhouse


func _ready() -> void:
	z_index = -10


func _draw() -> void:
	if style == "greenhouse":
		_draw_greenhouse()
	else:
		_draw_station()


func _draw_station() -> void:
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


# ─────────────────────────────────────────────
# 온실 구역: 유리 바닥, 흙 화단, 이끼 낀 통로, 햇살
# ─────────────────────────────────────────────
func _draw_greenhouse() -> void:
	var half := view_size / 2.0 + Vector2(CELL, CELL)
	var left := cam_pos.x - half.x
	var top := cam_pos.y - half.y
	draw_rect(Rect2(left, top, half.x * 2.0, half.y * 2.0), Color(0.035, 0.085, 0.07))

	var cx0 := floori(left / CELL)
	var cx1 := floori((cam_pos.x + half.x) / CELL)
	var cy0 := floori(top / CELL)
	var cy1 := floori((cam_pos.y + half.y) / CELL)

	for cx in range(cx0, cx1 + 1):
		for cy in range(cy0, cy1 + 1):
			var h := Util.hash2(cx + 300, cy - 200)
			var x := float(cx * CELL)
			var y := float(cy * CELL)
			var rect := Rect2(x + 2, y + 2, CELL - 4, CELL - 4)
			if h < 0.18:
				# 흙 화단: 짙은 갈색 흙에 작은 싹
				draw_rect(rect, Color(0.2, 0.13, 0.1))
				draw_rect(Rect2(x + 2, y + 2, CELL - 4, 4), Color(0.32, 0.22, 0.16))
				for i in 5:
					var sx := x + 12.0 + Util.hash2(cx * 7 + i, cy) * (CELL - 24.0)
					var sy := y + 16.0 + Util.hash2(cx, cy * 7 + i) * (CELL - 30.0)
					draw_circle(Vector2(sx, sy), 2.2, Color(0.12, 0.08, 0.06))
					if Util.hash2(cx + i, cy + i * 3) > 0.62:
						_tiny_sprout(Vector2(sx, sy))
			elif h < 0.32:
				# 이끼 낀 돌길
				var m := 0.16 + 0.03 * Util.hash2(cx + 9, cy + 4)
				draw_rect(rect, Color(m, m + 0.05, m + 0.02))
				draw_rect(Rect2(x + 2, y + 2, CELL - 4, 3), Color(1, 1, 1, 0.04))
				for i in 3:
					var mx := x + Util.hash2(cx + i, cy * 3) * (CELL - 16.0) + 8.0
					var my := y + Util.hash2(cx * 3, cy + i) * (CELL - 16.0) + 8.0
					draw_circle(Vector2(mx, my), 5.0 + 4.0 * Util.hash2(cx + i * 5, cy), Color(0.25, 0.5, 0.28, 0.35))
			else:
				# 유리 바닥: 푸른 초록빛이 도는 패널
				var shade := 0.09 + 0.03 * Util.hash2(cx + 5, cy + 9)
				draw_rect(rect, Color(shade * 0.7, shade + 0.06, shade + 0.05))
				draw_rect(Rect2(x + 2, y + 2, CELL - 4, 3), Color(0.8, 1.0, 0.9, 0.05))
				draw_line(Vector2(x + 10, y + CELL - 12), Vector2(x + 30, y + CELL - 32), Color(1, 1, 1, 0.05), 3.0)
			# 나사 대신 작은 이슬방울
			if Util.hash2(cx + 40, cy + 41) > 0.7:
				draw_circle(Vector2(x + 10, y + 10), 1.6, Color(0.7, 0.95, 1.0, 0.35))
			# 장식물
			var hd := Util.hash2(cx + 91, cy - 37)
			if hd > 0.86:
				var ox := x + Util.hash2(cx, cy + 5) * (CELL - 44.0) + 22.0
				var oy := y + Util.hash2(cx + 3, cy) * (CELL - 44.0) + 22.0
				_greenhouse_deco(int(hd * 1000.0) % 6, Vector2(ox, oy), hd)

	# 유리 천장에서 비스듬히 내려오는 햇살 (천천히 흐른다)
	for i in 4:
		var bx := cam_pos.x - half.x + fmod(float(i) * 420.0 + t * 12.0, half.x * 2.0 + 300.0) - 150.0
		var a := 0.03 + 0.012 * sin(t * 0.6 + float(i))
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx, cam_pos.y - half.y), Vector2(bx + 90.0, cam_pos.y - half.y),
			Vector2(bx - 160.0, cam_pos.y + half.y), Vector2(bx - 250.0, cam_pos.y + half.y),
		]), Color(1.0, 0.97, 0.7, a))
	# 둥둥 떠다니는 꽃가루
	for i in 26:
		var fx := cam_pos.x - half.x + fposmod(Util.hash2(i, 77) * (half.x * 2.0) + t * (6.0 + float(i % 5) * 2.0), half.x * 2.0)
		var fy := cam_pos.y - half.y + fposmod(Util.hash2(i, 91) * (half.y * 2.0) - t * (10.0 + float(i % 4) * 3.0) + half.y * 4.0, half.y * 2.0)
		var tw := 0.5 + 0.5 * sin(t * 2.0 + float(i))
		draw_circle(Vector2(fx, fy), 2.0, Color(1.0, 0.95, 0.6, 0.25 * tw))
		draw_circle(Vector2(fx, fy), 0.9, Color(1.0, 1.0, 0.9, 0.7 * tw))


func _tiny_sprout(p: Vector2) -> void:
	draw_line(p, p + Vector2(0, -6), Color(0.3, 0.6, 0.3), 1.5)
	draw_colored_polygon(Util.ellipse(p + Vector2(-3, -7), 3.2, 1.7, 8), Color(0.45, 0.8, 0.4))
	draw_colored_polygon(Util.ellipse(p + Vector2(3, -8), 3.2, 1.7, 8), Color(0.55, 0.88, 0.45))


func _greenhouse_deco(kind: int, p: Vector2, v: float) -> void:
	match kind:
		0:  # 커다란 꽃 화분 (웃는 얼굴)
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 15), 16, 4.5), Color(0, 0, 0, 0.3))
			draw_line(p + Vector2(0, 2), p + Vector2(0, -14), Color(0.3, 0.65, 0.35), 2.5)
			var pet := Color(1.0, 0.6, 0.75) if v > 0.93 else Color(1.0, 0.85, 0.35)
			for i in 6:
				draw_circle(p + Vector2(0, -18) + Vector2.from_angle(TAU * float(i) / 6.0 + t * 0.2) * 7.0, 5.0, pet)
			draw_circle(p + Vector2(0, -18), 4.5, Color(1.0, 0.95, 0.7))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-11, 0), p + Vector2(11, 0), p + Vector2(8, 15), p + Vector2(-8, 15)]), Color(0.85, 0.5, 0.4))
			draw_rect(Rect2(p.x - 12, p.y - 2, 24, 4), Color(0.95, 0.62, 0.5))
			draw_circle(p + Vector2(-3, 8), 1.3, Color(0.2, 0.1, 0.15))
			draw_circle(p + Vector2(3, 8), 1.3, Color(0.2, 0.1, 0.15))
			draw_arc(p + Vector2(0, 9), 2.2, 0.2, PI - 0.2, 5, Color(0.2, 0.1, 0.15), 1.0)
		1:  # 버섯 무리
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 12), 18, 4.5), Color(0, 0, 0, 0.3))
			for e in [Vector3(-9, 2, 0.8), Vector3(6, 4, 1.0), Vector3(14, 8, 0.6)]:
				var q := p + Vector2(e.x, e.y)
				draw_rect(Rect2(q.x - 3 * e.z, q.y - 2, 6 * e.z, 9 * e.z), Color(0.98, 0.93, 0.83))
				draw_colored_polygon(Util.ellipse(q + Vector2(0, -3 * e.z), 10 * e.z, 7 * e.z, 14), Color(0.45, 0.62, 0.95) if e.x < 10 else Color(0.62, 0.5, 0.92))
				draw_circle(q + Vector2(-3 * e.z, -5 * e.z), 1.6 * e.z, Color(1, 1, 1, 0.9))
				draw_circle(q + Vector2(3 * e.z, -3 * e.z), 1.2 * e.z, Color(1, 1, 1, 0.9))
			var glow := 0.5 + 0.5 * sin(t * 2.0 + v * 30.0)
			draw_circle(p + Vector2(0, 0), 20.0, Color(0.55, 0.7, 1.0, 0.06 + 0.05 * glow))
		2:  # 물뿌리개
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 12), 15, 4), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(p.x - 9, p.y - 6, 18, 17), Color(0.45, 0.7, 0.85))
			draw_rect(Rect2(p.x - 9, p.y - 6, 18, 4), Color(0.6, 0.82, 0.95))
			draw_line(p + Vector2(9, 0), p + Vector2(20, -10), Color(0.4, 0.62, 0.78), 3.0)
			draw_colored_polygon(PackedVector2Array([p + Vector2(18, -13), p + Vector2(24, -8), p + Vector2(22, -6), p + Vector2(16, -10)]), Color(0.35, 0.55, 0.7))
			draw_arc(p + Vector2(-3, -8), 8.0, PI * 1.05, PI * 1.95, 10, Color(0.35, 0.55, 0.7), 2.5)
			draw_circle(p + Vector2(-3, 3), 1.2, Color(0.1, 0.15, 0.25))
			draw_circle(p + Vector2(3, 3), 1.2, Color(0.1, 0.15, 0.25))
			draw_arc(p + Vector2(0, 4), 2.0, 0.2, PI - 0.2, 5, Color(0.1, 0.15, 0.25), 1.0)
		3:  # 반짝이는 등불 (꽃봉오리 모양)
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 12), 10, 3.5), Color(0, 0, 0, 0.3))
			draw_line(p + Vector2(0, 12), p + Vector2(0, -12), Color(0.3, 0.55, 0.32), 3.0)
			var flick := 0.6 + 0.25 * sin(t * 2.5 + v * 20.0)
			draw_circle(p + Vector2(0, -16), 16.0, Color(0.7, 1.0, 0.6, 0.12 * flick))
			draw_circle(p + Vector2(0, -16), 7.0, Color(0.75, 1.0, 0.65, 0.9))
			draw_circle(p + Vector2(-2, -18), 2.2, Color(1, 1, 1, 0.9))
			for sx in [-1.0, 1.0]:
				_petal_bg(p + Vector2(sx * 5.0, -2.0), sx * 0.7, Color(0.35, 0.7, 0.4))
		4:  # 스프링클러 (물방울이 튄다)
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 12), 11, 3.5), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(p.x - 2.5, p.y - 2, 5, 14), Color(0.55, 0.6, 0.72))
			draw_rect(Rect2(p.x - 6, p.y - 7, 12, 6), Color(0.65, 0.72, 0.85))
			for i in 5:
				var ph := fmod(t * 1.4 + float(i) * 0.2 + v * 9.0, 1.0)
				var dir := -0.9 + 0.45 * float(i)
				var dp := p + Vector2(dir * ph * 26.0, -8.0 - sin(ph * PI) * 16.0 + ph * ph * 12.0)
				draw_circle(dp, 1.6, Color(0.7, 0.9, 1.0, 0.8 * (1.0 - ph * 0.5)))
		_:  # 잎이 무성한 화분 (웃는 얼굴)
			draw_colored_polygon(Util.ellipse(p + Vector2(0, 14), 15, 4.5), Color(0, 0, 0, 0.3))
			for a in [-1.0, -0.5, 0.0, 0.5, 1.0]:
				_petal_bg(p + Vector2(sin(a) * 8.0, -8.0 - cos(a) * 8.0), a, Color(0.3 + 0.1 * cos(a), 0.7, 0.4))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-10, -1), p + Vector2(10, -1), p + Vector2(7, 14), p + Vector2(-7, 14)]), Color(0.6, 0.72, 0.9))
			draw_rect(Rect2(p.x - 11, p.y - 3, 22, 4), Color(0.75, 0.85, 1.0))
			draw_circle(p + Vector2(-3, 7), 1.3, Color(0.15, 0.15, 0.3))
			draw_circle(p + Vector2(3, 7), 1.3, Color(0.15, 0.15, 0.3))
			draw_arc(p + Vector2(0, 8), 2.2, 0.2, PI - 0.2, 5, Color(0.15, 0.15, 0.3), 1.0)


func _petal_bg(center: Vector2, ang: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(center + Vector2(cos(a) * 7.0, sin(a) * 3.2).rotated(ang - PI / 2.0))
	draw_colored_polygon(pts, col)
