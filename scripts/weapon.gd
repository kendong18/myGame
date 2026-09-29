class_name Weapon
extends RefCounted
## 플레이어가 가진 무기 하나. 종류별 동작은 이 파일 안에서 처리한다.

# 한 번 발동할 때 여러 발을 쏘는 무기의 발사 간격(초)
const GAPS := {"whip": 0.12, "wand": 0.08, "knife": 0.05, "axe": 0.12, "spiral": 0.0, "zone": 0.15, "lightning": 0.09}

var id := ""
var def: Dictionary = {}
var level := 1
var s: Dictionary = {}          # 현재 레벨의 수치
var timer := 0.4
var burst_left := 0
var burst_idx := 0
var burst_timer := 0.0
var targets: Array = []
var tick := 0.0
var damage_dealt := 0.0
var angle := 0.0
var active := 0.0
var cool := 0.3
var books: Array = []

var g: Main
var p: Player


func _init(weapon_id: String) -> void:
	id = weapon_id
	def = GameData.WEAPONS[weapon_id]
	recompute()


func recompute() -> void:
	s = (def.base as Dictionary).duplicate()
	var lv_list: Array = def.levels
	for i in level - 1:
		var lv: Dictionary = lv_list[i]
		for k: String in lv:
			if k != "text":
				s[k] = s.get(k, 0.0) + lv[k]


func max_level() -> int:
	return (def.levels as Array).size() + 1


func level_up_text() -> String:
	var lv: Dictionary = (def.levels as Array)[level - 1]
	return lv.text


func is_evolved() -> bool:
	return def.get("evolved", false)


## 진화할 수 있는 상태인가 (최대 레벨 + 짝 패시브 보유)
func can_evolve(player: Player) -> bool:
	var ev: Variant = def.get("evolve")
	if ev == null or level < max_level():
		return false
	return int(player.passives.get(ev.passive, 0)) > 0


func cleanup() -> void:
	for b in books:
		if is_instance_valid(b):
			(b as Projectile).dead = true
	books.clear()


# ── 플레이어 스탯이 반영된 실제 수치 ─────────
func _dmg() -> float:
	return float(s.damage) * float(p.stats["might"])


func _cd() -> float:
	return maxf(0.08, float(s.cooldown) * float(p.stats["cooldown"]))


func _amt() -> int:
	return maxi(1, int(s.get("amount", 1)) + int(p.stats["amount"]))


func _area() -> float:
	return float(s.get("area", 1.0)) * float(p.stats["area"])


func _spd() -> float:
	return float(s.get("speed", 1.0)) * float(p.stats["proj_speed"])


func _dur() -> float:
	return float(s.get("duration", 1.0)) * float(p.stats["duration"])


func update(delta: float, game: Main) -> void:
	g = game
	p = game.player
	match str(def.type):
		"aura":
			_update_aura(delta)
		"bible":
			_update_bible(delta)
		_:
			_update_volley(delta)


# ─────────────────────────────────────────────
# 일반 무기: 쿨타임마다 여러 발을 순서대로 발사
# ─────────────────────────────────────────────
func _update_volley(delta: float) -> void:
	var type := str(def.type)
	timer -= delta
	if timer <= 0.0:
		var count := _amt()
		if type == "wand":
			targets = g.nearest_enemies(p.position, count, 700.0)
			if targets.is_empty():
				timer = 0.1     # 적이 없으면 쿨타임을 쓰지 않고 곧 다시 확인
				return
		elif type == "lightning" or type == "zone":
			if g.random_enemy_in_view(1.0) == null:
				timer = 0.2
				return
		timer = _cd()
		burst_left = count
		burst_idx = 0
		burst_timer = 0.0
		if type == "spiral":
			angle += 0.35
	if burst_left > 0:
		burst_timer -= delta
		var gap: float = GAPS.get(type, 0.1)
		while burst_left > 0 and burst_timer <= 0.0:
			_fire(str(def.type), burst_idx)
			burst_idx += 1
			burst_left -= 1
			burst_timer += gap


func _fire(type: String, idx: int) -> void:
	match type:
		"whip": _fire_whip(idx)
		"wand": _fire_wand(idx)
		"knife": _fire_knife(idx)
		"axe": _fire_axe(idx)
		"spiral": _fire_spiral(idx)
		"zone": _fire_zone()
		"lightning": _fire_lightning()


func _fire_whip(idx: int) -> void:
	var side := (1.0 if idx % 2 == 0 else -1.0) * p.face_x
	var area := _area()
	var length := 150.0 * area
	var height := 34.0 * area
	var y_off := -4.0 - floorf(idx / 2.0) * 26.0
	var center := p.position + Vector2(side * (length / 2.0 + 6.0), y_off)
	var dmg := _dmg()
	var hits := 0
	for e in g.query_enemies(center, length * 0.5 + 40.0):
		if e.dead:
			continue
		if absf(e.position.x - center.x) < length / 2.0 + e.radius and absf(e.position.y - center.y) < height / 2.0 + e.radius:
			g.damage_enemy(e, dmg, self, Vector2(side, 0.0), float(s.knockback))
			hits += 1
	g.hit_props(center, length * 0.5)
	if float(s.get("lifesteal", 0.0)) > 0.0 and hits > 0:
		g.heal_player(float(mini(hits, 8)))
	var col := Color(1.0, 0.35, 0.4) if is_evolved() else Color(1.0, 1.0, 1.0)
	g.add_fx(Fx.slash(center, length, height, side, col))


func _fire_wand(idx: int) -> void:
	var target_pos := Vector2.ZERO
	var found := false
	if not targets.is_empty():
		var candidate: Variant = targets[idx % targets.size()]
		if is_instance_valid(candidate) and not (candidate as Enemy).dead:
			target_pos = (candidate as Enemy).position
			found = true
	if not found:
		var list := g.nearest_enemies(p.position, 1, 700.0)
		if list.is_empty():
			return
		target_pos = (list[0] as Enemy).position
	var a := (target_pos - p.position).angle()
	if idx >= targets.size():
		a += randf_range(-0.15, 0.15)
	var pr := Projectile.make("bolt", p.position + Vector2(0, -4), Vector2.from_angle(a) * _spd(),
		_dmg(), int(s.pierce), _dur(), 7.0 * _area(), self)
	pr.color = Color(1.0, 0.88, 0.4) if is_evolved() else Color(0.48, 0.85, 1.0)
	pr.kb = 0.6
	g.add_projectile(pr)


func _fire_knife(idx: int) -> void:
	var n := _amt()
	var d := p.dir
	var off := (idx - (n - 1) / 2.0) * 9.0 + randf_range(-3.0, 3.0)
	var a := d.angle() + randf_range(-0.05, 0.05)
	var perp := Vector2(-d.y, d.x)
	var pr := Projectile.make("knife", p.position + Vector2(0, -4) + perp * off, Vector2.from_angle(a) * _spd(),
		_dmg(), int(s.pierce), _dur(), 6.0, self)
	pr.kb = 0.4
	g.add_projectile(pr)


func _fire_axe(idx: int) -> void:
	var sp := _spd()
	var dir_x := (1.0 if idx % 2 == 0 else -1.0) * p.face_x
	var vx := dir_x * (50.0 + floorf(idx / 2.0) * 55.0 + randf_range(0.0, 40.0))
	var pr := Projectile.make("axe", p.position + Vector2(0, -10), Vector2(vx, -randf_range(500.0, 570.0) * sp),
		_dmg(), int(s.pierce), 3.0, 14.0 * _area(), self)
	pr.gravity = 950.0 * sp
	pr.spin = 12.0 * dir_x
	pr.kb = 0.8
	pr.hit_interval = 0.4
	g.add_projectile(pr)


func _fire_spiral(idx: int) -> void:
	var n := _amt()
	var a := angle + float(idx) / float(n) * TAU
	var pr := Projectile.make("scythe", p.position, Vector2.from_angle(a) * 280.0 * _spd(),
		_dmg(), 999, _dur(), 18.0 * _area(), self)
	pr.spin = 14.0
	pr.curve = 1.3
	pr.hit_interval = 0.5
	pr.kb = 0.8
	g.add_projectile(pr)


func _fire_zone() -> void:
	var pos: Vector2
	var e := g.random_enemy_in_view(0.8)
	if e != null and randf() < 0.85:
		pos = e.position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	else:
		pos = p.position + Vector2.from_angle(randf() * TAU) * randf_range(70.0, 220.0)
	var delay := 0.35
	var pr := Projectile.make("zone", pos, Vector2.ZERO, _dmg(), 999, delay + _dur(), 38.0 * _area(), self)
	pr.delay = delay
	pr.hit_interval = float(s.interval)
	pr.kb = 0.1
	pr.evolved = is_evolved()
	g.add_projectile(pr)


func _fire_lightning() -> void:
	var e := g.random_enemy_in_view(1.0)
	if e == null:
		return
	var r := 30.0 * _area()
	var pos := e.position
	g.add_fx(Fx.bolt(pos, g.get_viewport_rect().size.y))
	g.add_fx(Fx.ring(pos, Color(1.0, 0.96, 0.63), r * 1.3, 0.25))
	var dmg := _dmg()
	for t in g.query_enemies(pos, r + 20.0):
		if t.dead:
			continue
		var rr := r + t.radius
		if t.position.distance_squared_to(pos) < rr * rr:
			g.damage_enemy(t, dmg, self, (t.position - pos).normalized(), 0.3)
	g.hit_props(pos, r)
	g.shake(2.0, 0.08)


# ─────────────────────────────────────────────
# 마늘 (오라)
# ─────────────────────────────────────────────
func _update_aura(delta: float) -> void:
	var radius: float = float(s.radius) * float(p.stats["area"])
	p.aura_radius = radius
	p.aura_evolved = is_evolved()
	tick -= delta
	if tick > 0.0:
		return
	tick = maxf(0.15, float(s.interval) * (0.5 + 0.5 * float(p.stats["cooldown"])))
	var dmg := _dmg()
	var hits := 0
	for e in g.query_enemies(p.position, radius + 25.0):
		if e.dead:
			continue
		var rr := radius + e.radius
		if e.position.distance_squared_to(p.position) < rr * rr:
			g.damage_enemy(e, dmg, self, (e.position - p.position).normalized(), float(s.knockback))
			hits += 1
	g.hit_props(p.position, radius)
	if float(s.get("heal", 0.0)) > 0.0 and hits > 0:
		g.heal_player(minf(3.0, hits * 0.15))


# ─────────────────────────────────────────────
# 성서 (주위를 도는 책)
# ─────────────────────────────────────────────
func _update_bible(delta: float) -> void:
	var n := _amt()
	angle += delta * 3.2 * _spd()
	var radius := 72.0 * _area()
	if active > 0.0:
		active -= delta
		if active <= 0.0:
			cleanup()
			cool = _cd()
		elif books.size() != n:
			_rebuild_books(n)
	else:
		cool -= delta
		if cool <= 0.0:
			active = _dur()
			_rebuild_books(n)

	var count := books.size()
	for i in count:
		var b: Projectile = books[i]
		var a := angle + float(i) / float(count) * TAU
		b.position = p.position + Vector2(cos(a), sin(a)) * radius
		b.radius = 13.0 * _area()
		b.damage = _dmg()
		b.fade = 1.0 if active >= 0.25 else maxf(0.1, active / 0.25)


func _rebuild_books(n: int) -> void:
	cleanup()
	for i in n:
		var b := Projectile.make("book", p.position, Vector2.ZERO, _dmg(), 999, INF, 13.0 * _area(), self)
		b.managed = true
		b.hit_interval = float(s.interval)
		b.kb = float(s.knockback)
		b.evolved = is_evolved()
		g.add_projectile(b)
		books.append(b)
