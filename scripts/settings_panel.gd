class_name SettingsPanel
extends VBoxContainer
## 설정 항목 모음: 음량, 피해 숫자, 화면 흔들림, 화면 모드, 창 크기, 수직 동기화.
## 타이틀과 일시정지 화면이 함께 쓴다. show_keys_button 이 true 면 조작 키 설정 버튼도 보인다.

signal keys_pressed
signal language_changed

var show_keys_button := false
var compact := false            # true 면 자주 쓰는 항목만 보여 준다 (일시정지 화면용)
var show_language := false      # 메뉴에서만 보인다 (게임 중에 바꾸면 게임이 다시 시작되므로)
var _size_option: OptionButton


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_add_slider("효과음", "sfx")
	_add_slider("음악", "music")
	_add_toggle("피해 숫자 표시", "damage_numbers")
	_add_toggle("화면 흔들림", "screen_shake")
	_add_toggle("전체 화면 (F11)", "fullscreen")
	if not compact:
		_add_size_option()
		_add_toggle("수직 동기화", "vsync")
	if show_language:
		_add_language_option()
	if show_keys_button:
		var b := Button.new()
		b.text = "조작 키 설정"
		b.custom_minimum_size = Vector2(0, 42)
		b.pressed.connect(func() -> void:
			Sfx.play("click")
			keys_pressed.emit())
		add_child(b)


func _row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := UiTheme.label(title, 17, Color(0.92, 0.9, 1.0), 2)
	l.custom_minimum_size = Vector2(150, 0)
	row.add_child(l)
	add_child(row)
	return row


func _add_slider(title: String, key: String) -> void:
	var row := _row(title)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(SaveData.settings[key])
	s.custom_minimum_size = Vector2(220, 24)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void:
		SaveData.settings[key] = v
		Sfx.apply_settings()
		SaveData.save()
		Sfx.play("click"))
	row.add_child(s)


func _add_toggle(title: String, key: String) -> void:
	var row := _row(title)
	var c := CheckButton.new()
	c.button_pressed = bool(SaveData.settings[key])
	c.toggled.connect(func(on: bool) -> void:
		SaveData.settings[key] = on
		SaveData.save()
		if key == "fullscreen" or key == "vsync":
			SaveData.apply_window()
		if key == "fullscreen" and _size_option != null:
			_size_option.disabled = on
		Sfx.play("click"))
	row.add_child(c)


## 창 크기: 창 모드일 때만 고를 수 있고, 모니터보다 큰 크기는 고를 수 없다
func _add_size_option() -> void:
	var row := _row("창 크기")
	_size_option = OptionButton.new()
	var screen := DisplayServer.screen_get_size()
	for i in SaveData.WINDOW_SIZES.size():
		var size: Vector2i = SaveData.WINDOW_SIZES[i]
		_size_option.add_item("%d × %d" % [size.x, size.y], i)
		if size.x > screen.x or size.y > screen.y:
			_size_option.set_item_disabled(i, true)
	_size_option.select(clampi(int(SaveData.settings.window_size), 0, SaveData.WINDOW_SIZES.size() - 1))
	_size_option.disabled = bool(SaveData.settings.fullscreen)
	_size_option.custom_minimum_size = Vector2(160, 0)
	_size_option.item_selected.connect(func(index: int) -> void:
		SaveData.settings["window_size"] = index
		SaveData.save()
		SaveData.apply_window()
		Sfx.play("click"))
	row.add_child(_size_option)


## 언어: 자동(컴퓨터 언어를 따름), 한국어, English
func _add_language_option() -> void:
	var row := _row("언어")
	var opt := OptionButton.new()
	opt.add_item("자동 / Auto", 0)
	opt.add_item("한국어", 1)
	opt.add_item("English", 2)
	var current := Lang.OPTIONS.find(str(SaveData.settings.get("language", "auto")))
	opt.select(maxi(current, 0))
	opt.custom_minimum_size = Vector2(160, 0)
	opt.item_selected.connect(func(index: int) -> void:
		SaveData.settings["language"] = Lang.OPTIONS[index]
		SaveData.save()
		Lang.apply()
		Sfx.play("click")
		language_changed.emit())
	row.add_child(opt)
