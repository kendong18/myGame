class_name Hud
extends CanvasLayer
## 화면 UI: 경험치바, 시간, 보스 체력, 레벨업 선택, 보물상자, 일시정지, 결과 화면

signal choice_selected(index: int)
signal restart_pressed
signal resume_pressed
signal chest_closed

var _root: Control
var _xp_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _kill_label: Label
var _gold_label: Label
var _hp_label: Label
var _inv_label: Label
var _banner: Label
var _banner_t := 0.0

var _boss_box: Control
var _boss_name: Label
var _boss_bar: ProgressBar

var _levelup_overlay: Control
var _choice_buttons: Array[Button] = []
var _chest_overlay: Control
var _chest_rewards: VBoxContainer
var _chest_button: Button
var _pause_overlay: Control
var _pause_info: Label
var _over_overlay: Control
var _over_title: Label
var _over_info: Label
var _restart_button: Button
var _resume_button: Button


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_build_top_bar()
	_build_boss_bar()
	_build_levelup()
	_build_chest()
	_build_pause()
	_build_gameover()


func _make_theme() -> Theme:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "Noto Sans KR", "Apple SD Gothic Neo", "sans-serif"])
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 18

	var normal := _box(Color(0.2, 0.15, 0.36), Color(0.36, 0.29, 0.54), 8)
	var hover := _box(Color(0.32, 0.24, 0.5), Color(1.0, 0.8, 0.3), 8)
	var pressed := _box(Color(0.14, 0.1, 0.26), Color(1.0, 0.8, 0.3), 8)
	th.set_stylebox("normal", "Button", normal)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), Color(1.0, 0.8, 0.3), 8, 3))
	th.set_color("font_color", "Button", Color(0.95, 0.93, 1.0))
	th.set_color("font_hover_color", "Button", Color(1, 1, 1))
	return th


func _box(bg: Color, border: Color, radius: int, border_w: int = 2) -> StyleBoxFlat:
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


func _label(text: String, size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	return l


func _build_top_bar() -> void:
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.anchor_right = 1.0
	_xp_bar.offset_bottom = 20
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.04, 0.12, 0.85)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.62, 1.0)
	_xp_bar.add_theme_stylebox_override("background", bg)
	_xp_bar.add_theme_stylebox_override("fill", fill)
	_root.add_child(_xp_bar)

	_level_label = _label("LV 1", 16)
	_level_label.anchor_left = 1.0
	_level_label.anchor_right = 1.0
	_level_label.offset_left = -110
	_level_label.offset_right = -10
	_level_label.offset_top = -1
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_level_label)

	_time_label = _label("00:00", 34)
	_time_label.anchor_left = 0.5
	_time_label.anchor_right = 0.5
	_time_label.offset_left = -80
	_time_label.offset_right = 80
	_time_label.offset_top = 22
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_time_label)

	_kill_label = _label("처치 0", 18, Color(1, 0.85, 0.5))
	_kill_label.anchor_left = 1.0
	_kill_label.anchor_right = 1.0
	_kill_label.offset_left = -200
	_kill_label.offset_right = -14
	_kill_label.offset_top = 28
	_kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_kill_label)

	_gold_label = _label("골드 0", 18, Color(1, 0.9, 0.35))
	_gold_label.anchor_left = 1.0
	_gold_label.anchor_right = 1.0
	_gold_label.offset_left = -200
	_gold_label.offset_right = -14
	_gold_label.offset_top = 52
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_gold_label)

	_hp_label = _label("HP 100 / 100", 18, Color(1, 0.55, 0.6))
	_hp_label.offset_left = 14
	_hp_label.offset_top = 28
	_root.add_child(_hp_label)

	_inv_label = _label("", 14, Color(0.85, 0.83, 0.95))
	_inv_label.anchor_top = 1.0
	_inv_label.anchor_bottom = 1.0
	_inv_label.offset_left = 14
	_inv_label.offset_top = -56
	_inv_label.offset_bottom = -8
	_root.add_child(_inv_label)

	_banner = _label("", 40, Color(1, 0.85, 0.3))
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.offset_left = -400
	_banner.offset_right = 400
	_banner.offset_top = 150
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.visible = false
	_root.add_child(_banner)


func _build_boss_bar() -> void:
	_boss_box = Control.new()
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -260
	_boss_box.offset_right = 260
	_boss_box.offset_top = 66
	_boss_box.offset_bottom = 110
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	_root.add_child(_boss_box)
	_boss_name = _label("", 16, Color(1, 0.7, 0.7))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.anchor_right = 1.0
	_boss_box.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.max_value = 1.0
	_boss_bar.anchor_right = 1.0
	_boss_bar.offset_top = 26
	_boss_bar.offset_bottom = 42
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.02, 0.05, 0.9)
	bg.border_color = Color(0.5, 0.15, 0.2)
	bg.set_border_width_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.15, 0.22)
	_boss_bar.add_theme_stylebox_override("background", bg)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_box.add_child(_boss_bar)


func _make_overlay(dim: float = 0.6) -> Control:
	var o := ColorRect.new()
	o.color = Color(0.02, 0.01, 0.06, dim)
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.visible = false
	_root.add_child(o)
	return o


func _make_panel(parent: Control, width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	var sb := _box(Color(0.08, 0.06, 0.16, 0.96), Color(0.36, 0.29, 0.54), 14, 3)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box


func _build_levelup() -> void:
	_levelup_overlay = _make_overlay(0.55)
	var box := _make_panel(_levelup_overlay, 620)
	var title := _label("LEVEL UP!", 34, Color(1, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 76)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(_on_choice.bind(i))
		box.add_child(b)
		_choice_buttons.append(b)
	var hint := _label("클릭 또는 숫자키 1~3으로 선택", 14, Color(0.7, 0.66, 0.85))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)


func _build_chest() -> void:
	_chest_overlay = _make_overlay(0.6)
	var box := _make_panel(_chest_overlay, 600)
	var title := _label("보물상자!", 36, Color(1, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_chest_rewards = VBoxContainer.new()
	_chest_rewards.add_theme_constant_override("separation", 8)
	box.add_child(_chest_rewards)
	_chest_button = Button.new()
	_chest_button.text = "확인 (Enter)"
	_chest_button.pressed.connect(func() -> void: chest_closed.emit())
	box.add_child(_chest_button)


func _build_pause() -> void:
	_pause_overlay = _make_overlay(0.6)
	var box := _make_panel(_pause_overlay, 520)
	var title := _label("일시정지", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_pause_info = _label("", 18, Color(0.9, 0.88, 1.0))
	box.add_child(_pause_info)
	_resume_button = Button.new()
	_resume_button.text = "계속하기 (ESC)"
	_resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	box.add_child(_resume_button)
	var restart := Button.new()
	restart.text = "다시 시작"
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	box.add_child(restart)


func _build_gameover() -> void:
	_over_overlay = _make_overlay(0.7)
	var box := _make_panel(_over_overlay, 560)
	_over_title = _label("", 38, Color(1, 0.4, 0.45))
	_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_over_title)
	_over_info = _label("", 19, Color(0.92, 0.9, 1.0))
	box.add_child(_over_info)
	_restart_button = Button.new()
	_restart_button.text = "다시 하기"
	_restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	box.add_child(_restart_button)


func _process(delta: float) -> void:
	if _banner_t > 0.0:
		_banner_t -= delta
		_banner.modulate.a = clampf(_banner_t / 0.6, 0.0, 1.0)
		if _banner_t <= 0.0:
			_banner.visible = false


func _on_choice(index: int) -> void:
	choice_selected.emit(index)


# ── 외부에서 호출 ───────────────────────────
func update_info(player: Player, time: float, kills: int, gold: int) -> void:
	var need := GameData.xp_for_level(player.level)
	_xp_bar.max_value = need
	_xp_bar.value = player.xp
	_level_label.text = "LV %d" % player.level
	_time_label.text = Util.fmt_time(time)
	_kill_label.text = "처치 %d" % kills
	_gold_label.text = "골드 %d" % gold
	_hp_label.text = "HP %d / %d" % [ceili(maxf(player.hp, 0.0)), int(player.max_hp)]


func set_inventory(text: String) -> void:
	_inv_label.text = text


func set_boss(boss_name: String, ratio: float) -> void:
	_boss_box.visible = true
	_boss_name.text = boss_name
	_boss_bar.value = clampf(ratio, 0.0, 1.0)


func clear_boss() -> void:
	_boss_box.visible = false


func show_banner(text: String, color: Color = Color(1, 0.85, 0.3)) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.modulate.a = 1.0
	_banner.visible = true
	_banner_t = 2.5


func show_levelup(choices: Array) -> void:
	for i in _choice_buttons.size():
		var b := _choice_buttons[i]
		if i < choices.size():
			var c: Dictionary = choices[i]
			b.text = "[%d]  %s\n       %s" % [i + 1, c.title, c.desc]
			b.visible = true
		else:
			b.visible = false
	_levelup_overlay.visible = true
	_choice_buttons[0].grab_focus()


func hide_levelup() -> void:
	_levelup_overlay.visible = false


func show_chest(rewards: Array) -> void:
	for ch in _chest_rewards.get_children():
		ch.queue_free()
	for r: Dictionary in rewards:
		var evo: bool = r.get("evo", false)
		var row := PanelContainer.new()
		var sb := _box(Color(0.45, 0.12, 0.35, 0.5) if evo else Color(0.4, 0.3, 0.08, 0.45),
			Color(1.0, 0.5, 0.85) if evo else Color(0.75, 0.6, 0.2), 8)
		row.add_theme_stylebox_override("panel", sb)
		var col := VBoxContainer.new()
		row.add_child(col)
		var t := _label(("★ 진화!  " if evo else "") + str(r.title), 20, Color(1, 0.7, 0.92) if evo else Color(1, 0.92, 0.6))
		col.add_child(t)
		var d := _label(str(r.desc), 15, Color(0.88, 0.86, 0.96))
		col.add_child(d)
		_chest_rewards.add_child(row)
	_chest_overlay.visible = true
	_chest_button.grab_focus()


func hide_chest() -> void:
	_chest_overlay.visible = false


func show_pause(info: String) -> void:
	_pause_info.text = info
	_pause_overlay.visible = true
	_resume_button.grab_focus()


func hide_pause() -> void:
	_pause_overlay.visible = false


func show_gameover(won: bool, info: String) -> void:
	_over_title.text = "승리!" if won else "사망했습니다"
	_over_title.add_theme_color_override("font_color", Color(1, 0.88, 0.4) if won else Color(1, 0.4, 0.45))
	_over_info.text = info
	_over_overlay.visible = true
	_restart_button.grab_focus()
