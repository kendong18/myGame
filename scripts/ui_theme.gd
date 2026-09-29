class_name UiTheme
extends RefCounted
## 모든 화면이 함께 쓰는 UI 스타일

static var _theme: Theme = null


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "Noto Sans KR", "Apple SD Gothic Neo", "sans-serif"])
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 18

	th.set_stylebox("normal", "Button", box(Color(0.2, 0.15, 0.36), Color(0.36, 0.29, 0.54), 8))
	th.set_stylebox("hover", "Button", box(Color(0.32, 0.24, 0.5), Color(1.0, 0.8, 0.3), 8))
	th.set_stylebox("pressed", "Button", box(Color(0.14, 0.1, 0.26), Color(1.0, 0.8, 0.3), 8))
	th.set_stylebox("disabled", "Button", box(Color(0.13, 0.11, 0.2), Color(0.25, 0.22, 0.34), 8))
	th.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), Color(1.0, 0.8, 0.3), 8, 3))
	th.set_color("font_color", "Button", Color(0.95, 0.93, 1.0))
	th.set_color("font_hover_color", "Button", Color(1, 1, 1))
	th.set_color("font_disabled_color", "Button", Color(0.5, 0.48, 0.6))
	_theme = th
	return th


static func box(bg: Color, border: Color, radius: int, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func label(text: String, size: int, color: Color = Color.WHITE, outline: int = 4) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", outline)
	return l


## 가운데에 놓이는 패널을 만들고, 내용을 넣을 VBoxContainer 를 반환
static func centered_panel(parent: Control, width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	var sb := box(Color(0.08, 0.06, 0.16, 0.96), Color(0.36, 0.29, 0.54), 14, 3)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	return vbox
