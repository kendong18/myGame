extends Node
## 개발용 테스트: 실행 `godot --headless --path . res://tests/i18n_test.tscn`
## 영어로 바꿨을 때 메뉴와 게임 화면의 모든 글자에 한글이 남아 있지 않은지 검사한다.

var _bad := 0
var _checked := 0


func _has_hangul(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 0xAC00 and c <= 0xD7A3:
			return true
	return false


func _all_nodes(n: Node, out: Array) -> void:
	out.append(n)
	for c in n.get_children():
		_all_nodes(c, out)


func _scan(root: Node, where: String) -> void:
	var nodes: Array = []
	_all_nodes(root, nodes)
	for n in nodes:
		var text := ""
		if n is Label:
			text = (n as Label).atr((n as Label).text)
		elif n is Button and not (n is OptionButton):
			text = (n as Button).atr((n as Button).text)
		elif n is Fx:
			text = (n as Fx).text
		if text == "":
			continue
		_checked += 1
		if _has_hangul(text):
			_bad += 1
			print("  [%s] 한글이 남아 있음: %s" % [where, text.replace("\n", " / ")])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	SaveData.persist = false
	SaveData.settings["language"] = "en"
	Lang.apply()
	print("현재 언어: %s" % TranslationServer.get_locale())
	print("번역 확인: '%s' → '%s'" % ["게임 시작", T.t("게임 시작")])
	print("형식 번역: '%s'" % T.f("처치 %d", [7]))
	print("표에 없는 문구는 그대로: '%s'" % T.t("표에 없는 문구"))

	# 메뉴의 모든 화면
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	add_child(menu)
	await _frames(3)
	SaveData.gold = 5000
	for screen: String in menu._screens.keys():
		menu._show(screen)
		await _frames(2)
		_scan(menu, "메뉴/" + screen)
	menu.queue_free()
	await _frames(2)

	# 게임 화면: 레벨업, 상자, 일시정지, 결과, 반응 글자
	var game: Node = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await _frames(3)
	game.time = 130.0
	game._open_levelup()
	await _frames(2)
	_scan(game, "게임/레벨업")
	game.hud.hide_levelup()
	game.state = Main.State.PLAYING
	game.player.level = 8
	game._open_chest(3)
	await _frames(2)
	_scan(game, "게임/상자")
	game.hud.hide_chest()
	game.state = Main.State.PLAYING
	game._toggle_pause()
	await _frames(2)
	_scan(game, "게임/일시정지")
	game.hud.hide_pause()
	game.state = Main.State.PLAYING
	game.last_hit_by = T.t("젤리 킹")
	game._finish(false)
	await _frames(2)
	_scan(game, "게임/결과")
	# 보스 알림, 반응 글자
	game.hud.show_banner(T.f("보스 등장: %s", [T.t("젤리 킹")]))
	var e: Enemy = game.spawn_enemy("jelly", {"pos": game.player.position + Vector2(40, 0)})
	for key: String in GameData.REACTIONS.keys():
		game._react(key, e, Weapon.new("gelgun"), 10.0, 1.0, 1)
	await _frames(2)
	_scan(game, "게임/반응 글자")
	await _frames(1)
	print("검사한 글자 %d개, 한글이 남은 것 %d개" % [_checked, _bad])
	get_tree().quit()
