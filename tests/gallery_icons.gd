extends Control
## 개발용 그림 확인 화면: 모든 무기와 아이템 아이콘을 늘어놓는다.
## 실행: godot --path . res://tests/gallery_icons.tscn -- --autoplay


func _ready() -> void:
	theme = UiTheme.get_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var weapons: Array = []
	var evolved: Array = []
	for id: String in GameData.WEAPONS:
		if GameData.WEAPONS[id].get("evolved", false):
			evolved.append(id)
		else:
			weapons.append(id)
	_row("무기", weapons, 40.0, true, false)
	_row("진화", evolved, 130.0, true, true)
	_row("아이템", GameData.PASSIVES.keys(), 220.0, false, false)
	# 진화 가능 표시와 최대 레벨 표시
	var ready := ItemSlot.new().setup({"id": "torch", "level": 8, "max": 8, "ready": true}, true, 64.0)
	ready.position = Vector2(30, 320)
	add_child(ready)
	var maxed := ItemSlot.new().setup({"id": "vacuum", "level": 8, "max": 8}, true, 64.0)
	maxed.position = Vector2(110, 320)
	add_child(maxed)
	var mid := ItemSlot.new().setup({"id": "mine", "level": 3, "max": 8}, true, 64.0)
	mid.position = Vector2(190, 320)
	add_child(mid)
	var empty := ItemSlot.new().setup({}, true, 64.0)
	empty.position = Vector2(270, 320)
	add_child(empty)
	var small := ItemSlot.new().setup({"id": "chip", "level": 2, "max": 5}, false, 44.0)
	small.position = Vector2(350, 330)
	add_child(small)


func _row(title: String, ids: Array, y: float, weapon: bool, evolved: bool) -> void:
	var t := UiTheme.label(title, 16, Color(1, 0.85, 0.4), 2)
	t.position = Vector2(30, y - 22)
	add_child(t)
	for i in ids.size():
		var id: String = ids[i]
		var info := {"id": id, "level": 3 + i % 5, "max": int(GameData.PASSIVES[id].max) if not weapon else 8, "evolved": evolved}
		var s := ItemSlot.new().setup(info, weapon, 64.0)
		s.position = Vector2(30 + i * 84, y)
		add_child(s)
