class_name ItemSlot
extends Control
## 아이콘 한 칸: 무기나 아이템의 그림, 레벨, 진화 표시. 게임 화면 아래쪽과 일시정지 화면에서 쓴다.
## info: {id, level, max, evolved, ready, name, detail}. id 가 비어 있으면 빈 칸이다.

signal picked(slot: ItemSlot)

var info: Dictionary = {}
var slot_size := 44.0
var is_weapon := true
var interactive := false     # 일시정지 화면에서는 선택할 수 있다
var _t := 0.0


func setup(p_info: Dictionary, weapon: bool, sz: float = 44.0, can_focus: bool = false) -> ItemSlot:
	info = p_info
	is_weapon = weapon
	slot_size = sz
	interactive = can_focus and str(info.get("id", "")) != ""
	custom_minimum_size = Vector2(sz, sz)
	mouse_filter = Control.MOUSE_FILTER_PASS if interactive else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
	set_process(bool(info.get("ready", false)) or interactive)
	queue_redraw()
	if interactive:
		mouse_entered.connect(func() -> void: picked.emit(self))
		focus_entered.connect(func() -> void: picked.emit(self))
	return self


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var id := str(info.get("id", ""))
	var r := Rect2(Vector2.ZERO, Vector2(slot_size, slot_size))
	if id == "":
		draw_rect(r, Color(0.08, 0.07, 0.16, 0.45), true)
		draw_rect(r, Color(0.3, 0.27, 0.45, 0.5), false, 1.5)
		return
	var evolved := bool(info.get("evolved", false))
	var ready := bool(info.get("ready", false))
	var accent := ItemIcons.main_color(id)
	var bg := Color(0.1, 0.08, 0.2, 0.88)
	draw_rect(r, bg, true)
	draw_rect(Rect2(2, 2, slot_size - 4, slot_size - 4), Color(accent.r, accent.g, accent.b, 0.12 if not evolved else 0.28), true)
	var border := accent.darkened(0.15) if is_weapon else Color(0.5, 0.6, 0.75)
	var bw := 2.0
	if evolved:
		border = Color(1.0, 0.85, 0.3)
		bw = 3.0
	if evolved:
		draw_circle(r.get_center(), slot_size * 0.5, Color(1.0, 0.85, 0.3, 0.18))
	draw_rect(r, border, false, bw)
	ItemIcons.draw(self, id, Vector2(slot_size, slot_size) / 2.0 + Vector2(0, -1), slot_size * 0.34)

	var font := UiTheme.get_theme().default_font
	var fs := int(slot_size * 0.28)
	var lv := int(info.get("level", 0))
	var mx := int(info.get("max", 0))
	var label := ""
	var col := Color.WHITE
	if evolved:
		label = ""
	elif mx > 0 and lv >= mx:
		label = "MAX"
		col = Color(1.0, 0.85, 0.3)
	elif lv > 0:
		label = str(lv)
	if label != "":
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(slot_size - w - 3, slot_size - 3)
		draw_string_outline(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.9))
		draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	if evolved:
		_star(Vector2(slot_size - 9, 9), 7.0, Color(1.0, 0.88, 0.3))
	if ready:
		var pulse := 0.5 + 0.5 * sin(_t * 6.0)
		draw_rect(r.grow(2.0), Color(1.0, 0.85, 0.3, 0.35 + 0.6 * pulse), false, 3.0)
		_star(Vector2(slot_size - 9, 9), 6.0 + 2.0 * pulse, Color(1.0, 0.95, 0.5))
	if interactive and has_focus():
		draw_rect(r.grow(3.0), Color(1, 1, 1, 0.95), false, 2.5)
	elif interactive and get_global_rect().has_point(get_global_mouse_position()):
		draw_rect(r.grow(2.0), Color(1, 1, 1, 0.6), false, 2.0)


func _star(p: Vector2, sz: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + TAU * float(i) / 10.0
		var rr := sz if i % 2 == 0 else sz * 0.45
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(0.5, 0.3, 0.0, 0.8), 1.0)
