class_name InputSetup
extends RefCounted
## 키 입력 설정: 기본 키와 사용자가 바꾼 키를 입력 이름(action)에 연결한다.
## 조작마다 키 두 칸을 쓴다. 게임패드는 고정이다.

const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "dash"]
const ACTION_NAMES := {
	"move_up": "위로 이동", "move_down": "아래로 이동", "move_left": "왼쪽으로 이동",
	"move_right": "오른쪽으로 이동", "dash": "대시",
}
const DEFAULTS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"dash": [KEY_SPACE, KEY_SHIFT],
}
# 다른 기능에 이미 쓰이는 키는 지정할 수 없다 (일시정지, 전체 화면, 레벨업 선택)
const RESERVED := [KEY_ESCAPE, KEY_F11, KEY_P, KEY_1, KEY_2, KEY_3]


static func keys_for(action: String) -> Array:
	var saved: Variant = SaveData.settings.get("keys", {})
	if saved is Dictionary and (saved as Dictionary).has(action):
		var arr: Variant = (saved as Dictionary)[action]
		if arr is Array and (arr as Array).size() == 2:
			return [int(arr[0]), int(arr[1])]
	return (DEFAULTS[action] as Array).duplicate()


static func key_label(code: int) -> String:
	if code <= 0:
		return "-"
	return OS.get_keycode_string(code as Key)


## 한 칸의 키를 바꾼다. 같은 키가 이미 다른 칸에 있으면 두 칸의 키를 서로 바꾼다.
static func set_key(action: String, slot: int, code: int) -> void:
	var keys := {}
	for a: String in ACTIONS:
		keys[a] = keys_for(a)
	var old: int = keys[action][slot]
	for a: String in ACTIONS:
		for i in 2:
			if (a != action or i != slot) and int(keys[a][i]) == code:
				keys[a][i] = old
	keys[action][slot] = code
	SaveData.settings["keys"] = keys
	SaveData.save()
	apply()


static func reset_defaults() -> void:
	SaveData.settings["keys"] = {}
	SaveData.save()
	apply()


## 저장된 키 설정을 입력 시스템에 반영한다. 게임 시작 때와 키를 바꿀 때마다 호출한다.
static func apply() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		InputMap.action_erase_events(action)
		for code: int in keys_for(action):
			if code > 0:
				var ev := InputEventKey.new()
				ev.physical_keycode = code as Key
				InputMap.action_add_event(action, ev)
	# 게임패드: 왼쪽 스틱으로 이동, A 또는 오른쪽 어깨 버튼으로 대시
	var axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action: String in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axes[action][0] as JoyAxis
		jm.axis_value = axes[action][1]
		InputMap.action_add_event(action, jm)
	for btn: int in [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER]:
		var jb := InputEventJoypadButton.new()
		jb.button_index = btn as JoyButton
		InputMap.action_add_event("dash", jb)
