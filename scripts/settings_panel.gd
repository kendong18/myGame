class_name SettingsPanel
extends VBoxContainer
## 설정 항목 모음: 음량, 피해 숫자, 화면 흔들림, 전체화면. 타이틀과 일시정지 화면이 함께 쓴다.


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_add_slider("효과음", "sfx")
	_add_slider("음악", "music")
	_add_toggle("피해 숫자 표시", "damage_numbers")
	_add_toggle("화면 흔들림", "screen_shake")
	_add_toggle("전체 화면 (F11)", "fullscreen")


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
		if key == "fullscreen":
			SaveData.apply_window()
		Sfx.play("click"))
	row.add_child(c)
