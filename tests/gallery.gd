extends Node2D
## 개발용 그림 확인 화면: 캐릭터, 적, 보스, 상태 표시, 투사체, 아이템을 한 화면에 늘어놓는다.
## 실행: godot --path . res://tests/gallery.tscn -- --autoplay


func _ready() -> void:
	var bg := Background.new()
	add_child(bg)
	bg.cam_pos = Vector2(640, 360)
	bg.view_size = Vector2(1280, 720)
	bg.queue_redraw()

	# 1줄: 캐릭터 6명
	for i in GameData.CHARACTERS.size():
		var ch: Dictionary = GameData.CHARACTERS[i]
		var p := Player.new()
		p.setup(ch.id)
		p.position = Vector2(150 + i * 195, 80)
		p.scale = Vector2(2.2, 2.2)
		add_child(p)
		p.set_process(false)
		p.queue_redraw()

	# 2줄: 일반 적 7종
	var kinds := ["moth", "jelly", "drone", "bubble", "turret", "hound", "cube"]
	for i in kinds.size():
		_enemy(kinds[i], Vector2(110 + i * 170, 215), 2.0)

	# 3줄: 보스 2종 + 상태 표시
	_enemy("jellyking", Vector2(170, 380), 1.6)
	_enemy("core", Vector2(470, 385), 1.4)
	var statuses := ["gel", "cold", "heat", "shock"]
	for i in statuses.size():
		var e := _enemy("jelly", Vector2(720 + i * 130, 360), 2.4)
		e.status[statuses[i]] = 5.0
		e.queue_redraw()
	var stunned := _enemy("drone", Vector2(720, 470), 2.4)
	stunned.stun = 5.0
	stunned.queue_redraw()
	var elite := _enemy("hound", Vector2(850, 470), 2.0, true)
	elite.queue_redraw()

	# 4줄: 투사체
	var y := 590.0
	_proj("bolt", Vector2(70, y), Color(0.5, 0.95, 0.4), 9.0)
	_proj("knife", Vector2(150, y), Color(1.0, 0.92, 0.3), 6.0)
	_proj("axe", Vector2(230, y), Color(0.5, 0.85, 1.0), 14.0)
	_proj("scythe", Vector2(320, y), Color(0.5, 0.85, 1.0), 18.0)
	_proj("book", Vector2(410, y), Color(0.8, 0.45, 1.0), 13.0)
	var zone := _proj("zone", Vector2(540, y), Color(1.0, 0.5, 0.2), 60.0)
	zone.age = 1.0
	zone.life = 2.0
	var zone_ev := _proj("zone", Vector2(690, y), Color(1.0, 0.5, 0.2), 60.0)
	zone_ev.age = 0.2
	zone_ev.delay = 0.35

	# 아이템과 상자
	var kinds_p := ["battery", "magnet", "pulse", "coin"]
	for i in kinds_p.size():
		var pk := Pickup.new()
		pk.kind = kinds_p[i]
		pk.position = Vector2(820 + i * 70, y)
		pk.scale = Vector2(1.6, 1.6)
		add_child(pk)
	var chest := Chest.new()
	chest.position = Vector2(1130, y - 10)
	chest.scale = Vector2(1.6, 1.6)
	add_child(chest)
	var prop := Prop.new()
	prop.position = Vector2(1215, y - 10)
	prop.scale = Vector2(1.6, 1.6)
	add_child(prop)


func _enemy(kind: String, pos: Vector2, sc: float, elite: bool = false) -> Enemy:
	var e := Enemy.new()
	e.setup(kind, 1.0, elite)
	e.position = pos
	e.scale = Vector2(sc, sc)
	add_child(e)
	return e


func _proj(kind: String, pos: Vector2, col: Color, r: float) -> Projectile:
	var p := Projectile.make(kind, pos, Vector2.RIGHT * 10.0, 1.0, 1, 5.0, r, null)
	p.color = col
	p.rotation = 0.0
	add_child(p)
	return p
