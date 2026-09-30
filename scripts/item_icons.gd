class_name ItemIcons
extends RefCounted
## 무기와 아이템의 아이콘. 다른 그림처럼 코드로 그린다. 진화한 무기는 원래 무기와 같은 모양이고 밝게 빛난다.

const PASSIVE_COLORS := {
	"cell": Color(0.45, 0.85, 0.5), "suit": Color(0.5, 0.7, 1.0), "tank": Color(0.6, 0.85, 0.95),
	"repair": Color(1.0, 0.5, 0.55), "jet": Color(0.95, 0.75, 0.4), "fan": Color(0.6, 0.9, 1.0),
	"lens": Color(0.8, 0.9, 1.0), "cloner": Color(0.8, 0.6, 1.0), "field": Color(1.0, 0.45, 0.45),
	"chip": Color(0.35, 0.75, 0.6), "screw": Color(0.5, 0.85, 0.4), "booster": Color(1.0, 0.85, 0.35),
	"module": Color(0.8, 0.75, 1.0), "catalyst": Color(0.85, 0.55, 1.0), "heal": Color(1.0, 0.45, 0.55),
}


## 진화한 무기 아이디를 원래 무기 아이디로 바꾼다 (그림은 원래 무기와 같다)
static func base_id(id: String) -> String:
	for wid: String in GameData.WEAPONS:
		var ev: Variant = GameData.WEAPONS[wid].get("evolve")
		if ev != null and ev.into == id:
			return wid
	return id


static func has_icon(id: String) -> bool:
	return GameData.WEAPONS.has(id) or GameData.PASSIVES.has(id) or id == "heal"


static func main_color(id: String) -> Color:
	if GameData.WEAPONS.has(id):
		return GameData.element_color(str(GameData.WEAPONS[id].get("element", "")))
	return PASSIVE_COLORS.get(id, Color(0.85, 0.88, 0.95))


## center 를 중심으로 반지름 radius 안에 아이콘을 그린다
static func draw(ci: CanvasItem, id: String, center: Vector2, radius: float) -> void:
	var gid := base_id(id)
	var c := main_color(id)
	ci.draw_set_transform(center, 0.0, Vector2(radius, radius))
	if GameData.WEAPONS.has(gid):
		_weapon(ci, gid, c)
	else:
		_passive(ci, gid, c)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# 아래 그림은 반지름 1인 단위 좌표에 그린다
static func _weapon(ci: CanvasItem, id: String, c: Color) -> void:
	var d := c.darkened(0.4)
	var l := c.lightened(0.45)
	match id:
		"torch":
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(0.05, -1.0), Vector2(0.55, -0.3), Vector2(0.65, 0.3), Vector2(0.3, 0.85), Vector2(0, 0.95),
				Vector2(-0.35, 0.8), Vector2(-0.65, 0.3), Vector2(-0.45, -0.25), Vector2(-0.15, -0.5),
			]), c)
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(0.05, -0.2), Vector2(0.35, 0.3), Vector2(0.2, 0.75), Vector2(-0.2, 0.75), Vector2(-0.35, 0.3),
			]), l)
		"gelgun":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-0.5, 0.1), Vector2(0, -1.0), Vector2(0.5, 0.1)]), c)
			ci.draw_circle(Vector2(0, 0.3), 0.62, c)
			ci.draw_circle(Vector2(-0.22, 0.12), 0.18, l)
			ci.draw_arc(Vector2(0, 0.3), 0.62, 0.6, 2.5, 10, d, 0.09)
		"bolt":
			var zig := PackedVector2Array([
				Vector2(0.25, -1.0), Vector2(-0.55, 0.1), Vector2(-0.05, 0.1), Vector2(-0.3, 1.0), Vector2(0.6, -0.2), Vector2(0.08, -0.2),
			])
			ci.draw_colored_polygon(zig, c)
			ci.draw_polyline(_closed(zig), d, 0.08)
		"canister":
			ci.draw_rect(Rect2(-0.45, -0.7, 0.9, 1.5), c)
			ci.draw_rect(Rect2(-0.52, -0.88, 1.04, 0.28), d)
			ci.draw_rect(Rect2(-0.45, -0.1, 0.9, 0.45), l)
			ci.draw_circle(Vector2(0, 0.12), 0.14, Color.WHITE)
			ci.draw_rect(Rect2(-0.45, -0.7, 0.9, 1.5), d, false, 0.08)
		"vacuum":
			ci.draw_arc(Vector2.ZERO, 0.85, 0.3, 4.7, 24, c, 0.22)
			ci.draw_arc(Vector2.ZERO, 0.5, 2.0, 5.6, 20, l, 0.2)
			ci.draw_circle(Vector2.ZERO, 0.15, Color.WHITE)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0.75, 0.55), Vector2(1.0, 0.1), Vector2(0.45, 0.2)]), c)
		"satellite":
			var ring := Util.ellipse(Vector2.ZERO, 0.95, 0.38, 24)
			for i in ring.size():
				ring[i] = ring[i].rotated(-0.5)
			ci.draw_polyline(_closed(ring), l, 0.12)
			ci.draw_circle(Vector2.ZERO, 0.42, c)
			ci.draw_circle(Vector2(-0.14, -0.14), 0.13, Color(1, 1, 1, 0.8))
			ci.draw_circle(Vector2(0.62, -0.62), 0.2, Color.WHITE)
		"hotplate":
			ci.draw_rect(Rect2(-0.9, 0.2, 1.8, 0.6), d)
			ci.draw_rect(Rect2(-0.9, 0.2, 1.8, 0.2), c)
			for x in [-0.5, 0.0, 0.5]:
				var wave := PackedVector2Array()
				for i in 7:
					var t := float(i) / 6.0
					wave.append(Vector2(x + sin(t * TAU + x * 4.0) * 0.14, 0.05 - t * 1.0))
				ci.draw_polyline(wave, l, 0.13)
		"tesla":
			ci.draw_rect(Rect2(-0.55, 0.72, 1.1, 0.24), d)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-0.3, 0.72), Vector2(0.3, 0.72), Vector2(0.14, -0.3), Vector2(-0.14, -0.3)]), c)
			ci.draw_circle(Vector2(0, -0.5), 0.3, l)
			ci.draw_polyline(PackedVector2Array([Vector2(0.3, -0.6), Vector2(0.55, -0.45), Vector2(0.45, -0.85), Vector2(0.8, -0.8)]), Color.WHITE, 0.08)
			ci.draw_polyline(PackedVector2Array([Vector2(-0.3, -0.6), Vector2(-0.6, -0.4), Vector2(-0.5, -0.8), Vector2(-0.85, -0.85)]), Color.WHITE, 0.08)
		"laser":
			ci.draw_line(Vector2.ZERO, Vector2(0.95, -0.55), c, 0.34)
			ci.draw_line(Vector2.ZERO, Vector2(0.95, -0.55), Color.WHITE, 0.12)
			ci.draw_line(Vector2.ZERO, Vector2(-0.8, 0.5), Color(c.r, c.g, c.b, 0.45), 0.26)
			ci.draw_circle(Vector2.ZERO, 0.32, d)
			ci.draw_circle(Vector2.ZERO, 0.18, l)
		"mine":
			for i in 8:
				var dir := Vector2.from_angle(TAU * float(i) / 8.0)
				ci.draw_line(dir * 0.55, dir * 0.95, c, 0.2)
			ci.draw_circle(Vector2.ZERO, 0.62, d)
			ci.draw_arc(Vector2.ZERO, 0.62, 0.0, TAU, 20, c, 0.1)
			ci.draw_circle(Vector2.ZERO, 0.22, Color(1.0, 0.4, 0.4))
			ci.draw_circle(Vector2(-0.18, -0.2), 0.08, Color(1, 1, 1, 0.8))
		"shield":
			var sh := PackedVector2Array([
				Vector2(0, -0.95), Vector2(0.8, -0.6), Vector2(0.7, 0.25), Vector2(0, 0.95), Vector2(-0.7, 0.25), Vector2(-0.8, -0.6),
			])
			ci.draw_colored_polygon(sh, c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -0.6), Vector2(0.5, -0.38), Vector2(0.44, 0.15), Vector2(0, 0.6), Vector2(-0.44, 0.15), Vector2(-0.5, -0.38)]), l)
			ci.draw_polyline(_closed(sh), d, 0.09)
		"railgun":
			ci.draw_line(Vector2(-0.85, 0.5), Vector2(0.5, -0.2), d, 0.4)
			ci.draw_line(Vector2(-0.85, 0.5), Vector2(0.5, -0.2), c, 0.22)
			ci.draw_line(Vector2(0.5, -0.2), Vector2(1.0, -0.46), Color.WHITE, 0.26)
			ci.draw_circle(Vector2(-0.85, 0.5), 0.2, l)
			ci.draw_circle(Vector2(0.9, -0.4), 0.16, c)
		"drone":
			ci.draw_line(Vector2(-0.85, -0.5), Vector2(0.85, -0.5), d, 0.13)
			ci.draw_line(Vector2(0, -0.5), Vector2(0, -0.2), d, 0.13)
			ci.draw_colored_polygon(Util.ellipse(Vector2(0, 0.15), 0.62, 0.42, 16), c)
			ci.draw_circle(Vector2(0, 0.12), 0.24, Color.WHITE)
			ci.draw_circle(Vector2(0.03, 0.14), 0.13, Color(0.1, 0.1, 0.25))
			ci.draw_line(Vector2(-0.35, 0.5), Vector2(-0.5, 0.8), d, 0.1)
			ci.draw_line(Vector2(0.35, 0.5), Vector2(0.5, 0.8), d, 0.1)
		_:
			ci.draw_circle(Vector2.ZERO, 0.7, c)


static func _passive(ci: CanvasItem, id: String, c: Color) -> void:
	var d := c.darkened(0.4)
	var l := c.lightened(0.5)
	match id:
		"cell":
			ci.draw_rect(Rect2(-0.55, -0.5, 1.1, 1.4), c)
			ci.draw_rect(Rect2(-0.22, -0.78, 0.44, 0.3), d)
			ci.draw_rect(Rect2(-0.55, -0.5, 1.1, 1.4), d, false, 0.09)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0.1, -0.3), Vector2(-0.3, 0.25), Vector2(0, 0.25), Vector2(-0.1, 0.75), Vector2(0.3, 0.1), Vector2(0, 0.1)]), Color.WHITE)
		"suit":
			var vest := PackedVector2Array([
				Vector2(-0.85, -0.6), Vector2(-0.38, -0.88), Vector2(0, -0.55), Vector2(0.38, -0.88), Vector2(0.85, -0.6), Vector2(0.7, 0.9), Vector2(-0.7, 0.9),
			])
			ci.draw_colored_polygon(vest, c)
			ci.draw_polyline(_closed(vest), d, 0.09)
			ci.draw_line(Vector2(0, -0.5), Vector2(0, 0.85), l, 0.1)
			ci.draw_rect(Rect2(-0.5, 0.0, 0.3, 0.3), l)
		"tank":
			ci.draw_circle(Vector2(0, -0.45), 0.42, c)
			ci.draw_circle(Vector2(0, 0.45), 0.42, c)
			ci.draw_rect(Rect2(-0.42, -0.45, 0.84, 0.9), c)
			ci.draw_rect(Rect2(-0.42, -0.1, 0.84, 0.3), l)
			ci.draw_rect(Rect2(-0.14, -1.0, 0.28, 0.3), d)
			ci.draw_line(Vector2(-0.34, -0.55), Vector2(-0.34, 0.5), Color(1, 1, 1, 0.6), 0.1)
		"repair":
			ci.draw_rect(Rect2(-0.28, -0.85, 0.56, 1.7), c)
			ci.draw_rect(Rect2(-0.85, -0.28, 1.7, 0.56), c)
			ci.draw_rect(Rect2(-0.18, -0.75, 0.18, 0.5), l)
			ci.draw_rect(Rect2(-0.28, -0.85, 0.56, 1.7), d, false, 0.08)
		"jet":
			var boot := PackedVector2Array([
				Vector2(-0.5, -0.85), Vector2(0.1, -0.85), Vector2(0.1, 0.05), Vector2(0.85, 0.35), Vector2(0.85, 0.8), Vector2(-0.5, 0.8),
			])
			ci.draw_colored_polygon(boot, c)
			ci.draw_polyline(_closed(boot), d, 0.08)
			ci.draw_rect(Rect2(-0.5, 0.55, 1.35, 0.25), d)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-0.55, 0.15), Vector2(-1.0, 0.4), Vector2(-0.55, 0.6)]), Color(1.0, 0.55, 0.2))
		"fan":
			for i in 4:
				var pts := PackedVector2Array()
				for k in 12:
					var a := TAU * float(k) / 12.0
					pts.append(Vector2(0.5, 0.0).rotated(float(i) * PI / 2.0 + 0.5) + Vector2(cos(a) * 0.5, sin(a) * 0.22).rotated(float(i) * PI / 2.0 + 0.8))
				ci.draw_colored_polygon(pts, c)
			ci.draw_circle(Vector2.ZERO, 0.2, Color.WHITE)
		"lens":
			ci.draw_line(Vector2(0.3, 0.3), Vector2(0.9, 0.9), Color(0.6, 0.42, 0.3), 0.26)
			ci.draw_circle(Vector2(-0.12, -0.12), 0.6, Color(c.r, c.g, c.b, 0.3))
			ci.draw_arc(Vector2(-0.12, -0.12), 0.6, 0.0, TAU, 24, c, 0.16)
			ci.draw_arc(Vector2(-0.12, -0.12), 0.35, 3.4, 4.5, 6, Color.WHITE, 0.09)
		"cloner":
			ci.draw_circle(Vector2(-0.3, 0.0), 0.58, Color(c.r, c.g, c.b, 0.75))
			ci.draw_circle(Vector2(0.3, 0.0), 0.58, Color(l.r, l.g, l.b, 0.7))
			ci.draw_arc(Vector2(-0.3, 0.0), 0.58, 0.0, TAU, 20, d, 0.08)
			ci.draw_arc(Vector2(0.3, 0.0), 0.58, 0.0, TAU, 20, d, 0.08)
		"field":
			ci.draw_arc(Vector2(0, 0.05), 0.55, 0.0, PI, 16, c, 0.36)
			ci.draw_rect(Rect2(-0.73, -0.75, 0.36, 0.8), c)
			ci.draw_rect(Rect2(0.37, -0.75, 0.36, 0.8), c)
			ci.draw_rect(Rect2(-0.73, -0.75, 0.36, 0.28), Color(0.9, 0.92, 1.0))
			ci.draw_rect(Rect2(0.37, -0.75, 0.36, 0.28), Color(0.9, 0.92, 1.0))
		"chip":
			for i in 3:
				var y := -0.35 + 0.35 * float(i)
				ci.draw_line(Vector2(-0.85, y), Vector2(-0.5, y), l, 0.1)
				ci.draw_line(Vector2(0.5, y), Vector2(0.85, y), l, 0.1)
			ci.draw_rect(Rect2(-0.55, -0.6, 1.1, 1.2), c)
			ci.draw_rect(Rect2(-0.3, -0.35, 0.6, 0.7), d)
			ci.draw_circle(Vector2(0, 0), 0.14, l)
		"screw":
			for p in [Vector2(-0.32, -0.32), Vector2(0.32, -0.32), Vector2(-0.32, 0.32), Vector2(0.32, 0.32)]:
				ci.draw_circle(p, 0.4, c)
			ci.draw_circle(Vector2.ZERO, 0.2, l)
			ci.draw_line(Vector2(0.1, 0.4), Vector2(0.5, 0.95), d, 0.13)
		"booster":
			for x in [-0.45, 0.15]:
				ci.draw_polyline(PackedVector2Array([Vector2(x, -0.7), Vector2(x + 0.6, 0.0), Vector2(x, 0.7)]), c if x < 0.0 else l, 0.34)
		"module":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-0.6, -0.8), Vector2(0.6, -0.8), Vector2(0.0, 0.0)]), Color(c.r, c.g, c.b, 0.55))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(-0.6, 0.8), Vector2(0.6, 0.8)]), c)
			ci.draw_rect(Rect2(-0.72, -0.95, 1.44, 0.18), d)
			ci.draw_rect(Rect2(-0.72, 0.77, 1.44, 0.18), d)
		"catalyst":
			var flask := PackedVector2Array([
				Vector2(-0.2, -0.9), Vector2(0.2, -0.9), Vector2(0.2, -0.3), Vector2(0.82, 0.72), Vector2(-0.82, 0.72), Vector2(-0.2, -0.3),
			])
			ci.draw_colored_polygon(flask, Color(0.85, 0.9, 1.0, 0.35))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-0.52, 0.22), Vector2(0.52, 0.22), Vector2(0.82, 0.72), Vector2(-0.82, 0.72)]), c)
			ci.draw_polyline(_closed(flask), l, 0.09)
			ci.draw_circle(Vector2(-0.12, 0.42), 0.09, Color.WHITE)
			ci.draw_circle(Vector2(0.2, 0.05), 0.07, Color.WHITE)
		"heal":
			ci.draw_circle(Vector2(-0.33, -0.25), 0.4, c)
			ci.draw_circle(Vector2(0.33, -0.25), 0.4, c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-0.7, -0.05), Vector2(0.7, -0.05), Vector2(0, 0.85)]), c)
			ci.draw_circle(Vector2(-0.4, -0.35), 0.1, Color(1, 1, 1, 0.7))
		_:
			ci.draw_circle(Vector2.ZERO, 0.7, c)


static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out
