class_name Main
extends Node2D
## 게임 전체를 관리하는 메인 스크립트: 게임 루프, 스폰, 충돌, 레벨업, 보물상자, 보스, 승패

enum State { PLAYING, LEVELUP, CHEST, PAUSED, DEAD, WON }

const CELL := 56.0
const MAX_GEMS := 250
const MAX_FX := 120
const MAX_SHOTS := 250

var state: State = State.PLAYING
var time := 0.0
var kills := 0
var gold := 0
var pending_levelups := 0
var choices: Array = []
var spawn_acc := 0.0
var event_idx := 0
var final_boss_spawned := false
var prop_timer := 0.0
var shake_time := 0.0
var shake_power := 0.0
var _frame := 0
var last_hit_by := ""
var reaction_counts: Dictionary = {}
var stress := 0
var demo_reaction := ""
var _demo_t := 1.0
var reward := 0
var new_record := false
var _boss_music := false

var world: Node2D
var bg: Background
var player: Player
var camera: Camera2D
var hud: Hud

var enemies: Array[Enemy] = []
var gems: Array[Gem] = []
var projectiles: Array[Projectile] = []
var shots: Array[EnemyShot] = []
var chests: Array[Chest] = []
var pickups: Array[Pickup] = []
var props: Array[Prop] = []
var fx_list: Array[Fx] = []
var grid: Dictionary = {}
var _query_buf: Array[Enemy] = []

# 테스트용 실행 인자: -- --autoplay --hold --god --start-time=300 --build=whip:8,heart:3
var bot := false
var hold := false
var hold_chest := false
var god := false
var _bot_log_t := 0.0
var _bot_frame_us := 0
var _bot_frames := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()

	world = Node2D.new()
	add_child(world)
	bg = Background.new()
	world.add_child(bg)

	var char_id := SaveData.selected_char
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--char="):
			char_id = a.substr(7)
	player = Player.new()
	player.setup(char_id)
	world.add_child(player)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	player.add_child(camera)

	hud = Hud.new()
	add_child(hud)
	hud.choice_selected.connect(_on_choice_selected)
	hud.restart_pressed.connect(_restart)
	hud.resume_pressed.connect(_toggle_pause)
	hud.chest_closed.connect(_on_chest_closed)
	hud.menu_pressed.connect(_to_menu)

	player.add_weapon(str(GameData.character(char_id).weapon))
	_parse_debug_args()
	_refresh_inventory()
	Sfx.play_music("game")
	if "--show-pause" in OS.get_cmdline_user_args():
		_toggle_pause.call_deferred()    # 테스트 전용: 일시정지 화면으로 시작


func _parse_debug_args() -> void:
	var args := OS.get_cmdline_user_args()
	bot = "--autoplay" in args
	hold = "--hold" in args
	hold_chest = "--hold-chest" in args
	god = "--god" in args
	for a in args:
		if a.begins_with("--stress="):
			stress = int(a.substr(9))
		elif a.begins_with("--demo-reaction="):
			demo_reaction = a.substr(16)    # 테스트 전용: 지정한 반응을 계속 일으킨다
	for a in args:
		if a.begins_with("--start-time="):
			time = float(a.substr(13))
			while event_idx < GameData.EVENTS.size() and float(GameData.EVENTS[event_idx].time) < time:
				event_idx += 1
		elif a.begins_with("--build="):
			player.weapons.clear()
			for entry in a.substr(8).split(","):
				var parts := entry.split(":")
				var id := parts[0]
				var lv := int(parts[1]) if parts.size() > 1 else 1
				if GameData.WEAPONS.has(id):
					var w := player.add_weapon(id)
					w.level = clampi(lv, 1, w.max_level())
					w.recompute()
				elif GameData.PASSIVES.has(id):
					player.passives[id] = lv
			player.recalc_stats()
			player.hp = player.max_hp


func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
	}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for k: int in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(action, ev)
	# 게임패드 왼쪽 스틱
	var axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action: String in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axes[action][0] as JoyAxis
		jm.axis_value = axes[action][1]
		InputMap.action_add_event(action, jm)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE, KEY_P:
				_toggle_pause()
			KEY_1, KEY_2, KEY_3:
				if state == State.LEVELUP:
					_on_choice_selected(int(event.keycode) - int(KEY_1))
			KEY_F11:
				var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		hud.show_pause(_status_text())
	elif state == State.PAUSED:
		state = State.PLAYING
		hud.hide_pause()


func _restart() -> void:
	get_tree().reload_current_scene()


func _to_menu() -> void:
	Sfx.stop_music()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


# ─────────────────────────────────────────────
# 메인 루프
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	var t0 := Time.get_ticks_usec()
	if state == State.PLAYING:
		_update_game(delta)
	hud.update_info(player, time, kills, gold)
	_update_boss_bar()
	if bot:
		_bot_step(delta)
		_bot_frame_us += Time.get_ticks_usec() - t0
		_bot_frames += 1


func _update_game(delta: float) -> void:
	time += delta
	_frame += 1

	var input := _bot_input() if bot else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.step(delta, input)
	if god:
		player.hp = player.max_hp

	_rebuild_grid()
	if demo_reaction != "":
		_demo_t -= delta
		if _demo_t <= 0.0:
			_demo_t = 1.6
			_run_demo()
	_spawn(delta)
	_run_events()
	_update_enemies(delta)
	for w in player.weapons:
		w.update(delta, self)
	_update_projectiles(delta)
	_update_shots(delta)
	_update_gems(delta)
	_update_pickups()
	_update_props(delta)
	_update_fx(delta)
	_cleanup()

	# 카메라 흔들림 / 배경
	if shake_time > 0.0:
		shake_time -= delta
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_power * clampf(shake_time / 0.25, 0.0, 1.0)
	else:
		camera.offset = Vector2.ZERO
	bg.cam_pos = player.position
	bg.view_size = get_viewport_rect().size
	bg.t = time
	bg.queue_redraw()

	if player.hp <= 0.0:
		if player.revives > 0:
			_revive()
		else:
			_finish(false)


func _revive() -> void:
	player.revives -= 1
	player.hp = player.max_hp * 0.5
	player.invuln = 2.5
	# 주변 적을 쓸어내고 탄을 지운다
	for e in enemies:
		if not e.dead and e.boss == "" and e.position.distance_squared_to(player.position) < 320.0 * 320.0:
			e.dead = true
	for sh in shots:
		sh.dead = true
	add_fx(Fx.ring(player.position, Color(1.0, 0.95, 0.6), 320.0, 0.7))
	hud.show_banner("부활!", Color(1.0, 0.95, 0.5))
	Sfx.play("evolve")
	shake(6.0, 0.3)


## 테스트 전용: 가까운 적에게 두 무기의 속성을 차례로 적용해 반응을 일으킨다
func _run_demo() -> void:
	var pairs := {
		"gel+shock": ["gelgun", "bolt"], "cold+heat": ["canister", "torch"],
		"gel+heat": ["gelgun", "torch"], "cold+shock": ["canister", "bolt"],
		"overload": ["gelgun", "satellite"],
	}
	if not pairs.has(demo_reaction):
		return
	var near := nearest_enemies(player.position, 1, 500.0)
	if near.is_empty():
		return
	var target: Enemy = near[0]
	var ids: Array = pairs[demo_reaction]
	_apply_element(target, Weapon.new(ids[0]), 12.0)
	_apply_element(target, Weapon.new(ids[1]), 12.0)
	print("[demo] %.2f" % time)


func shake(power: float, duration: float = 0.25) -> void:
	if not SaveData.settings.screen_shake:
		return
	shake_power = power
	shake_time = duration


func _update_boss_bar() -> void:
	for e in enemies:
		if e.boss != "" and not e.dead:
			hud.set_boss(str(GameData.ENEMIES[e.kind].name), e.hp / e.max_hp)
			if not _boss_music and state == State.PLAYING:
				_boss_music = true
				Sfx.play_music("boss")
			return
	hud.clear_boss()
	if _boss_music and state == State.PLAYING:
		_boss_music = false
		Sfx.play_music("game")


# ─────────────────────────────────────────────
# 공간 분할 그리드 (충돌/탐색 최적화)
# ─────────────────────────────────────────────
func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


func _rebuild_grid() -> void:
	grid.clear()
	for e in enemies:
		var key := _cell_of(e.position)
		if grid.has(key):
			(grid[key] as Array).append(e)
		else:
			grid[key] = [e]


## pos 반경 안 셀에 있는 적들 (셀 단위 근사이므로 정확한 거리 판정은 호출 측에서)
func query_enemies(pos: Vector2, radius: float) -> Array[Enemy]:
	_query_buf.clear()
	var c0 := _cell_of(pos - Vector2(radius, radius))
	var c1 := _cell_of(pos + Vector2(radius, radius))
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var arr: Variant = grid.get(Vector2i(cx, cy))
			if arr == null:
				continue
			for e: Enemy in arr:
				_query_buf.append(e)
	return _query_buf


func nearest_enemies(pos: Vector2, count: int, max_dist: float) -> Array:
	var result: Array = []
	var used := {}
	var max2 := max_dist * max_dist
	for _i in count:
		var best: Enemy = null
		var best_d := max2
		for e in enemies:
			if e.dead or used.has(e):
				continue
			var d := e.position.distance_squared_to(pos)
			if d < best_d:
				best_d = d
				best = e
		if best == null:
			break
		used[best] = true
		result.append(best)
	return result


## 화면 안(mult 배)에 있는 무작위 적 하나
func random_enemy_in_view(mult: float = 1.0) -> Enemy:
	if enemies.is_empty():
		return null
	var half := get_viewport_rect().size * 0.5 * mult
	for _i in 24:
		var e := enemies[randi() % enemies.size()]
		if e.dead:
			continue
		var d := (e.position - player.position).abs()
		if d.x < half.x and d.y < half.y:
			return e
	return null


# ─────────────────────────────────────────────
# 적 스폰 / 이벤트
# ─────────────────────────────────────────────
func _spawn(delta: float) -> void:
	if stress > 0:
		# 성능 테스트: 정해진 수만큼 적을 계속 채운다
		var kinds := ["moth", "jelly", "drone", "bubble", "hound", "turret", "cube"]
		var made := 0
		while enemies.size() < stress and made < 20:
			spawn_enemy(kinds[randi() % kinds.size()])
			made += 1
		return
	var wave := GameData.wave_for(time)
	var rate := float(wave.rate) * (0.45 if final_boss_spawned else 1.0)
	spawn_acc += rate * delta
	var types: Array = wave.types
	while spawn_acc >= 1.0:
		spawn_acc -= 1.0
		if enemies.size() < int(wave.max):
			var kind: String = types[randi() % types.size()]
			# 마법사가 너무 많으면 화면이 탄막으로 가득 차므로 동시 마릿수를 제한
			if kind == "turret" and _count_kind("turret") >= 3 + int(time / 120.0):
				kind = "drone"
			spawn_enemy(kind)
	# 초반에도 화면이 너무 한산하지 않도록 최소 적 수 유지
	if enemies.size() < 6 + int(time / 10.0):
		spawn_acc += delta * 3.0


func _count_kind(kind: String) -> int:
	var n := 0
	for e in enemies:
		if e.kind == kind and not e.dead:
			n += 1
	return n


func _edge_pos() -> Vector2:
	var half := get_viewport_rect().size / 2.0
	var r := half.length() + 40.0
	return player.position + Vector2.from_angle(randf() * TAU) * r


## opts: pos(Vector2), elite(bool), straight(Vector2)
func spawn_enemy(kind: String, opts: Dictionary = {}) -> Enemy:
	var e := Enemy.new()
	e.setup(kind, 1.0 + time / 180.0, opts.get("elite", false))
	e.position = opts.get("pos", _edge_pos())
	if opts.has("straight"):
		e.straight = opts.straight
	world.add_child(e)
	enemies.append(e)
	return e


func _run_events() -> void:
	while event_idx < GameData.EVENTS.size() and time >= float(GameData.EVENTS[event_idx].time):
		_run_event(GameData.EVENTS[event_idx])
		event_idx += 1


func _run_event(ev: Dictionary) -> void:
	match str(ev.type):
		"elite":
			_spawn_elites(int(ev.count))
		"ring":
			_spawn_ring(str(ev.enemy), int(ev.count), str(ev.get("text", "")))
		"stream":
			_spawn_stream(str(ev.enemy), int(ev.count))
		"boss":
			_spawn_boss(str(ev.enemy))


func _spawn_elites(count: int) -> void:
	var types: Array = GameData.wave_for(time).types
	var best: String = types[0]
	for t: String in types:
		if float(GameData.ENEMIES[t].hp) > float(GameData.ENEMIES[best].hp):
			best = t
	for _i in count:
		spawn_enemy(best if randf() < 0.5 else types[randi() % types.size()], {"elite": true})
	hud.show_banner("강력한 적이 나타났다!", Color(1, 0.8, 0.3))


## 플레이어를 둘러싸는 원형 포위
func _spawn_ring(kind: String, count: int, text: String) -> void:
	var r := get_viewport_rect().size.length() / 2.0 + 30.0
	for i in count:
		var a := TAU * float(i) / float(count)
		spawn_enemy(kind, {"pos": player.position + Vector2.from_angle(a) * r})
	if text != "":
		hud.show_banner(text, Color(1, 0.55, 0.55))


## 화면을 가로지르는 돌진 무리
func _spawn_stream(kind: String, count: int) -> void:
	var from_left := randf() < 0.5
	var sgn := -1.0 if from_left else 1.0
	var view := get_viewport_rect().size
	var sx := player.position.x + sgn * (view.x / 2.0 + 60.0)
	var spd := float(GameData.ENEMIES[kind].speed) * 1.8
	for _i in count:
		var pos := Vector2(sx + sgn * randf_range(0.0, 250.0), player.position.y + randf_range(-view.y * 0.45, view.y * 0.45))
		spawn_enemy(kind, {"pos": pos, "straight": Vector2(-sgn * spd, 0.0)})
	hud.show_banner("무리가 돌진해 온다!", Color(1, 0.55, 0.55))


func _spawn_boss(kind: String) -> void:
	spawn_enemy(kind)
	if kind == "core":
		final_boss_spawned = true
	hud.show_banner("보스 등장: %s" % GameData.ENEMIES[kind].name, Color(1, 0.3, 0.35))
	Sfx.play("warning")


# ─────────────────────────────────────────────
# 적 이동 / 공격
# ─────────────────────────────────────────────
func _update_enemies(delta: float) -> void:
	var ppos := player.position
	for e in enemies:
		if e.dead:
			continue
		var to := ppos - e.position
		var dist := to.length()
		var dir := to / maxf(dist, 0.001)
		if not e.status.is_empty() or e.stun > 0.0:
			_tick_status(e, delta)
			if e.dead:
				continue
		var vel := Vector2.ZERO
		if e.straight != Vector2.ZERO:
			vel = e.straight
		elif e.ranged:
			# 적당한 거리를 유지하며 탄을 쏜다
			if dist > 270.0:
				vel = dir * e.speed
			elif dist < 180.0:
				vel = -dir * e.speed * 0.6
			else:
				vel = Vector2(-dir.y, dir.x) * e.speed * 0.4
			if e.stun <= 0.0:
				e.shoot_t -= delta
			if e.shoot_t <= 0.0 and dist < 540.0:
				e.shoot_t = 3.2
				add_shot(EnemyShot.make(e.position, dir * 150.0, 5.0, Color(0.65, 0.45, 1.0), 6.0, "포탑 봇"))
		else:
			vel = dir * e.speed
		vel *= e.speed_mult()
		if e.boss != "":
			_boss_ai(e, delta, dir)
		vel += e.knock

		# 겹침 방지 (주변 적끼리 살짝 밀어냄). 비용이 커서 적마다 2프레임에 한 번만 계산
		if (e.get_instance_id() + _frame) % 2 == 0:
			var push := Vector2.ZERO
			var ck := _cell_of(e.position)
			for ox in range(-1, 2):
				for oy in range(-1, 2):
					var arr: Variant = grid.get(Vector2i(ck.x + ox, ck.y + oy))
					if arr == null:
						continue
					for o: Enemy in arr:
						if o == e:
							continue
						var diff := e.position - o.position
						var d2 := diff.length_squared()
						var rr := (e.radius + o.radius) * 0.9
						if d2 < rr * rr and d2 > 0.0001:
							var d := sqrt(d2)
							push += diff / d * (rr - d)
			e.push = push
		vel += e.push * 8.0

		e.position += vel * delta
		e.knock = e.knock.move_toward(Vector2.ZERO, 700.0 * delta)

		# 바라보는 방향 / 걷는 흔들림
		var fx_dir := signf(to.x) if absf(to.x) > 2.0 else e.face
		e.face = fx_dir
		e.scale = Vector2(fx_dir, 1.0 + 0.07 * sin(time * 9.0 + e.wobble))

		if e.flash > 0.0:
			e.flash -= delta
			if e.flash <= 0.0:
				e.queue_redraw()

		# 접촉 피해
		if dist < e.radius + Player.RADIUS - 4.0 and e.stun <= 0.0:
			_hurt_player(e.damage, ("엘리트 " if e.elite else "") + str(GameData.ENEMIES[e.kind].name))

		if dist > 1400.0:
			if e.straight != Vector2.ZERO:
				e.dead = true    # 돌진 무리는 지나가면 조용히 사라짐
			else:
				e.position = _edge_pos()


func _hurt_player(amount: float, source: String) -> void:
	if player.take_damage(amount):
		last_hit_by = source
		hud.flash_damage(clampf(0.45 + amount / 40.0, 0.45, 1.0))
		Sfx.play("hurt", 0.05)
		shake(4.0, 0.2)
		add_fx(Fx.ring(player.position, Color(1, 0.3, 0.35), 30.0, 0.25))


func _boss_ai(e: Enemy, delta: float, dir: Vector2) -> void:
	var ratio := e.hp / e.max_hp
	e.skill_t -= delta
	e.skill2_t -= delta
	match e.boss:
		"jellyking":
			var rage := ratio < 0.4
			if e.skill_t <= 0.0:
				e.skill_t = 3.0 if rage else 4.2
				_enemy_ring(e.position, 12 if rage else 9, 150.0, 10.0, e.spin, "젤리 킹")
				e.spin += 0.25
			if e.skill2_t <= 0.0:
				e.skill2_t = 8.0
				for i in 8:
					spawn_enemy("moth", {"pos": e.position + Vector2.from_angle(TAU * float(i) / 8.0) * 60.0})
		"core":
			var rage := ratio < 0.35
			if rage and e.speed < 90.0:
				e.speed = 92.0
				hud.show_banner("컴퓨터가 폭주한다!", Color(1, 0.3, 0.3))
			if e.skill_t <= 0.0:
				e.skill_t = 2.4 if rage else 3.2
				_enemy_ring(e.position, 20 if rage else 14, 165.0, 14.0, e.spin, "폭주 메인 컴퓨터")
				e.spin += 0.2
				for k in [-0.25, 0.0, 0.25]:
					add_shot(EnemyShot.make(e.position, dir.rotated(k) * 230.0, 14.0, Color(1.0, 0.55, 0.15), 8.0, "폭주 메인 컴퓨터"))
			if e.skill2_t <= 0.0:
				e.skill2_t = 6.0 if rage else 8.0
				for i in 6:
					spawn_enemy("bubble", {"pos": e.position + Vector2.from_angle(TAU * float(i) / 6.0) * 90.0})


func _enemy_ring(pos: Vector2, n: int, speed: float, dmg: float, offset: float, src: String) -> void:
	for i in n:
		var a := offset + TAU * float(i) / float(n)
		add_shot(EnemyShot.make(pos, Vector2.from_angle(a) * speed, dmg, Color(1.0, 0.3, 0.45), 7.0, src))


func add_shot(s: EnemyShot) -> void:
	if shots.size() >= MAX_SHOTS:
		s.free()
		return
	Sfx.play("eshot", 0.08)
	world.add_child(s)
	shots.append(s)


func _update_shots(delta: float) -> void:
	var ppos := player.position
	for s in shots:
		if s.dead:
			continue
		s.position += s.vel * delta
		s.life -= delta
		var d2 := s.position.distance_squared_to(ppos)
		if s.life <= 0.0 or d2 > 1600.0 * 1600.0:
			s.dead = true
			continue
		var rr := s.radius + Player.RADIUS - 2.0
		if d2 < rr * rr:
			s.dead = true
			_hurt_player(s.damage, s.source)


# ─────────────────────────────────────────────
# 피해 / 처치
# ─────────────────────────────────────────────
func damage_enemy(e: Enemy, dmg: float, weapon: Weapon, dir: Vector2, kb: float, apply_element: bool = true, num_color: Color = Color.WHITE) -> void:
	if e.dead:
		return
	e.hp -= dmg
	if e.flash <= 0.0:
		e.queue_redraw()
	e.flash = 0.08
	e.knock += dir * 170.0 * kb * (1.0 - e.kb_resist)
	if weapon != null:
		weapon.damage_dealt += dmg
	if SaveData.settings.damage_numbers:
		add_fx(Fx.number(e.position + Vector2(0, -e.radius - 6), dmg, num_color, num_color != Color.WHITE))
	if apply_element:
		Sfx.play("hit", 0.1)
		if weapon != null and weapon.element != "":
			_apply_element(e, weapon, dmg)
	if e.hp <= 0.0 and not e.dead:
		_kill_enemy(e)


# ─────────────────────────────────────────────
# 속성 상태와 반응
# ─────────────────────────────────────────────
func _pair_key(a: String, b: String) -> String:
	return a + "+" + b if a < b else b + "+" + a


## 무기의 속성을 적에게 적용한다. 이미 붙어 있는 다른 속성과 반응하면 그 반응이 터진다.
func _apply_element(e: Enemy, w: Weapon, dmg: float) -> void:
	var elem := w.element
	var mult := float(player.stats["reaction"])
	if elem == "plasma":
		# 플라즈마는 상태를 남기지 않고, 붙어 있는 상태를 모두 터뜨린다
		var n := e.status.size() + (1 if e.stun > 0.0 else 0)
		if n > 0:
			e.status.clear()
			e.stun = 0.0
			e.burn_dps = 0.0
			e.queue_redraw()
			_react("overload", e, w, dmg, mult, n)
		return
	for other: String in e.status.keys():
		if other == elem:
			continue
		var key := _pair_key(elem, other)
		if GameData.REACTIONS.has(key):
			e.status.erase(other)
			if other == "heat":
				e.burn_dps = 0.0
			e.queue_redraw()
			_react(key, e, w, dmg, mult, 1)
			return
	_add_status(e, elem, dmg, w)


func _add_status(e: Enemy, elem: String, dmg: float, w: Weapon) -> void:
	if e.dead:
		return
	var dur: float = GameData.STATUS_TIME[elem]
	if e.boss != "":
		dur *= 0.5
	e.status[elem] = maxf(float(e.status.get(elem, 0.0)), dur)
	if elem == "heat":
		e.burn_dps = maxf(e.burn_dps, dmg * 0.5)
		e.burn_src = w
	e.queue_redraw()


func _stun(e: Enemy, dur: float) -> void:
	if e.dead:
		return
	if e.boss != "":
		dur *= 0.25
	e.stun = maxf(e.stun, dur)
	e.queue_redraw()


func _tick_status(e: Enemy, delta: float) -> void:
	var changed := false
	for k: String in e.status.keys():
		e.status[k] = float(e.status[k]) - delta
		if float(e.status[k]) <= 0.0:
			e.status.erase(k)
			changed = true
			if k == "heat":
				e.burn_dps = 0.0
	if e.stun > 0.0:
		e.stun -= delta
		if e.stun <= 0.0:
			changed = true
	if e.status.has("heat"):
		e.burn_tick -= delta
		if e.burn_tick <= 0.0:
			e.burn_tick = 0.5
			damage_enemy(e, e.burn_dps * 0.5, e.burn_src, Vector2.ZERO, 0.0, false, Color(1.0, 0.65, 0.3))
	if changed:
		e.queue_redraw()


## 반응 효과 범위 검사용. 공유 버퍼를 쓰지 않아서 다른 반복문 안에서 호출해도 안전하다.
func _near_fresh(pos: Vector2, radius: float, exclude: Enemy = null) -> Array[Enemy]:
	var out: Array[Enemy] = []
	var r2 := radius * radius
	var c0 := _cell_of(pos - Vector2(radius, radius))
	var c1 := _cell_of(pos + Vector2(radius, radius))
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var arr: Variant = grid.get(Vector2i(cx, cy))
			if arr == null:
				continue
			for t: Enemy in arr:
				if t.dead or t == exclude:
					continue
				if t.position.distance_squared_to(pos) < r2:
					out.append(t)
	out.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.position.distance_squared_to(pos) < b.position.distance_squared_to(pos))
	return out


func _react(key: String, e: Enemy, w: Weapon, dmg: float, mult: float, n: int) -> void:
	var info: Dictionary = GameData.REACTIONS[key]
	var col: Color = info.color
	var pos := e.position
	reaction_counts[key] = int(reaction_counts.get(key, 0)) + 1
	add_fx(Fx.label(pos + Vector2(0, -e.radius - 44), "%s!" % info.name, col, 21.0))
	Sfx.play("react", 0.08)
	match key:
		"gel+shock":
			# 전도: 가까운 적 4마리에게 전기가 퍼진다
			damage_enemy(e, dmg * mult, w, Vector2.ZERO, 0.0, false, col)
			var hit := 0
			for t in _near_fresh(pos, 150.0, e):
				if hit >= 4:
					break
				add_fx(Fx.arc(pos, t.position, col))
				damage_enemy(t, dmg * 1.5 * mult, w, (t.position - pos).normalized(), 0.3, false, col)
				hit += 1
			add_fx(Fx.ring(pos, col, 40.0, 0.25))
		"cold+heat":
			# 열충격: 큰 피해와 작은 범위 폭발
			damage_enemy(e, dmg * 3.0 * mult, w, Vector2.ZERO, 0.0, false, col)
			for t in _near_fresh(pos, 75.0, e):
				damage_enemy(t, dmg * 1.2 * mult, w, (t.position - pos).normalized(), 0.6, false, col)
			add_fx(Fx.ring(pos, Color(0.6, 0.9, 1.0), 85.0, 0.3))
			add_fx(Fx.puff(pos, Color(1.0, 0.8, 0.6), 22.0))
			shake(3.0, 0.12)
		"gel+heat":
			# 점화: 범위 폭발하고 주변 적에게 불이 붙는다
			var victims := _near_fresh(pos, 85.0, e)
			victims.append(e)
			for t in victims:
				damage_enemy(t, dmg * 2.0 * mult, w, (t.position - pos).normalized(), 0.6, false, col)
				if not t.dead:
					_add_status(t, "heat", dmg, w)
			add_fx(Fx.ring(pos, col, 95.0, 0.35))
			add_fx(Fx.puff(pos, col, 26.0))
			shake(4.0, 0.15)
		"cold+shock":
			# 정지: 잠시 멈추고, 주변 적도 잠깐 멈춘다
			damage_enemy(e, dmg * 0.5 * mult, w, Vector2.ZERO, 0.0, false, col)
			_stun(e, 1.5)
			for t in _near_fresh(pos, 60.0, e):
				_stun(t, 0.8)
			add_fx(Fx.ring(pos, col, 70.0, 0.3))
		"overload":
			# 과부하: 붙어 있던 상태 수만큼 커지는 폭발
			var d := dmg * (0.75 + 0.6 * float(n)) * mult
			var victims := _near_fresh(pos, 95.0, e)
			victims.append(e)
			for t in victims:
				damage_enemy(t, d, w, (t.position - pos).normalized(), 0.8, false, col)
			add_fx(Fx.ring(pos, col, 105.0, 0.35))
			add_fx(Fx.puff(pos, col, 24.0))
			shake(4.0, 0.15)


func _kill_enemy(e: Enemy) -> void:
	e.dead = true
	e.visible = false
	kills += 1
	var big := e.elite or e.boss != ""
	Sfx.play("kill", 0.12)
	add_fx(Fx.puff(e.position, e.color, e.radius * (2.4 if big else 1.6)))
	if e.boss == "core":
		add_fx(Fx.ring(e.position, Color(1, 0.8, 0.4), 260.0, 0.8))
		shake(10.0, 0.5)
		_finish(true)
		return
	if e.boss != "":
		for _i in 10:
			spawn_gem(e.position + Vector2(randf_range(-40, 40), randf_range(-40, 40)), maxi(1, e.xp / 10))
		spawn_chest(e.position, 3)
		hud.show_banner("%s 격파!" % GameData.ENEMIES[e.kind].name, Color(1, 0.85, 0.3))
		shake(8.0, 0.4)
		return
	spawn_gem(e.position, e.xp)
	if e.elite:
		spawn_chest(e.position + Vector2(0, 8), 1)
	elif randf() < 0.015 * float(player.stats["luck"]):
		spawn_pickup("coin", e.position)


func heal_player(amount: float) -> void:
	if amount <= 0.0 or player.hp >= player.max_hp:
		return
	player.heal(amount)
	if amount >= 5.0:
		add_fx(Fx.number(player.position + Vector2(0, -30), amount, Color(0.4, 1.0, 0.5)))


# ─────────────────────────────────────────────
# 투사체
# ─────────────────────────────────────────────
func add_projectile(p: Projectile) -> void:
	world.add_child(p)
	projectiles.append(p)


func _update_projectiles(delta: float) -> void:
	for p in projectiles:
		if p.dead:
			continue
		p.age += delta
		p.life -= delta
		if p.life <= 0.0:
			p.dead = true
			continue
		if not p.managed:
			if p.curve != 0.0:
				p.vel = p.vel.rotated(p.curve * delta)
			p.vel.y += p.gravity * delta
			p.position += p.vel * delta
		if p.spin != 0.0:
			p.rotation += p.spin * delta
		if p.kind == "zone":
			p.queue_redraw()
		elif p.kind == "book":
			p.scale = Vector2.ONE * p.fade
		if p.age < p.delay:
			continue

		hit_props(p.position, p.radius)
		if p.hit_ids.size() > 150:
			_prune_hits(p)
		for e in query_enemies(p.position, p.radius + 30.0):
			if e.dead:
				continue
			var id := e.get_instance_id()
			if p.hit_ids.has(id) and float(p.hit_ids[id]) > p.age:
				continue
			var rr := p.radius + e.radius
			if e.position.distance_squared_to(p.position) < rr * rr:
				p.hit_ids[id] = p.age + p.hit_interval if p.hit_interval > 0.0 else INF
				var kdir := p.vel.normalized() if p.vel != Vector2.ZERO else (e.position - p.position).normalized()
				damage_enemy(e, p.damage, p.weapon, kdir, p.kb)
				if p.kind == "bolt" or p.kind == "knife":
					add_fx(Fx.puff(p.position, p.color, 8.0))
				if p.pierce < 900:
					p.pierce -= 1
					if p.pierce <= 0:
						p.dead = true
						break


func _prune_hits(p: Projectile) -> void:
	for id: int in p.hit_ids.keys():
		if float(p.hit_ids[id]) <= p.age:
			p.hit_ids.erase(id)


# ─────────────────────────────────────────────
# 경험치 보석
# ─────────────────────────────────────────────
func spawn_gem(pos: Vector2, value: int) -> void:
	if gems.size() >= MAX_GEMS:
		# 너무 많으면 기존 보석에 합쳐서 성능 유지
		gems[randi() % gems.size()].add_value(value)
		return
	var gem := Gem.new()
	gem.position = pos + Vector2(randf_range(-6, 6), randf_range(-6, 6))
	gem.value = value
	world.add_child(gem)
	gems.append(gem)


func _update_gems(delta: float) -> void:
	var magnet_r := GameData.BASE_MAGNET * float(player.stats["magnet"])
	var magnet_r2 := magnet_r * magnet_r
	var ppos := player.position
	for g in gems:
		if g.dead:
			continue
		var d2 := g.position.distance_squared_to(ppos)
		if not g.attracted and d2 < magnet_r2:
			g.attracted = true
		if g.attracted:
			g.pull_speed = minf(g.pull_speed + 1400.0 * delta, 720.0)
			g.position = g.position.move_toward(ppos, g.pull_speed * delta)
			if d2 < 14.0 * 14.0:
				g.dead = true
				g.visible = false
				Sfx.play("gem", 0.1)
				gain_xp(float(g.value))
		else:
			g.t += delta * 4.0
			g.scale = Vector2.ONE * (1.0 + 0.08 * sin(g.t))


func gain_xp(amount: float) -> void:
	player.xp += amount * float(player.stats["growth"])
	while player.xp >= GameData.xp_for_level(player.level):
		player.xp -= GameData.xp_for_level(player.level)
		player.level += 1
		pending_levelups += 1
	if pending_levelups > 0 and state == State.PLAYING:
		_open_levelup()


# ─────────────────────────────────────────────
# 상자 / 아이템 / 화로
# ─────────────────────────────────────────────
func spawn_chest(pos: Vector2, tier: int) -> void:
	var c := Chest.new()
	c.position = pos
	c.tier = tier
	world.add_child(c)
	chests.append(c)


func spawn_pickup(kind: String, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.position = pos
	world.add_child(p)
	pickups.append(p)


func spawn_prop() -> void:
	var pr := Prop.new()
	pr.position = player.position + Vector2.from_angle(randf() * TAU) * randf_range(350.0, 700.0)
	world.add_child(pr)
	props.append(pr)


## 무기가 화로를 맞췄는지 검사. 겹치면 부순다.
func hit_props(pos: Vector2, radius: float) -> void:
	for pr in props:
		if pr.dead:
			continue
		var rr := radius + 14.0
		if pr.position.distance_squared_to(pos) < rr * rr:
			_break_prop(pr)


func _break_prop(pr: Prop) -> void:
	pr.dead = true
	pr.visible = false
	add_fx(Fx.puff(pr.position, Color(1.0, 0.6, 0.2), 16.0))
	var luck := float(player.stats["luck"])
	var table := [["battery", 45.0], ["coin", 30.0], ["magnet", 12.0 * luck], ["pulse", 8.0 * luck]]
	var total := 0.0
	for r in table:
		total += float(r[1])
	var roll := randf() * total
	var kind := "battery"
	for r in table:
		roll -= float(r[1])
		if roll <= 0.0:
			kind = str(r[0])
			break
	spawn_pickup(kind, pr.position)


func _update_props(delta: float) -> void:
	prop_timer -= delta
	if prop_timer <= 0.0:
		prop_timer = 2.0
		var near := 0
		for pr in props:
			if not pr.dead and pr.position.distance_squared_to(player.position) < 900.0 * 900.0:
				near += 1
		if near < 4:
			spawn_prop()
	for pr in props:
		if pr.position.distance_squared_to(player.position) > 1600.0 * 1600.0:
			pr.dead = true


func _update_pickups() -> void:
	var ppos := player.position
	for pk in pickups:
		if pk.dead:
			continue
		if pk.position.distance_squared_to(ppos) < 26.0 * 26.0:
			pk.dead = true
			pk.visible = false
			_collect(pk.kind)
	for c in chests:
		if c.dead:
			continue
		if c.position.distance_squared_to(ppos) < 30.0 * 30.0:
			c.dead = true
			c.visible = false
			_open_chest(c.tier)
			return


func _collect(kind: String) -> void:
	match kind:
		"battery":
			Sfx.play("heal")
			heal_player(30.0)
			add_fx(Fx.ring(player.position, Color(0.4, 1.0, 0.5), 40.0, 0.35))
		"magnet":
			Sfx.play("select")
			for g in gems:
				g.attracted = true
			add_fx(Fx.ring(player.position, Color(0.5, 0.7, 1.0), 120.0, 0.5))
			hud.show_banner("경험치 보석을 모두 끌어당긴다!", Color(0.6, 0.8, 1.0))
		"pulse":
			_bomb()
		"coin":
			Sfx.play("coin")
			gold += int(round(10.0 * float(player.stats["greed"])))


func _bomb() -> void:
	Sfx.play("boom")
	var half := get_viewport_rect().size * 0.5
	for e in enemies:
		if e.dead:
			continue
		var d := (e.position - player.position).abs()
		if d.x < half.x and d.y < half.y:
			damage_enemy(e, 100.0, null, (e.position - player.position).normalized(), 0.5)
	add_fx(Fx.ring(player.position, Color(1.0, 0.85, 0.4), 420.0, 0.6))
	shake(8.0, 0.4)
	hud.show_banner("펄스 폭발!", Color(1.0, 0.75, 0.3))


# ─────────────────────────────────────────────
# 이펙트
# ─────────────────────────────────────────────
func add_fx(f: Fx) -> void:
	if fx_list.size() >= MAX_FX:
		f.free()
		return
	world.add_child(f)
	fx_list.append(f)


func _update_fx(delta: float) -> void:
	for f in fx_list:
		if f.step(delta):
			f.visible = false


## dead 표시된 노드를 배열에서 빼고 화면에서도 제거
func _purge(arr: Array) -> void:
	var j := 0
	for i in arr.size():
		var o: Variant = arr[i]
		if o.dead:
			o.queue_free()
		else:
			arr[j] = o
			j += 1
	arr.resize(j)


func _cleanup() -> void:
	_purge(enemies)
	_purge(projectiles)
	_purge(gems)
	_purge(shots)
	_purge(chests)
	_purge(pickups)
	_purge(props)
	_purge(fx_list)


# ─────────────────────────────────────────────
# 레벨업 / 보물상자
# ─────────────────────────────────────────────
func _open_levelup() -> void:
	Sfx.play("levelup")
	add_fx(Fx.ring(player.position, Color(1.0, 0.9, 0.4), 90.0, 0.5))
	choices = _make_choices()
	state = State.LEVELUP
	hud.show_levelup(choices)


## 지금 얻을 수 있는 모든 강화 목록
func _upgrade_pool() -> Array:
	var pool: Array = []
	for w in player.weapons:
		if w.level < w.max_level():
			pool.append({
				"type": "weapon_up", "id": w.id,
				"title": "%s%s  Lv.%d → %d" % [w.def.name, _elem_tag(w.id), w.level, w.level + 1],
				"desc": w.level_up_text(),
			})
	if player.weapons.size() < GameData.MAX_WEAPONS:
		for id: String in GameData.WEAPONS:
			var d: Dictionary = GameData.WEAPONS[id]
			if d.get("evolved", false) or player.get_weapon(id) != null or _has_evolved_of(id):
				continue
			pool.append({"type": "weapon_new", "id": id, "title": "[신규 무기]  %s%s" % [d.name, _elem_tag(id)], "desc": d.desc})
	for id: String in GameData.PASSIVES:
		var d: Dictionary = GameData.PASSIVES[id]
		var lv: int = int(player.passives.get(id, 0))
		if lv >= int(d.max):
			continue
		if lv == 0 and player.passives.size() >= GameData.MAX_PASSIVES:
			continue
		var title: String = "%s  Lv.%d → %d" % [d.name, lv, lv + 1] if lv > 0 else "[신규 아이템]  %s" % d.name
		pool.append({"type": "passive", "id": id, "title": title, "desc": d.desc})
	return pool


## 무기 이름 옆에 붙는 속성 표시. 예: " [젤]"
func _elem_tag(weapon_id: String) -> String:
	var el := str(GameData.WEAPONS[weapon_id].get("element", ""))
	return "" if el == "" else " [%s]" % GameData.element_name(el)


func _has_evolved_of(base_id: String) -> bool:
	var into: String = GameData.WEAPONS[base_id].get("evolve", {}).get("into", "")
	return into != "" and player.get_weapon(into) != null


func _make_choices() -> Array:
	var pool := _upgrade_pool()
	if pool.is_empty():
		return [{"type": "heal", "id": "", "title": "치킨", "desc": "체력을 30% 회복합니다."}]
	pool.shuffle()
	return pool.slice(0, 3)


func _apply_choice(c: Dictionary) -> void:
	match str(c.type):
		"weapon_new":
			player.add_weapon(str(c.id))
		"weapon_up":
			var w := player.get_weapon(str(c.id))
			w.level += 1
			w.recompute()
		"passive":
			var pid := str(c.id)
			player.passives[pid] = int(player.passives.get(pid, 0)) + 1
			player.recalc_stats()
		"heal":
			player.heal(player.max_hp * 0.3)
	_refresh_inventory()


func _on_choice_selected(index: int) -> void:
	if state != State.LEVELUP or index < 0 or index >= choices.size():
		return
	Sfx.play("select")
	_apply_choice(choices[index])
	pending_levelups -= 1
	hud.hide_levelup()
	if pending_levelups > 0:
		_open_levelup()
	else:
		state = State.PLAYING


func _evolve_weapon(w: Weapon) -> Weapon:
	var into: String = (w.def.evolve as Dictionary).into
	var nw := Weapon.new(into)
	nw.damage_dealt = w.damage_dealt
	w.cleanup()
	player.weapons[player.weapons.find(w)] = nw
	return nw


func _open_chest(tier: int) -> void:
	var rewards: Array = []
	# 진화 가능한 무기가 있으면 먼저 진화
	for w in player.weapons.duplicate():
		if rewards.size() >= tier:
			break
		if w.can_evolve(player):
			var from_name: String = w.def.name
			var nw := _evolve_weapon(w)
			rewards.append({"evo": true, "title": "%s → %s" % [from_name, nw.def.name], "desc": nw.def.desc})
	# 남은 칸은 무작위 강화
	while rewards.size() < tier:
		var pool := _upgrade_pool()
		if pool.is_empty():
			player.heal(player.max_hp * 0.3)
			rewards.append({"evo": false, "title": "치킨", "desc": "체력을 30% 회복했습니다."})
			break
		var c: Dictionary = pool[randi() % pool.size()]
		_apply_choice(c)
		rewards.append({"evo": false, "title": c.title, "desc": c.desc})
	_refresh_inventory()
	var evolved := false
	for r: Dictionary in rewards:
		if r.get("evo", false):
			evolved = true
	Sfx.play("evolve" if evolved else "chest")
	state = State.CHEST
	hud.show_chest(rewards)


func _on_chest_closed() -> void:
	if state != State.CHEST:
		return
	hud.hide_chest()
	if pending_levelups > 0:
		_open_levelup()
	else:
		state = State.PLAYING


func _refresh_inventory() -> void:
	var ws: PackedStringArray = []
	for w in player.weapons:
		ws.append("%s %d" % [w.def.name, w.level] if not w.is_evolved() else "★%s" % w.def.name)
	var ps: PackedStringArray = []
	for id: String in player.passives:
		ps.append("%s %d" % [GameData.PASSIVES[id].name, player.passives[id]])
	hud.set_inventory("무기  %s\n아이템  %s" % [" · ".join(ws), " · ".join(ps) if not ps.is_empty() else "-"])


# ─────────────────────────────────────────────
# 종료 / 결과
# ─────────────────────────────────────────────
func _finish(won: bool) -> void:
	if state == State.DEAD or state == State.WON:
		return
	state = State.WON if won else State.DEAD
	hud.hide_levelup()
	hud.hide_chest()
	reward = GameData.run_reward(gold, kills, time, won)
	new_record = SaveData.record_run(time, kills, player.level, reward, won)
	Sfx.stop_music()
	Sfx.play("victory" if won else "death")
	hud.show_gameover(won, _summary_text())
	if bot:
		print("[bot] 종료: %s | %s | 처치 %d | 레벨 %d | 마지막 피해: %s" % ["승리" if won else "사망", Util.fmt_time(time), kills, player.level, last_hit_by])
		get_tree().quit()


func _status_text() -> String:
	var lines: PackedStringArray = []
	lines.append("생존 시간  %s    처치  %d    레벨  %d    골드  %d" % [Util.fmt_time(time), kills, player.level, gold])
	lines.append("")
	lines.append("무기")
	for w in player.weapons:
		lines.append("  %s  Lv.%d" % [w.def.name, w.level] if not w.is_evolved() else "  ★ %s  (진화)" % w.def.name)
	lines.append("아이템")
	if player.passives.is_empty():
		lines.append("  (없음)")
	for id: String in player.passives:
		lines.append("  %s  Lv.%d" % [GameData.PASSIVES[id].name, player.passives[id]])
	return "\n".join(lines)


func _summary_text() -> String:
	var lines: PackedStringArray = []
	lines.append("생존 시간   %s" % Util.fmt_time(time))
	lines.append("처치 수     %d" % kills)
	lines.append("도달 레벨   %d" % player.level)
	lines.append("주운 동전   %d" % gold)
	if state == State.DEAD and last_hit_by != "":
		lines.append("사망 원인   %s" % last_hit_by)
	lines.append("")
	lines.append("무기별 누적 피해")
	for w in player.weapons:
		lines.append("  %s Lv.%d   %d" % [w.def.name, w.level, int(w.damage_dealt)])
	lines.append("")
	lines.append("획득 골드   +%d   (보유 %d)" % [reward, SaveData.gold])
	if new_record:
		lines.append("★ 최고 생존 기록 갱신!")
	return "\n".join(lines)


# ─────────────────────────────────────────────
# 자동 플레이 (테스트용)
# ─────────────────────────────────────────────
func _bot_input() -> Vector2:
	# 가까운 적에게서 멀어지고, 안전하면 상자/아이템/보석으로 이동
	var flee := Vector2.ZERO
	for e in enemies:
		var d := e.position - player.position
		var l := d.length()
		if l < 110.0 and l > 0.01:
			flee -= d / l * (110.0 - l) / 110.0
	var seek := Vector2.ZERO
	var best_d := 700.0 * 700.0
	for g in gems:
		var d2 := g.position.distance_squared_to(player.position)
		if d2 < best_d:
			best_d = d2
			seek = (g.position - player.position).normalized()
	for c in chests:
		if not c.dead:
			seek = (c.position - player.position).normalized() * 2.0
			break
	var circle := Vector2.from_angle(time * 0.6 + PI / 2.0) * 0.2
	var v := flee * 1.3 + seek * 1.0 + circle
	return v.limit_length(1.0)


func _bot_step(delta: float) -> void:
	if state == State.LEVELUP and not hold:
		# 사람처럼 무기와 공격 관련 아이템을 우선 선택
		var best := 0
		var best_score := -1
		for i in choices.size():
			var c: Dictionary = choices[i]
			var score := randi() % 3
			match str(c.type):
				"weapon_up": score += 10
				"weapon_new": score += 9
				"passive":
					if str(c.id) in ["cell", "fan", "lens", "jet", "tank", "cloner", "catalyst"]:
						score += 6
			if score > best_score:
				best_score = score
				best = i
		_on_choice_selected(best)
	elif state == State.CHEST and not hold and not hold_chest:
		_on_chest_closed()
	_bot_log_t += delta
	if _bot_log_t >= 30.0 and state == State.PLAYING:
		_bot_log_t = 0.0
		var avg_ms := float(_bot_frame_us) / maxf(_bot_frames, 1) / 1000.0
		var dmg_info := ""
		for w in player.weapons:
			dmg_info += " %s.%d=%d" % [w.id, w.level, int(w.damage_dealt)]
		print("[bot] %s | LV %d | HP %d/%d | 적 %d | 보석 %d | 처치 %d | %.2fms | 반응 %s |%s" % [
			Util.fmt_time(time), player.level, int(player.hp), int(player.max_hp),
			enemies.size(), gems.size(), kills, avg_ms, str(reaction_counts), dmg_info])
		_bot_frame_us = 0
		_bot_frames = 0
