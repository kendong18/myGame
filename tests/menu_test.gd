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

	# 보상 계산
	print("보상 예시: 동전 50, 처치 800, 5분, 패배 = %d / 승리 = %d" % [GameData.run_reward(50, 800, 300.0, false), GameData.run_reward(50, 800, 600.0, true)])
	get_tree().quit()
