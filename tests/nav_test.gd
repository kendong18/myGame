extends Node
## 개발용 테스트: 실행 `godot --headless --path . res://tests/nav_test.tscn`
## 게임패드/키보드로 메뉴를 조작하는 흐름(포커스, 확인, 취소), 키 바꾸기, 라이선스 화면을 검사한다.

var _menu: Node


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame


func _focus_text() -> String:
	var f := get_viewport().gui_get_focus_owner()
	return "(없음)" if f == null else "%s '%s'" % [f.get_class(), (f as Button).text if f is Button else ""]


func _ready() -> void:
	SaveData.persist = false
	SaveData.gold = 500
	SaveData.upgrades = {}
	SaveData.settings["keys"] = {}
	_menu = load("res://scenes/menu.tscn").instantiate()
	add_child(_menu)
	for i in 4:
		await get_tree().process_frame

	print("시작 포커스: %s (기대: 게임 시작)" % _focus_text())
	await _press("ui_accept")
	print("확인 후 화면: %s (기대 select), 포커스 %s" % [_menu._current, _focus_text()])
	await _press("ui_cancel")
	print("취소 후 화면: %s (기대 title)" % _menu._current)

	# 아래로 이동해서 강화 상점 열기
	await _press("ui_down")
	print("아래로 한 칸: %s (기대: 강화 상점)" % _focus_text())
	await _press("ui_accept")
	print("화면: %s (기대 shop), 포커스 %s" % [_menu._current, _focus_text()])
	var before := SaveData.gold
	await _press("ui_accept")
	print("첫 항목 구매: 골드 %d → %d, 포커스 유지 %s" % [before, SaveData.gold, _focus_text()])
	await _press("ui_cancel")

	# 설정 → 조작 키 설정 → 키 바꾸기
	_menu._show("settings")
	await get_tree().process_frame
	await get_tree().process_frame
	_menu._show("keys")
	await get_tree().process_frame
	await get_tree().process_frame
	var slot_button: Button = null
	for row in _menu._keys_grid.get_children():
		slot_button = row.get_child(1)
		break
	slot_button.pressed.emit()
	await get_tree().process_frame
	print("바꾸는 중 상태: %s" % str(_menu._listening))
	var key_ev := InputEventKey.new()
	key_ev.physical_keycode = KEY_T
	key_ev.pressed = true
	Input.parse_input_event(key_ev)
	await get_tree().process_frame
	await get_tree().process_frame
	var keys := InputSetup.keys_for("move_up")
	var has_t := false
	for e in InputMap.action_get_events("move_up"):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_T:
			has_t = true
	print("위로 이동 키: %s / %s (기대 T / Up), 입력 시스템 반영 %s" % [InputSetup.key_label(keys[0]), InputSetup.key_label(keys[1]), has_t])

	# 이미 쓰는 키를 고르면 서로 바뀐다
	InputSetup.set_key("move_down", 0, KEY_T)
	print("키 맞바꾸기: 위로=%s 아래로=%s (기대 위로 S, 아래로 T)" % [InputSetup.key_label(InputSetup.keys_for("move_up")[0]), InputSetup.key_label(InputSetup.keys_for("move_down")[0])])
	InputSetup.reset_defaults()
	print("기본값 복구: 위로=%s" % InputSetup.key_label(InputSetup.keys_for("move_up")[0]))

	# 예약된 키는 거부
	_menu._show("keys")
	await get_tree().process_frame
	_menu._listening = {"action": "dash", "slot": 0}
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_P
	esc.pressed = true
	Input.parse_input_event(esc)
	await get_tree().process_frame
	print("예약 키 P 거부: 대시 키 %s (기대 Space)" % InputSetup.key_label(InputSetup.keys_for("dash")[0]))

	# 라이선스 전문
	_menu._show("licenses")
	await get_tree().process_frame
	var txt: String = _menu._licenses_text.get_parsed_text()
	print("라이선스 화면 글자 수 %d, 주아 포함 %s, Godot 포함 %s" % [txt.length(), txt.contains("Jua"), txt.contains("Godot")])
	await _press("ui_cancel")
	print("라이선스에서 취소: %s (기대 credits)" % _menu._current)
	get_tree().quit()
