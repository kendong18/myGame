class_name Util
extends RefCounted
## 공용 도우미 함수


static func ellipse(center: Vector2, rx: float, ry: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## 좌표로부터 항상 같은 0~1 값을 만드는 해시 (맵 장식 배치용)
static func hash2(x: int, y: int) -> float:
	var h: int = (x * 374761393 + y * 668265263) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFFFF) / 4294967296.0


static func fmt_time(sec: float) -> String:
	var s := maxi(0, int(sec))
	return "%02d:%02d" % [s / 60, s % 60]


## 귀여운 눈: 흰자, 눈동자, 반짝이는 하이라이트
static func eye(ci: CanvasItem, pos: Vector2, r: float, look: Vector2 = Vector2.ZERO, pupil: Color = Color(0.1, 0.1, 0.2)) -> void:
	ci.draw_circle(pos, r, Color.WHITE)
	var pp := pos + look * r * 0.3
	ci.draw_circle(pp, r * 0.66, pupil)
	ci.draw_circle(pp + Vector2(-r * 0.22, -r * 0.26), r * 0.25, Color.WHITE)


## 볼터치
static func cheek(ci: CanvasItem, pos: Vector2, r: float) -> void:
	ci.draw_circle(pos, r, Color(1.0, 0.55, 0.65, 0.55))


## 젤리 모양: 위는 둥글고 아래는 살짝 납작한 덩어리 (center 기준)
static func blob(center: Vector2, rx: float, ry: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := PI + PI * float(i) / float(n)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	pts.append(center + Vector2(rx, ry * 0.35))
	pts.append(center + Vector2(rx * 0.6, ry * 0.58))
	pts.append(center + Vector2(-rx * 0.6, ry * 0.58))
	pts.append(center + Vector2(-rx, ry * 0.35))
	return pts


## 닫힌 윤곽선 그리기
static func outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, width: float = 1.5) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col, width)
