extends Node
## 개발용 테스트: 실행 `godot --headless --path . res://tests/menu_test.tscn`
## 메뉴 화면 각각을 만들어 보고, 저장/상점/해금 로직을 검사한다. (실제 저장 파일은 건드리지 않음)


func _ready() -> void:
	var save := SaveData
	save.persist = false          # 테스트가 실제 저장 파일을 바꾸지 않도록
	save.gold = 5000
	save.upgrades = {}
	save.unlocked = ["coco", "miyu"]
	var scene: Node = load("res://scenes/menu.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	for screen in ["title", "select", "shop", "howto", "settings", "title"]:
		scene._show(screen)
		await get_tree().process_frame
		print("화면 %s: 정상" % screen)

	# 상점 구매/환불
	print("시작 상태: 골드 %d, 힘 단계 %d" % [save.gold, save.upgrade_level("might")])
	var item: Dictionary = GameData.SHOP[0]
	print("힘 가격 %d, 구매 %s, 남은 골드 %d, 단계 %d" % [GameData.shop_cost(item, 0), save.buy_upgrade(item), save.gold, save.upgrade_level("might")])
	var p := Player.new()
	p.setup("coco")
	print("힘 강화 후 공격력 배율 %.2f (기대 1.05), 코코 최대 체력 %d (기대 120)" % [p.stats["might"], int(p.max_hp)])
	print("환불 %d, 골드 %d, 단계 %d" % [save.refund_all(), save.gold, save.upgrade_level("might")])

	# 캐릭터 해금
	var hunter: Dictionary = GameData.character("scout")
	print("탐사 로봇 해금 %s (비용 %d), 골드 %d" % [save.unlock_char(hunter), hunter.cost, save.gold])

	# 부활 강화 반영
	save.upgrades["revival"] = 1
	var p2 := Player.new()
	p2.setup("miyu")
	print("부활 횟수 %d (기대 1), 미유 쿨타임 배율 %.2f (기대 0.90)" % [p2.revives, p2.stats["cooldown"]])

	# 대시: 시작, 무적, 재사용 대기, 상점 강화 반영
	var p3 := Player.new()
	p3.setup("coco")
	p3.position = Vector2.ZERO
	var started: bool = p3.try_dash(Vector2.RIGHT)
	var again: bool = p3.try_dash(Vector2.RIGHT)
	for i in 12:
		p3.step(0.016, Vector2.ZERO)
	print("대시 시작 %s (기대 true), 연속 사용 %s (기대 false), 이동 %d px (기대 약 150), 무적 %s" % [started, again, int(p3.position.x), p3.invuln > 0.0])
	for i in 100:
		p3.step(0.016, Vector2.ZERO)
	print("1.6초 뒤 재사용 가능 %s (기대 true)" % p3.try_dash(Vector2.LEFT))
	save.upgrades["dash"] = 3
	var p4 := Player.new()
	p4.setup("coco")
	p4.try_dash(Vector2.RIGHT)
	print("대시 충전 3단계 재사용 시간 %.2f초 (기대 1.14)" % p4.dash_cd)

	# 보상 계산
	print("보상 예시: 동전 50, 처치 800, 5분, 패배 = %d / 승리 = %d" % [GameData.run_reward(50, 800, 300.0, false), GameData.run_reward(50, 800, 600.0, true)])
	get_tree().quit()
