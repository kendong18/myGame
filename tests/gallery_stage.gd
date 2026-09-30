extends Node2D
## 개발용 그림 확인 화면: 온실 구역의 바닥, 적, 보스, 위험 지대를 한 화면에 늘어놓는다.
## 실행: godot --path . res://tests/gallery_stage.tscn -- --autoplay
## 다른 스테이지는 --stage=아이디 로 고른다.

var _hazards: Array[Hazard] = []


func _ready() -> void:
	var stage_id := "greenhouse"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--stage="):
			stage_id = a.substr(8)
	var st := GameData.stage(stage_id)
	var bg := Background.new()
	bg.style = str(st.bg)
	add_child(bg)
	bg.cam_pos = Vector2(640, 360)
	bg.view_size = Vector2(1280, 720)
	bg.t = 3.0

	# 1줄: 일반 적
	var kinds: Array = st.enemies
	for i in kinds.size():
		_enemy(str(kinds[i]), Vector2(140 + i * 200, 110), 2.4)

	# 2줄: 보스 둘, 심지가 타는 열매, 성난 호박
	_enemy(str(st.mid_boss), Vector2(200, 300), 1.7)
	_enemy(str(st.final), Vector2(520, 320), 1.5)
	var lit := _enemy("bulb", Vector2(820, 290), 2.8)
	lit.fuse = 0.4
	lit.queue_redraw()
	var angry := _enemy("pumpkin", Vector2(1000, 290), 2.4)
	angry.charge_state = 1
	angry.queue_redraw()
	var raged := _enemy("greentree", Vector2(1160, 330), 1.1)
	raged.rage = true
	raged.queue_redraw()

	# 3줄: 위험 지대
	if stage_id == "freezer":
		_hazard(Hazard.frost(Vector2(150, 560), 55.0, 1.2, 10.0, "냉기 폭발"), 0.85)
		_hazard(Hazard.frost(Vector2(350, 560), 55.0, 1.2, 10.0, "냉기 폭발"), 1.32)
		_hazard(Hazard.ice(Vector2(600, 560), 105.0, 16.0), 3.0)
		_hazard(Hazard.sweep(Vector2(900, 600), 2, 0.4, 0.8, 1.2, 3.4, 10.0, "냉기 빔"), 2.0)
		_hazard(Hazard.sweep(Vector2(1100, 640), 1, 3.6, 0.8, 1.2, 3.4, 10.0, "냉기 빔"), 0.6)
	else:
		_hazard(Hazard.thorns(Vector2(150, 560), 55.0, 1.2, 10.0, "가시 덩굴"), 0.85)
		_hazard(Hazard.thorns(Vector2(350, 560), 55.0, 1.2, 10.0, "가시 덩굴"), 1.32)
		_hazard(Hazard.spore(Vector2(560, 560), 60.0, 4.5, 4.0, "버섯 포자"), 1.5)
		_hazard(Hazard.puddle(Vector2(800, 560), 85.0, 12.0), 3.0)
		# 상태 표시를 붙여 본 새싹
		var statuses := ["gel", "cold", "heat", "shock"]
		for i in statuses.size():
			var e := _enemy("sprout", Vector2(980 + i * 70, 560), 2.2)
			e.status[statuses[i]] = 5.0
			e.queue_redraw()


func _enemy(kind: String, pos: Vector2, sc: float) -> Enemy:
	var e := Enemy.new()
	e.setup(kind, 1.0)
	e.position = pos
	e.scale = Vector2(sc, sc)
	add_child(e)
	return e


func _hazard(h: Hazard, age: float) -> void:
	add_child(h)
	h.age = age
	h.queue_redraw()
	_hazards.append(h)
