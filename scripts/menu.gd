extends Node2D
## 타이틀 / 캐릭터 선택 / 강화 상점 / 게임 방법 / 설정 / 조작 키 / 크레딧 화면

const GAME_SCENE := "res://scenes/main.tscn"

var _bg: Background
var _cam: Camera2D
var _t := 0.0
var _walkers: Array[Enemy] = []
var _root: Control
var _screens: Dictionary = {}
var _title_info: Label
var _select_grid: GridContainer
var _select_gold: Label
var _shop_grid: GridContainer
var _shop_gold: Label
var _current := "title"
var _keys_grid: VBoxContainer
var _keys_hint: Label
var _listening: Dictionary = {}     # 키 바꾸는 중일 때 {action, slot}
var _licenses_text: RichTextLabel
var _licenses_built := false

# 뒤로 갈 때 돌아가는 화면 (없으면 타이틀)
const PARENT := {"keys": "settings", "licenses": "credits"}


func _ready() -> void:
	_build_background()
	var ui := CanvasLayer.new()
	add_child(ui)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.get_theme()
	ui.add_child(_root)

	_build_title()
	_build_select()
	_build_shop()
	_build_howto()
	_build_settings()
	_build_keys()
	_build_credits()
	_build_licenses()
	Sfx.play_music("menu")
	var first := "title"
	if SaveData.pending_screen != "":
		first = SaveData.pending_screen
		SaveData.pending_screen = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screen="):
			first = a.substr(9)    # 테스트 전용: 시작 화면 지정
	_show(first)


# ─────────────────────────────────────────────
# 배경: 밤의 들판을 천천히 흐르고, 몬스터들이 지나간다
# ─────────────────────────────────────────────
func _build_background() -> void:
	_bg = Background.new()
	add_child(_bg)
	_cam = Camera2D.new()
	add_child(_cam)
	var kinds := ["moth", "jelly", "drone", "bubble", "hound", "turret", "cube"]
	var size := get_viewport_rect().size
	for i in 16:
		var e := Enemy.new()
		e.setup(kinds[randi() % kinds.size()], 1.0)
		e.position = Vector2(randf_range(-100.0, size.x + 100.0), randf_range(80.0, size.y - 60.0))
		var dir := -1.0 if randf() < 0.5 else 1.0
		e.straight = Vector2(dir * randf_range(15.0, 45.0), 0.0)
		e.z_index = 0
		add_child(e)
		_walkers.append(e)


func _process(delta: float) -> void:
	_t += delta
	var size := get_viewport_rect().size
	_cam.position = size / 2.0 + Vector2(_t * 8.0, sin(_t * 0.2) * 20.0)
	_bg.cam_pos = _cam.position
	_bg.view_size = size
	_bg.t = _t
	_bg.queue_redraw()
	for e in _walkers:
		e.position += e.straight * delta
		e.scale = Vector2(signf(e.straight.x), 1.0 + 0.07 * sin(_t * 9.0 + e.wobble))
		# 화면 밖으로 나가면 반대편에서 다시 등장 (카메라가 움직이므로 카메라 기준)
		var rel := e.position.x - _cam.position.x
		if rel < -size.x * 0.5 - 120.0:
			e.position.x = _cam.position.x + size.x * 0.5 + 100.0
		elif rel > size.x * 0.5 + 120.0:
			e.position.x = _cam.position.x - size.x * 0.5 - 100.0


# ─────────────────────────────────────────────
# 공통
# ─────────────────────────────────────────────
func _show(screen: String) -> void:
	_current = screen
	_listening.clear()
	for k: String in _screens:
		(_screens[k] as Control).visible = (k == screen)
	match screen:
		"title":
			_refresh_title()
		"select":
			_rebuild_select()
		"shop":
			_rebuild_shop()
		"keys":
			_rebuild_keys()
		"licenses":
			_fill_licenses()
	_focus_first.call_deferred(screen)


## 게임패드와 키보드로 조작할 수 있도록 화면이 바뀔 때 첫 버튼에 포커스를 준다
func _focus_first(screen: String) -> void:
	if not _screens.has(screen):
		return
	var b := _find_button(_screens[screen])
	if b != null:
		b.grab_focus()


func _find_button(node: Node, focus_id: String = "") -> Button:
	for c in node.get_children():
		if c is Button and c.is_visible_in_tree() and not (c as Button).disabled:
			if focus_id == "" or str(c.get_meta("focus_id", "")) == focus_id:
				return c
		var r := _find_button(c, focus_id)
		if r != null:
			return r
	return null


## 구매나 해금 뒤에 화면을 다시 만들어도 같은 항목에 포커스가 남도록 한다
func _focus_item(screen: String, focus_id: String) -> void:
	var b := _find_button(_screens[screen], focus_id)
	if b == null:
		b = _find_button(_screens[screen])
	if b != null:
		b.grab_focus()


func _clear_children(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func _new_screen(screen_name: String, dim: float) -> Control:
	var c := ColorRect.new()
	c.color = Color(0.02, 0.01, 0.06, dim)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	_root.add_child(c)
	_screens[screen_name] = c
	return c


func _button(text: String, on_press: Callable, primary: bool = false, min_w: float = 280.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 52)
	b.add_theme_font_size_override("font_size", 20)
	if primary:
		b.add_theme_stylebox_override("normal", UiTheme.box(Color(0.75, 0.5, 0.12), Color(1.0, 0.85, 0.4), 8))
		b.add_theme_stylebox_override("hover", UiTheme.box(Color(0.9, 0.62, 0.16), Color(1.0, 0.95, 0.6), 8))
		b.add_theme_color_override("font_color", Color(0.15, 0.08, 0.0))
		b.add_theme_color_override("font_hover_color", Color(0.1, 0.05, 0.0))
	b.pressed.connect(func() -> void:
		Sfx.play("click")
		on_press.call())
	return b


## 창 높이에 맞춰 줄어드는 스크롤 영역 (작은 화면에서도 아래 버튼이 잘리지 않게)
func _scroll_area(content: Control, reserved: float) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	sc.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y - reserved, 220.0, 560.0))
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	return sc


func _go_back() -> void:
	_show(str(PARENT.get(_current, "title")))


func _unhandled_input(event: InputEvent) -> void:
	# ESC 또는 게임패드 B 로 이전 화면으로 돌아간다
	if event.is_action_pressed("ui_cancel") and _current != "title":
		get_viewport().set_input_as_handled()
		Sfx.play("click")
		_go_back()


## 조작 키를 바꾸는 중에는 다음에 누른 키를 받아서 등록한다
func _input(event: InputEvent) -> void:
	if _listening.is_empty() or not (event is InputEventKey):
		return
	var ke := event as InputEventKey
	if not ke.pressed or ke.echo:
		return
	get_viewport().set_input_as_handled()
	var code := int(ke.physical_keycode)
	if code == KEY_ESCAPE:
		_listening.clear()
		_rebuild_keys()
		return
	if code in InputSetup.RESERVED:
		Sfx.play("hurt")
		_keys_hint.text = "이 키는 다른 기능에 쓰여서 지정할 수 없습니다. 다른 키를 눌러 주세요."
		return
	InputSetup.set_key(str(_listening.action), int(_listening.slot), code)
	_listening.clear()
	Sfx.play("select")
	_rebuild_keys()
	_focus_first.call_deferred("keys")


# ─────────────────────────────────────────────
# 타이틀
# ─────────────────────────────────────────────
func _build_title() -> void:
	var s := _new_screen("title", 0.35)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)

	var logo := UiTheme.label(GameData.TITLE_EN, 78, Color(1.0, 0.92, 0.55), 14)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.62))
	logo.add_theme_constant_override("line_spacing", -8)
	v.add_child(logo)
	var sub := UiTheme.label("%s  ·  %s" % [T.t(GameData.TITLE), T.t(GameData.SUBTITLE)], 22, Color(0.75, 0.85, 1.0), 3)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(Control.new())

	for entry in [
		["게임 시작", func() -> void: _show("select"), true],
		["강화 상점", func() -> void: _show("shop"), false],
		["게임 방법", func() -> void: _show("howto"), false],
		["설정", func() -> void: _show("settings"), false],
		["크레딧", func() -> void: _show("credits"), false],
		["종료", func() -> void: get_tree().quit(), false],
	]:
		var b := _button(entry[0], entry[1], entry[2])
		var wrap := CenterContainer.new()
		wrap.add_child(b)
		v.add_child(wrap)

	_title_info = UiTheme.label("", 16, Color(1.0, 0.9, 0.5), 3)
	_title_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(Control.new())
	v.add_child(_title_info)


func _refresh_title() -> void:
	var b: Dictionary = SaveData.best
	var text := T.f("보유 골드  %d", [SaveData.gold])
	if SaveData.runs > 0:
		text += "\n" + T.f("최고 기록  %s  ·  최다 처치  %d  ·  승리 %d회", [Util.fmt_time(float(b.time)), int(b.kills), SaveData.wins])
	_title_info.text = text


# ─────────────────────────────────────────────
# 캐릭터 선택
# ─────────────────────────────────────────────
func _build_select() -> void:
	var s := _new_screen("select", 0.8)
	var v := UiTheme.centered_panel(s, 940.0)
	var title := UiTheme.label("캐릭터 선택", 34, Color(1, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_select_gold = UiTheme.label("", 18, Color(1, 0.9, 0.35), 3)
	_select_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_select_gold)
	_select_grid = GridContainer.new()
	_select_grid.columns = 3
	_select_grid.add_theme_constant_override("h_separation", 12)
	_select_grid.add_theme_constant_override("v_separation", 12)
	v.add_child(_scroll_area(_select_grid, 300.0))
	var back := _button("뒤로", _go_back, false, 160.0)
	var wrap := CenterContainer.new()
	wrap.add_child(back)
	v.add_child(wrap)


func _rebuild_select(focus_id: String = "") -> void:
	_select_gold.text = T.f("보유 골드  %d", [SaveData.gold])
	_clear_children(_select_grid)
	for ch: Dictionary in GameData.CHARACTERS:
		_select_grid.add_child(_make_char_card(ch))
	if focus_id != "":
		_focus_item.call_deferred("select", focus_id)


func _make_char_card(ch: Dictionary) -> Control:
	var unlocked := SaveData.is_unlocked(ch.id)
	var selected: bool = SaveData.selected_char == ch.id
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 0)
	var border := Color(1.0, 0.8, 0.3) if selected else Color(0.3, 0.24, 0.46)
	card.add_theme_stylebox_override("panel", UiTheme.box(Color(0.12, 0.09, 0.22), border, 10, 3 if selected else 2))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var prev := HeroPreview.new()
	prev.char_id = ch.id
	prev.locked = not unlocked
	var pw := CenterContainer.new()
	pw.add_child(prev)
	v.add_child(pw)

	var nm := UiTheme.label(T.t(str(ch.name)) if unlocked else "???", 20, Color(1, 0.95, 0.85), 3)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var wname: String = T.t(str(GameData.WEAPONS[ch.weapon].name))
	var wl := UiTheme.label(T.f("시작 무기  %s", [wname]), 15, Color(1, 0.85, 0.4), 2)
	wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(wl)
	var desc := UiTheme.label(T.t(str(ch.desc)), 14, Color(0.78, 0.75, 0.92), 2)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(240, 40)
	v.add_child(desc)

	var b: Button
	if unlocked:
		b = _button("선택", func() -> void: _start_game(str(ch.id)), true, 200.0)
	else:
		var cost := int(ch.cost)
		b = _button(T.f("해금  %d G", [cost]), func() -> void:
			if SaveData.unlock_char(ch):
				Sfx.play("chest")
				_rebuild_select(str(ch.id)), false, 200.0)
		b.disabled = SaveData.gold < cost
	b.custom_minimum_size = Vector2(200, 42)
	b.set_meta("focus_id", str(ch.id))
	var bw := CenterContainer.new()
	bw.add_child(b)
	v.add_child(bw)
	return card


func _start_game(char_id: String) -> void:
	SaveData.selected_char = char_id
	SaveData.save()
	Sfx.play("select")
	Sfx.stop_music()
	get_tree().change_scene_to_file(GAME_SCENE)


# ─────────────────────────────────────────────
# 강화 상점
# ─────────────────────────────────────────────
func _build_shop() -> void:
	var s := _new_screen("shop", 0.8)
	var v := UiTheme.centered_panel(s, 940.0)
	var title := UiTheme.label("강화 상점", 34, Color(1, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var hint := UiTheme.label("모은 골드로 영구 능력치를 올립니다. 모든 판에 적용됩니다.", 15, Color(0.75, 0.72, 0.9), 2)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	_shop_gold = UiTheme.label("", 22, Color(1, 0.9, 0.35), 3)
	_shop_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_shop_gold)
	_shop_grid = GridContainer.new()
	_shop_grid.columns = 3
	_shop_grid.add_theme_constant_override("h_separation", 10)
	_shop_grid.add_theme_constant_override("v_separation", 10)
	v.add_child(_scroll_area(_shop_grid, 340.0))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_button("전체 환불", func() -> void:
		SaveData.refund_all()
		_rebuild_shop(), false, 160.0))
	row.add_child(_button("뒤로", _go_back, false, 160.0))
	v.add_child(row)


func _rebuild_shop(focus_id: String = "") -> void:
	_shop_gold.text = T.f("보유 골드  %d", [SaveData.gold])
	_clear_children(_shop_grid)
	for item: Dictionary in GameData.SHOP:
		_shop_grid.add_child(_make_shop_card(item))
	if focus_id != "":
		_focus_item.call_deferred("shop", focus_id)


func _make_shop_card(item: Dictionary) -> Control:
	var lv := SaveData.upgrade_level(item.id)
	var maxed := lv >= int(item.max)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 0)
	card.add_theme_stylebox_override("panel", UiTheme.box(Color(0.12, 0.09, 0.22), Color(0.3, 0.24, 0.46), 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	v.add_child(UiTheme.label(T.t(str(item.name)), 19, Color(1, 0.95, 0.85), 2))
	v.add_child(UiTheme.label(T.t(str(item.desc)), 14, Color(0.78, 0.75, 0.92), 2))
	var pips := ""
	for i in int(item.max):
		pips += "■ " if i < lv else "□ "
	v.add_child(UiTheme.label(pips, 16, Color(1, 0.85, 0.35), 2))
	var b: Button
	if maxed:
		b = _button("최대", func() -> void: pass, false, 100.0)
		b.disabled = true
	else:
		var cost := GameData.shop_cost(item, lv)
		b = _button("%d G" % cost, func() -> void:
			if SaveData.buy_upgrade(item):
				Sfx.play("select")
				_rebuild_shop(str(item.id)), false, 100.0)
		b.disabled = SaveData.gold < cost
	b.custom_minimum_size = Vector2(0, 36)
	b.add_theme_font_size_override("font_size", 16)
	b.set_meta("focus_id", str(item.id))
	v.add_child(b)
	return card


# ─────────────────────────────────────────────
# 게임 방법 / 설정
# ─────────────────────────────────────────────
func _build_howto() -> void:
	var s := _new_screen("howto", 0.8)
	var v := UiTheme.centered_panel(s, 800.0)
	var title := UiTheme.label("게임 방법", 34, Color(1, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var lines: Array = [
		["이동", "WASD 또는 방향키 (게임패드 왼쪽 스틱)"],
		["대시", "Space 또는 Shift (게임패드 A): 짧게 돌진하며 잠깐 무적이 됩니다. 적 사이를 빠져나갈 때 쓰세요."],
		["공격", "무기가 자동으로 공격합니다. 피하는 데 집중하세요."],
		["속성", "무기에는 열, 냉각, 전기, 젤, 플라즈마 속성이 있습니다. 맞은 적에게는 속성 상태가 붙습니다."],
		["반응", "이미 상태가 붙은 적에게 다른 속성을 맞히면 반응이 터집니다. 아래는 반응 목록입니다."],
	]
	for key: String in GameData.REACTIONS:
		var info: Dictionary = GameData.REACTIONS[key]
		lines.append(["   · " + T.t(str(info.name)), T.t(str(info.desc))])
	lines.append_array([
		["경험치", "적이 떨어뜨린 보석을 모아 레벨업합니다."],
		["레벨업", "새 무기, 무기 강화, 아이템 중 하나를 고릅니다. (숫자키 1~3)"],
		["진화", "무기를 8레벨까지 올리고 짝이 되는 아이템을 가진 채 보급 상자를 열면 진화합니다."],
		["보급 상자", "금빛 테두리의 엘리트 적과 보스가 떨어뜨립니다."],
		["보급 캡슐", "부수면 배터리, 자석, 펄스탄, 동전이 나옵니다."],
		["목표", "10분에 나타나는 폭주 메인 컴퓨터를 쓰러뜨리면 승리합니다."],
		["기타", "ESC 또는 P: 일시정지 / F11: 전체 화면"],
	])
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	for l in lines:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var k := UiTheme.label(l[0], 17, Color(1, 0.85, 0.4), 2)
		k.custom_minimum_size = Vector2(150, 0)
		row.add_child(k)
		var t := UiTheme.label(l[1], 16, Color(0.92, 0.9, 1.0), 2)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(560, 0)
		row.add_child(t)
		list.add_child(row)
	v.add_child(_scroll_area(list, 250.0))
	var wrap := CenterContainer.new()
	wrap.add_child(_button("뒤로", _go_back, false, 160.0))
	v.add_child(wrap)


func _build_settings() -> void:
	var s := _new_screen("settings", 0.8)
	var v := UiTheme.centered_panel(s, 560.0)
	var title := UiTheme.label("설정", 34, Color(1, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sp := SettingsPanel.new()
	sp.show_keys_button = true
	sp.show_language = true
	sp.language_changed.connect(func() -> void:
		SaveData.pending_screen = "settings"
		get_tree().reload_current_scene.call_deferred())
	sp.keys_pressed.connect(func() -> void: _show("keys"))
	v.add_child(sp)
	var wrap := CenterContainer.new()
	wrap.add_child(_button("뒤로", _go_back, false, 160.0))
	v.add_child(wrap)


# ─────────────────────────────────────────────
# 조작 키 설정
# ─────────────────────────────────────────────
func _build_keys() -> void:
	var s := _new_screen("keys", 0.8)
	var v := UiTheme.centered_panel(s, 680.0)
	var title := UiTheme.label("조작 키 설정", 34, Color(1, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_keys_hint = UiTheme.label("", 15, Color(0.75, 0.85, 1.0), 2)
	_keys_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keys_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_keys_hint.custom_minimum_size = Vector2(600, 40)
	v.add_child(_keys_hint)
	_keys_grid = VBoxContainer.new()
	_keys_grid.add_theme_constant_override("separation", 8)
	v.add_child(_keys_grid)
	var pad := UiTheme.label("게임패드: 왼쪽 스틱 이동 / A 또는 RB 대시 / Start 일시정지 (고정)", 14, Color(0.7, 0.68, 0.85), 2)
	pad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pad)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_button("기본값으로", func() -> void:
		InputSetup.reset_defaults()
		_rebuild_keys(), false, 180.0))
	row.add_child(_button("뒤로", _go_back, false, 160.0))
	v.add_child(row)


func _rebuild_keys() -> void:
	_keys_hint.text = "바꾸고 싶은 칸을 누른 뒤 새 키를 누르세요. (ESC: 취소)  이미 쓰는 키를 고르면 두 칸이 서로 바뀝니다."
	_clear_children(_keys_grid)
	for action: String in InputSetup.ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var name_label := UiTheme.label(str(InputSetup.ACTION_NAMES[action]), 18, Color(0.95, 0.93, 1.0), 2)
		name_label.custom_minimum_size = Vector2(220, 0)
		row.add_child(name_label)
		var keys := InputSetup.keys_for(action)
		for slot in 2:
			var b := Button.new()
			var listening: bool = not _listening.is_empty() and str(_listening.action) == action and int(_listening.slot) == slot
			b.text = "키를 누르세요..." if listening else InputSetup.key_label(int(keys[slot]))
			b.custom_minimum_size = Vector2(170, 42)
			b.pressed.connect(func() -> void:
				Sfx.play("click")
				_listening = {"action": action, "slot": slot}
				_rebuild_keys())
			row.add_child(b)
		_keys_grid.add_child(row)


# ─────────────────────────────────────────────
# 크레딧 / 라이선스
# ─────────────────────────────────────────────
func _build_credits() -> void:
	var s := _new_screen("credits", 0.8)
	var v := UiTheme.centered_panel(s, 720.0)
	var title := UiTheme.label("크레딧", 34, Color(1, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var lines: Array = [
		[T.t(GameData.TITLE) + "  " + T.t("(임시 제목)"), ""],
		["개발", "kendong18"],
		["글꼴", "주아(Jua) — 우아한형제들 · SIL Open Font License 1.1"],
		["게임 엔진", "Godot Engine — MIT 라이선스"],
		["그림 · 소리", "이 게임의 그림, 효과음, 음악은 게임 안에서 직접 만든 것입니다."],
	]
	for l in lines:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		if str(l[1]) == "":
			var t := UiTheme.label(str(l[0]), 22, Color(1, 0.95, 0.75), 3)
			t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(t)
		else:
			var k := UiTheme.label(str(l[0]), 17, Color(1, 0.85, 0.4), 2)
			k.custom_minimum_size = Vector2(120, 0)
			row.add_child(k)
			var t := UiTheme.label(str(l[1]), 16, Color(0.92, 0.9, 1.0), 2)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			t.custom_minimum_size = Vector2(540, 0)
			row.add_child(t)
		v.add_child(row)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	buttons.add_child(_button("라이선스 전문", func() -> void: _show("licenses"), false, 200.0))
	buttons.add_child(_button("뒤로", _go_back, false, 160.0))
	v.add_child(buttons)


func _build_licenses() -> void:
	var s := _new_screen("licenses", 0.85)
	var v := UiTheme.centered_panel(s, 900.0)
	var title := UiTheme.label("라이선스 전문", 30, Color(1, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_licenses_text = RichTextLabel.new()
	_licenses_text.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y - 250.0, 240.0, 520.0))
	_licenses_text.focus_mode = Control.FOCUS_ALL
	_licenses_text.scroll_active = true
	_licenses_text.add_theme_font_size_override("normal_font_size", 14)
	_licenses_text.add_theme_font_size_override("bold_font_size", 16)
	v.add_child(_licenses_text)
	var wrap := CenterContainer.new()
	wrap.add_child(_button("뒤로", _go_back, false, 160.0))
	v.add_child(wrap)


## 처음 열 때 한 번만 채운다: 글꼴 라이선스, 엔진 라이선스, 엔진이 쓰는 제3자 구성 요소
func _fill_licenses() -> void:
	if _licenses_built:
		return
	_licenses_built = true
	var t := _licenses_text
	t.clear()
	t.push_bold()
	t.add_text(T.t("주아 (Jua)") + "\n")
	t.pop()
	var ofl_path := "res://assets/fonts/OFL.txt"
	if FileAccess.file_exists(ofl_path):
		t.add_text(FileAccess.get_file_as_string(ofl_path) + "\n\n")
	else:
		t.add_text("Copyright 2018 The Jua Project Authors. SIL Open Font License 1.1 (http://scripts.sil.org/OFL)\n\n")
	t.push_bold()
	t.add_text("Godot Engine\n")
	t.pop()
	t.add_text(Engine.get_license_text() + "\n\n")
	t.push_bold()
	t.add_text(T.t("Godot 엔진이 사용하는 제3자 구성 요소") + "\n")
	t.pop()
	for comp: Dictionary in Engine.get_copyright_info():
		t.add_text("• %s\n" % comp.name)
		for part: Dictionary in comp.parts:
			t.add_text("    %s — %s\n" % [", ".join(part.copyright), part.license])
	t.add_text("\n")
	var infos: Dictionary = Engine.get_license_info()
	for license_name: String in infos:
		t.push_bold()
		t.add_text("%s\n" % license_name)
		t.pop()
		t.add_text(str(infos[license_name]) + "\n\n")
