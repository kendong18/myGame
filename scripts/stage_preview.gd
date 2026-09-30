class_name StagePreview
extends Control
## 스테이지 선택 카드에 보이는 작은 미리보기: 그 스테이지의 바닥과 나오는 적들이 서 있다

var stage_id := "station"
var locked := false
var _bg: Background
var _actors: Array[Enemy] = []
var _t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(300, 120)
	clip_contents = true


func _ready() -> void:
	var st := GameData.stage(stage_id)
	_bg = Background.new()
	_bg.style = str(st.bg)
	_bg.view_size = custom_minimum_size
	_bg.position = custom_minimum_size / 2.0
	add_child(_bg)
	_bg.z_index = 0    # 카드 위에 그려지도록 (배경 기본값은 맨 아래)
	var kinds: Array = st.enemies
	var n := mini(5, kinds.size())
	for i in n:
		var e := Enemy.new()
		e.setup(str(kinds[(i * 2) % kinds.size()]), 1.0)
		e.position = Vector2(46.0 + float(i) * (custom_minimum_size.x - 92.0) / maxf(1.0, float(n - 1)), 68.0 + float(i % 2) * 14.0)
		e.z_index = 0
		e.scale = Vector2(1.4, 1.4)
		add_child(e)
		_actors.append(e)
	if locked:
		var shade := ColorRect.new()
		shade.color = Color(0.03, 0.02, 0.08, 0.82)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(shade)


func _process(delta: float) -> void:
	_t += delta
	_bg.t = _t
	_bg.queue_redraw()
	for i in _actors.size():
		var e := _actors[i]
		e.scale = Vector2(1.4, 1.4 + 0.08 * sin(_t * 5.0 + float(i)))
