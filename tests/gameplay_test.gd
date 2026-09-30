extends Node
## 개발용 테스트: 실행 `godot --headless --path . res://tests/gameplay_test.tscn`
## 진공청소기가 적을 몸에 붙이지 않는지, 캐릭터 고유 능력, 위험도 해금과 난이도 배율, 스테이지 해금과 온실 구역의 적, 지형, 보스를 검사한다.

var _fails := 0


func _check(ok: bool, text: String) -> void:
	print("%s %s" % ["✔" if ok else "✘ 실패:", text])
	if not ok:
		_fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## 게임 장면을 새로 만든다. 자동 진행은 끄고, 테스트가 직접 한 프레임씩 진행시킨다.
func _new_game(char_id: String, tier: int = 0, stage_id: String = "station") -> Main:
	SaveData.selected_char = char_id
	SaveData.risk_tier = tier
	SaveData.selected_stage = stage_id
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
	SaveData.cleared = {}

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
	SaveData.cleared = {}
	_check(SaveData.max_tier() == 0, "처음에는 위험도 0만 고를 수 있음 (%d)" % SaveData.max_tier())
	SaveData.record_run(600.0, 500, 20, 100, true, 0)
	_check(SaveData.max_tier() == 1, "위험도 0을 클리어하면 1이 열림 (%d)" % SaveData.max_tier())
	SaveData.record_run(300.0, 100, 10, 50, false, 1)
	_check(SaveData.max_tier() == 1, "패배해도 위험도는 열리지 않음 (%d)" % SaveData.max_tier())
	SaveData.record_run(600.0, 900, 30, 100, true, 1)
	_check(SaveData.max_tier() == 2, "위험도 1을 클리어하면 2가 열림 (%d)" % SaveData.max_tier())
	SaveData.cleared = {"station": 5}
	_check(SaveData.max_tier() == 5, "위험도는 최대 5단계 (%d)" % SaveData.max_tier())
	SaveData.cleared = {}

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

	await _stage_tests()
	SaveData.selected_stage = "station"

	print("\n결과: 실패 %d개" % _fails)
	get_tree().quit()


## 스테이지 해금, 온실 구역의 적과 지형, 보스
func _stage_tests() -> void:
	# ── 스테이지 해금과 위험도 ──
	SaveData.cleared = {}
	_check(SaveData.is_stage_unlocked("station"), "첫 스테이지는 처음부터 열려 있음")
	_check(not SaveData.is_stage_unlocked("greenhouse"), "온실 구역은 처음에 잠겨 있음")
	SaveData.record_run(600.0, 500, 20, 100, false, 0, "station")
	_check(not SaveData.is_stage_unlocked("greenhouse"), "패배해도 다음 스테이지는 열리지 않음")
	SaveData.record_run(600.0, 500, 20, 100, true, 0, "station")
	_check(SaveData.is_stage_unlocked("greenhouse"), "첫 스테이지를 클리어하면 온실 구역이 열림")
	_check(SaveData.max_tier("greenhouse") == 0, "온실 구역의 위험도는 0부터 시작 (%d)" % SaveData.max_tier("greenhouse"))
	_check(SaveData.max_tier("station") == 1, "첫 스테이지는 위험도 1까지 열림 (%d)" % SaveData.max_tier("station"))
	SaveData.record_run(600.0, 500, 20, 100, true, 0, "greenhouse")
	_check(SaveData.max_tier("greenhouse") == 1, "온실 구역 클리어로 온실 위험도 1이 열림 (%d)" % SaveData.max_tier("greenhouse"))
	_check(SaveData.max_tier("station") == 1, "다른 스테이지의 위험도는 영향을 받지 않음")
	_check(not SaveData.is_stage_unlocked("없는스테이지"), "없는 스테이지는 잠겨 있음")

	# ── 옛 저장 파일 이전: 스테이지가 생기기 전 파일도 그대로 이어진다 ──
	SaveData.cleared = {}
	SaveData.apply_dict({"gold": 52, "cleared_tier": 1, "risk_tier": 1, "wins": 3, "runs": 3, "selected_char": "owl", "unlocked": ["coco", "miyu", "owl"]})
	_check(SaveData.cleared_tier_of("station") == 1, "옛 위험도 기록이 첫 스테이지의 기록으로 옮겨짐 (%d)" % SaveData.cleared_tier_of("station"))
	_check(SaveData.is_stage_unlocked("greenhouse"), "옛 파일에서도 이미 깬 사람은 온실 구역이 열림")
	_check(SaveData.risk_tier == 1 and SaveData.selected_stage == "station" and SaveData.gold == 52, "골드와 선택한 위험도는 그대로 유지")
	SaveData.cleared = {}
	SaveData.apply_dict({"gold": 5, "wins": 0, "runs": 1})
	_check(SaveData.cleared.is_empty() and not SaveData.is_stage_unlocked("greenhouse"), "한 번도 이기지 못한 옛 파일은 잠긴 채로 시작")
	SaveData.cleared = {}
	SaveData.apply_dict({"wins": 2, "runs": 2})
	_check(SaveData.cleared_tier_of("station") == 0, "위험도가 생기기 전 파일에서 이긴 기록이 있으면 위험도 0 클리어로 봄")
	SaveData.cleared = {}
	SaveData.apply_dict({"cleared": {"station": 2, "greenhouse": 0, "없는곳": 3}, "selected_stage": "greenhouse", "risk_tier": 1})
	_check(SaveData.cleared_tier_of("greenhouse") == 0 and not SaveData.cleared.has("없는곳"), "새 형식 파일을 읽고, 없는 스테이지 기록은 버림")
	_check(SaveData.selected_stage == "greenhouse", "고른 스테이지가 유지됨")
	SaveData.cleared = {}
	SaveData.apply_dict({"selected_stage": "greenhouse"})
	_check(SaveData.selected_stage == "station", "잠긴 스테이지가 저장돼 있으면 첫 스테이지로 돌아감")
	SaveData.selected_stage = "station"
	SaveData.risk_tier = 0
	SaveData.gold = 0
	SaveData.cleared = {}

	# ── 스테이지 배율: 같은 적이 온실에서 더 단단하고 아프다 ──
	var st := await _new_game("coco", 0, "station")
	var gh := await _new_game("coco", 0, "greenhouse")
	var m0 := st.spawn_enemy("moth", {"pos": Vector2(500, 0)})
	var m1 := gh.spawn_enemy("moth", {"pos": Vector2(500, 0)})
	_check(absf(m1.max_hp / m0.max_hp - 1.5) < 0.01, "온실의 적은 체력이 1.5배 (%.1f vs %.1f)" % [m1.max_hp, m0.max_hp])
	_check(absf(m1.damage / m0.damage - 1.25) < 0.01, "온실의 적은 피해가 1.25배 (%.2f vs %.2f)" % [m1.damage, m0.damage])
	_check(gh.bg.style == "greenhouse" and st.bg.style == "station", "스테이지마다 배경 종류가 다름")
	st.queue_free()
	await _frames(2)

	# ── 약점과 저항 ──
	var sprout := _add_enemy(gh, "sprout", gh.player.position + Vector2(300, 0))
	var sun := _add_enemy(gh, "sunflower", gh.player.position + Vector2(0, 300))
	var torch := Weapon.new("torch")
	var bolt := Weapon.new("bolt")
	var base_hp := sprout.hp
	gh.damage_enemy(sprout, 100.0, torch, Vector2.ZERO, 0.0, false)
	_check(is_equal_approx(base_hp - sprout.hp, 135.0), "식물은 열에 약함: 100 피해가 135로 들어감 (%.1f)" % (base_hp - sprout.hp))
	var hp_b := sprout.hp
	gh.damage_enemy(sprout, 100.0, bolt, Vector2.ZERO, 0.0, false)
	_check(is_equal_approx(hp_b - sprout.hp, 100.0), "약점도 저항도 아닌 속성은 그대로 (%.1f)" % (hp_b - sprout.hp))
	var hp_s := sun.hp
	gh.damage_enemy(sun, 100.0, torch, Vector2.ZERO, 0.0, false)
	_check(is_equal_approx(hp_s - sun.hp, 70.0), "해바라기는 열에 저항함: 100 피해가 70으로 (%.1f)" % (hp_s - sun.hp))
	hp_s = sun.hp
	gh.damage_enemy(sun, 100.0, bolt, Vector2.ZERO, 0.0, false)
	_check(is_equal_approx(hp_s - sun.hp, 135.0), "해바라기는 전기에 약함 (%.1f)" % (hp_s - sun.hp))
	hp_s = sun.hp
	gh.damage_enemy(sun, 100.0, null, Vector2.ZERO, 0.0, false)
	_check(is_equal_approx(hp_s - sun.hp, 100.0), "무기가 없는 피해는 속성 배율을 받지 않음")

	# ── 물웅덩이: 위의 적은 전기에 더 크게 다친다 ──
	gh.add_hazard(Hazard.puddle(sprout.position, 85.0, 12.0))
	var hp_p := sprout.hp
	gh.damage_enemy(sprout, 100.0, bolt, Vector2.ZERO, 0.0, false)
	_check(is_equal_approx(hp_p - sprout.hp, 150.0), "물웅덩이 위에서 전기 피해가 1.5배 (%.1f)" % (hp_p - sprout.hp))
	hp_p = sprout.hp
	gh.damage_enemy(sprout, 100.0, torch, Vector2.ZERO, 0.0, false)
	_check(is_equal_approx(hp_p - sprout.hp, 135.0), "물웅덩이는 전기가 아닌 무기에는 영향이 없음 (%.1f)" % (hp_p - sprout.hp))
	gh.hazards[0].position = Vector2(5000, 0)
	hp_p = sprout.hp
	gh.damage_enemy(sprout, 100.0, bolt, Vector2.ZERO, 0.0, false)
	_check(is_equal_approx(hp_p - sprout.hp, 100.0), "웅덩이 밖에서는 보너스가 없음 (%.1f)" % (hp_p - sprout.hp))
	gh.queue_free()
	await _frames(2)

	# ── 폭탄 열매: 붙으면 심지가 타고 터진다 ──
	var g1 := await _new_game("coco", 0, "greenhouse")
	var bulb := _add_enemy(g1, "bulb", g1.player.position + Vector2(30, 0))
	g1._rebuild_grid()
	_step(g1, 0.3)
	_check(bulb.fuse >= 0.0 and not bulb.dead, "가까이 온 폭탄 열매는 심지가 타는 중 (%.2f)" % bulb.fuse)
	_step(g1, 1.0)
	_check(bulb.dead, "심지가 다 타면 폭탄 열매가 터짐")
	_check(g1.player.damage_taken > 0.0, "폭발 범위 안의 플레이어는 피해를 받음 (%.1f)" % g1.player.damage_taken)
	var far := _add_enemy(g1, "bulb", g1.player.position + Vector2(400, 0))
	g1.player.invuln = 0.0
	var taken := g1.player.damage_taken
	far.fuse = 0.05
	_step(g1, 0.3)
	_check(far.dead and g1.player.damage_taken == taken, "멀리서 터진 폭탄 열매는 플레이어를 다치게 하지 않음")
	g1.queue_free()
	await _frames(2)

	# ── 돌진 호박: 조준하고 달려든 뒤 지쳐서 쓰러진다 ──
	var g2 := await _new_game("coco", 0, "greenhouse")
	g2.god = true
	var pump := _add_enemy(g2, "pumpkin", g2.player.position + Vector2(220, 0))
	pump.charge_t = 0.5
	g2._rebuild_grid()
	var saw_wind := false
	var saw_dash := false
	var start_x := pump.position.x
	var min_x := start_x
	for i in 240:
		g2._update_game(1.0 / 60.0)
		saw_wind = saw_wind or pump.charge_state == 1
		saw_dash = saw_dash or pump.charge_state == 2
		min_x = minf(min_x, pump.position.x)
		if saw_dash and pump.charge_state == 0:
			break
	_check(saw_wind and saw_dash, "호박이 준비 자세를 거쳐 돌진함 (준비 %s, 돌진 %s)" % [saw_wind, saw_dash])
	_check(start_x - min_x > 150.0, "돌진하면서 플레이어 쪽으로 크게 이동함 (%.0f px)" % (start_x - min_x))
	_check(pump.stun > 0.0, "돌진이 끝나면 지쳐서 잠시 멈춤 (%.2f)" % pump.stun)
	g2.queue_free()
	await _frames(2)

	# ── 가시 덩굴과 포자 ──
	var g3 := await _new_game("coco", 0, "greenhouse")
	g3.add_hazard(Hazard.thorns(g3.player.position + Vector2(400, 0), 55.0, 0.5, 10.0, "가시 덩굴"))
	_step(g3, 0.7)
	_check(g3.player.damage_taken == 0.0, "멀리 솟은 가시에는 다치지 않음")
	g3.add_hazard(Hazard.thorns(g3.player.position, 55.0, 0.5, 10.0, "가시 덩굴"))
	_step(g3, 0.4)
	_check(g3.player.damage_taken == 0.0, "가시가 솟기 전에는 피해가 없음 (예고 시간)")
	_step(g3, 0.3)
	_check(g3.player.damage_taken > 0.0, "서 있던 자리에 가시가 솟으면 피해를 받음 (%.1f)" % g3.player.damage_taken)
	_step(g3, 1.0)
	var hp_after := g3.player.damage_taken
	_step(g3, 1.0)
	_check(g3.player.damage_taken == hp_after, "가시는 한 번만 피해를 줌")
	g3.queue_free()
	await _frames(2)

	var g4 := await _new_game("coco", 0, "greenhouse")
	var mush := _add_enemy(g4, "mushroom", g4.player.position + Vector2(20, 0))
	mush.hp = 1.0
	g4._rebuild_grid()
	g4.damage_enemy(mush, 999.0, null, Vector2.ZERO, 0.0, false)
	var spores := 0
	for h in g4.hazards:
		if h.kind == "spore":
			spores += 1
	_check(mush.dead and spores == 1, "포자 버섯을 쓰러뜨리면 포자 구름이 남음 (%d)" % spores)
	_step(g4, 1.2)
	_check(g4.player.damage_taken > 0.0, "포자 구름 안에 서 있으면 피해를 받음 (%.1f)" % g4.player.damage_taken)
	_step(g4, 5.0)
	var alive := 0
	for h in g4.hazards:
		if not h.dead:
			alive += 1
	_check(alive == 0, "포자 구름은 시간이 지나면 사라짐 (%d)" % alive)
	g4.queue_free()
	await _frames(2)

	# ── 스테이지 환경: 시간이 되면 물웅덩이와 가시 덩굴이 생긴다 ──
	var g5 := await _new_game("coco", 0, "greenhouse")
	g5.god = true
	g5.time = 39.9
	_step(g5, 0.2)
	var n_thorn := 0
	var n_pud := 0
	for h in g5.hazards:
		if h.kind == "thorns":
			n_thorn += 1
		elif h.kind == "puddle":
			n_pud += 1
	_check(n_thorn >= 3, "40초에 가시 덩굴이 3곳 이상 예고됨 (%d)" % n_thorn)
	_check(n_pud >= 3, "물웅덩이가 생김 (%d)" % n_pud)
	g5.queue_free()
	await _frames(2)

	# ── 보스: 여왕벌은 돌진하고 탄을 쏘고, 온실 나무는 뿌리 가시를 낸다 ──
	var g6 := await _new_game("coco", 0, "greenhouse")
	g6.god = true
	g6.player.weapons.clear()
	var queen := g6.spawn_enemy("queenbee", {"pos": g6.player.position + Vector2(300, 0)})
	var charged := false
	var start_shots := g6.shots.size()
	for i in 720:
		g6._update_game(1.0 / 60.0)
		charged = charged or queen.charge_state == 2
	_check(charged, "여왕벌이 돌진함")
	_check(g6.shots.size() > start_shots or g6.kills >= 0, "여왕벌이 꿀 탄막을 쏨")
	var bees := 0
	for e in g6.enemies:
		if e.kind == "bee" and not e.dead:
			bees += 1
	_check(bees >= 6, "여왕벌이 꿀벌을 불러냄 (%d마리)" % bees)
	g6.queue_free()
	await _frames(2)

	var g7 := await _new_game("coco", 0, "greenhouse")
	g7.god = true
	g7.player.weapons.clear()
	var tree := g7.spawn_enemy("greentree", {"pos": g7.player.position + Vector2(400, 0)})
	g7.final_boss_spawned = true
	var roots := 0
	var seen_shots := false
	for i in 900:
		g7._update_game(1.0 / 60.0)
		seen_shots = seen_shots or g7.shots.size() > 0
		for h in g7.hazards:
			if h.kind == "thorns" and h.source == "뿌리 가시":
				roots += 1
				break
	_check(roots > 0, "온실 나무가 뿌리 가시를 냄")
	_check(seen_shots, "온실 나무가 씨앗 탄막을 쏨")
	var sprouts := 0
	for e in g7.enemies:
		if e.kind == "sprout" and not e.dead:
			sprouts += 1
	_check(sprouts >= 6, "온실 나무가 새싹을 불러냄 (%d마리)" % sprouts)
	# 분노 상태
	tree.hp = tree.max_hp * 0.3
	_step(g7, 0.2)
	_check(tree.rage, "체력이 줄면 온실 나무가 분노함")
	# 최종 보스를 쓰러뜨리면 승리하고 기록됨
	SaveData.cleared = {"station": 0}
	g7._kill_enemy(tree)
	_check(g7.state == Main.State.WON, "온실 나무를 쓰러뜨리면 승리")
	_check(SaveData.cleared_tier_of("greenhouse") == 0, "승리하면 온실 구역 클리어가 기록됨")
	g7.queue_free()
	await _frames(2)
	SaveData.cleared = {}
