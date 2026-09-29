extends Node
## 개발용 테스트: 실행 `godot --headless --path . res://tests/gameplay_test.tscn`
## 진공청소기가 적을 몸에 붙이지 않는지, 캐릭터 고유 능력, 위험도 해금과 난이도 배율을 검사한다.

var _fails := 0


func _check(ok: bool, text: String) -> void:
	print("%s %s" % ["✔" if ok else "✘ 실패:", text])
	if not ok:
		_fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## 게임 장면을 새로 만든다. 자동 진행은 끄고, 테스트가 직접 한 프레임씩 진행시킨다.
func _new_game(char_id: String, tier: int = 0) -> Main:
	SaveData.selected_char = char_id
	SaveData.risk_tier = tier
	var game: Main = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await _frames(2)
	game.set_process(false)
	game.stress = 1              # 자동 스폰을 막고, 테스트가 넣은 적만 쓴다
	for e in game.enemies:
		e.dead = true
	game._cleanup()
	return game


func _add_enemy(game: Main, kind: String, pos: Vector2) -> Enemy:
	var e := game.spawn_enemy(kind, {"pos": pos})
	e.speed = 0.0
	e.hp = 1.0e9          # 테스트 도중 죽지 않게 한다
	e.max_hp = 1.0e9
	return e


func _step(game: Main, seconds: float) -> void:
	for i in int(seconds * 60.0):
		game._update_game(1.0 / 60.0)


func _ready() -> void:
	SaveData.persist = false
	SaveData.cleared_tier = -1

	# ── 진공청소기: 적을 몸에 붙이지 않는다 ──
	var g := await _new_game("ppo")
	g.player.weapons.clear()
	g.player.add_weapon("vacuum")
	var crowd: Array[Enemy] = []
	for i in 24:
		var a := TAU * float(i) / 24.0
		crowd.append(_add_enemy(g, "jelly", g.player.position + Vector2.from_angle(a) * (52.0 + float(i % 3) * 6.0)))
	_step(g, 3.0)
	var nearest := 9999.0
	var slowed := 0
	for e in crowd:
		if not e.dead:
			nearest = minf(nearest, e.position.distance_to(g.player.position))
			if e.suction > 0.0:
				slowed += 1
	var touch := 11.0 + Player.RADIUS - 4.0
	# 24마리가 좁은 고리에 한꺼번에 몰리는 극단적인 상황이므로, 접촉 거리보다 5픽셀 이상 바깥이면 통과로 본다
	_check(nearest > touch + 5.0, "진공청소기가 끌어당긴 뒤에도 적이 접촉 거리(%d) 밖에 있음 (가장 가까운 적 %.0f)" % [int(touch), nearest])
	_check(g.player.damage_taken == 0.0, "끌어당기는 동안 플레이어가 피해를 받지 않음 (받은 피해 %.0f)" % g.player.damage_taken)
	_check(slowed > 0, "범위 안의 적이 붙잡혀 느려짐 (%d마리)" % slowed)
	var moved := 0
	for e in crowd:
		if e.position.distance_to(g.player.position) < 52.0 - 4.0:
			moved += 1
	_check(moved > 5, "적들이 안쪽 고리로 모여듦 (%d마리)" % moved)
	g.queue_free()
	await _frames(2)

	# ── 코코: 대시 2회 ──
	var coco := await _new_game("coco")
	var pl := coco.player
	var a1: bool = pl.try_dash(Vector2.RIGHT)
	for i in 14:
		pl.step(0.016, Vector2.ZERO)
	var a2: bool = pl.try_dash(Vector2.RIGHT)
	for i in 14:
		pl.step(0.016, Vector2.ZERO)
	var a3: bool = pl.try_dash(Vector2.RIGHT)
	_check(a1 and a2 and not a3, "코코는 대시를 연속 2번 쓰고 3번째는 못 씀 (%s, %s, %s)" % [a1, a2, a3])
	for i in 200:
		pl.step(0.016, Vector2.ZERO)
	_check(pl.dash_charges == 2, "시간이 지나면 2번 모두 충전됨 (%d)" % pl.dash_charges)
	coco.queue_free()
	await _frames(2)

	# ── 삐삐: 대시 뒤 쿨타임 감소 ──
	var scout := await _new_game("scout")
	var base_cd: float = scout.player.cd_mult()
	scout.player.try_dash(Vector2.RIGHT)
	_check(scout.player.cd_mult() < base_cd * 0.75, "삐삐는 대시 뒤 무기 쿨타임이 줄어듦 (%.2f → %.2f)" % [base_cd, scout.player.cd_mult()])
	scout.queue_free()
	await _frames(2)

	# ── 부루: 대시 충격파 ──
	var buru := await _new_game("buru")
	var victim := _add_enemy(buru, "cube", buru.player.position + Vector2(40, 0))
	buru._rebuild_grid()
	var hp_before := victim.hp
	buru._dash_slam()
	_check(victim.hp < hp_before, "부루의 대시 충격파가 주변 적에게 피해를 줌 (%.0f → %.0f)" % [hp_before, victim.hp])
	buru.queue_free()
	await _frames(2)

	# ── 미유: 젤 번짐 ──
	var miyu := await _new_game("miyu")
	var center := _add_enemy(miyu, "jelly", miyu.player.position + Vector2(200, 0))
	for i in 4:
		_add_enemy(miyu, "jelly", center.position + Vector2(30.0 + float(i) * 10.0, 0))
	miyu._rebuild_grid()
	miyu._add_status(center, "gel", 10.0, Weapon.new("gelgun"))
	var gelled := 0
	for e in miyu.enemies:
		if e.status.has("gel"):
			gelled += 1
	_check(gelled == 3, "미유의 젤이 주변 적 2마리에게 번짐 (젤이 붙은 적 %d마리, 기대 3)" % gelled)
	miyu.queue_free()
	await _frames(2)

	# ── 뽀송: 보석을 주우면 회복 ──
	var ppo := await _new_game("ppo")
	ppo.player.hp = 50.0
	ppo.spawn_gem(ppo.player.position, 1)
	ppo.gems[0].position = ppo.player.position
	ppo.gems[0].attracted = true
	_step(ppo, 0.3)
	_check(ppo.player.hp > 50.0, "뽀송은 경험치 보석을 주우면 체력이 회복됨 (%.1f)" % ppo.player.hp)
	ppo.queue_free()
	await _frames(2)

	# ── 오린: 반응이 터지면 경험치 ──
	var owl := await _new_game("owl")
	var target := _add_enemy(owl, "jelly", owl.player.position + Vector2(100, 0))
	var xp_before: float = owl.player.xp
	owl._react("gel+shock", target, Weapon.new("gelgun"), 10.0, 1.0, 1)
	_check(owl.player.xp > xp_before, "오린은 속성 반응이 터지면 경험치를 얻음 (%.1f → %.1f)" % [xp_before, owl.player.xp])
	owl.queue_free()
	await _frames(2)

	# ── 위험도: 해금과 난이도 배율 ──
	SaveData.cleared_tier = -1
	_check(SaveData.max_tier() == 0, "처음에는 위험도 0만 고를 수 있음 (%d)" % SaveData.max_tier())
	SaveData.record_run(600.0, 500, 20, 100, true, 0)
	_check(SaveData.max_tier() == 1, "위험도 0을 클리어하면 1이 열림 (%d)" % SaveData.max_tier())
	SaveData.record_run(300.0, 100, 10, 50, false, 1)
	_check(SaveData.max_tier() == 1, "패배해도 위험도는 열리지 않음 (%d)" % SaveData.max_tier())
	SaveData.record_run(600.0, 900, 30, 100, true, 1)
	_check(SaveData.max_tier() == 2, "위험도 1을 클리어하면 2가 열림 (%d)" % SaveData.max_tier())
	SaveData.cleared_tier = 5
	_check(SaveData.max_tier() == 5, "위험도는 최대 5단계 (%d)" % SaveData.max_tier())
	SaveData.cleared_tier = -1

	var normal := await _new_game("coco", 0)
	var hard := await _new_game("coco", 5)
	var e0 := normal.spawn_enemy("jelly", {"pos": Vector2(500, 0)})
	var e5 := hard.spawn_enemy("jelly", {"pos": Vector2(500, 0)})
	_check(e5.max_hp > e0.max_hp * 2.5, "위험도 5의 적 체력이 훨씬 높음 (%.0f vs %.0f)" % [e0.max_hp, e5.max_hp])
	_check(e5.damage > e0.damage * 1.5, "위험도 5의 적 피해가 더 큼 (%.1f vs %.1f)" % [e0.damage, e5.damage])
	var boss0 := normal.spawn_enemy("jellyking", {"pos": Vector2(500, 0)})
	var boss5 := hard.spawn_enemy("jellyking", {"pos": Vector2(500, 0)})
	_check(boss5.max_hp > boss0.max_hp * 2.5, "위험도 5의 보스 체력이 훨씬 높음 (%.0f vs %.0f)" % [boss0.max_hp, boss5.max_hp])
	_check(GameData.run_reward(100, 500, 300.0, false, 5) > GameData.run_reward(100, 500, 300.0, false, 0) * 2, "위험도가 높으면 보상이 늘어남")
	normal.queue_free()
	hard.queue_free()
	await _frames(2)

	print("\n결과: 실패 %d개" % _fails)
	get_tree().quit()
