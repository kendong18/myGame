class_name Weapon
extends RefCounted
## 플레이어가 가진 무기 하나. 종류별 동작은 이 파일 안에서 처리한다.

# 한 번 발동할 때 여러 발을 쏘는 무기의 발사 간격(초)
const GAPS := {
	"whip": 0.12, "wand": 0.08, "knife": 0.05, "axe": 0.12, "spiral": 0.0, "zone": 0.15,
	"lightning": 0.09, "mine": 0.15, "rail": 0.35,
}

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
var drones: Array = []          # 정비 드론: [{node, mode, t, target, dir}]
var rail_chosen: Array = []     # 레일건이 이번 발사에서 이미 조준한 적
var rail_pending: Array = []    # 충전 중인 광선: [{t, dir}]
var shield_angle := 0.0
var element := ""
var color := Color.WHITE

var g: Main
var p: Player


func _init(weapon_id: String) -> void:
	id = weapon_id
	def = GameData.WEAPONS[weapon_id]
	element = str(def.get("element", ""))
	color = GameData.element_color(element)
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
	return T.t(str(lv.text))


func is_evolved() -> bool:
	return def.get("evolved", false)


## 진화할 수 있는 상태인가 (최대 레벨 + 짝 패시브 보유)
func can_evolve(player: Player) -> bool:
	var ev: Variant = def.get("evolve")
	if ev == null or level < max_level():
		return false
	return int(player.passives.get(ev.passive, 0)) > 0


## 무기가 화면에 남겨 둔 것들(책, 드론, 빔, 방패)을 정리한다
func cleanup() -> void:
	for b in books:
		if is_instance_valid(b):
			(b as Projectile).dead = true
	books.clear()
	for d: Dictionary in drones:
		if is_instance_valid(d.node):
			(d.node as Projectile).dead = true
	drones.clear()
	rail_pending.clear()
	if p != null:
		match str(def.type):
			"beam":
				p.beams.clear()
			"shield":
				p.shields.clear()


# ── 플레이어 스탯이 반영된 실제 수치 ─────────
func _dmg() -> float:
	return float(s.damage) * float(p.stats["might"])


func _cd() -> float:
	return maxf(0.08, float(s.cooldown) * p.cd_mult())


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
		"beam":
			_update_beam(delta)
		"shield":
			_update_shield(delta)
		"drone":
			_update_drones(delta)
		_:
			if str(def.type) == "rail":
				_process_rail(delta)
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
		elif type == "rail":
			if g.tankiest_in_view([]) == null:
				timer = 0.25
				return
			rail_chosen.clear()
		elif type == "mine":
			if g.enemies.is_empty() or _active_mines() >= int(float(s.get("cap", 5.0))):
				timer = 0.4
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
		"mine": _fire_mine(idx)
		"rail": _fire_rail()


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
	g.add_fx(Fx.slash(center, length, height, side, color.lightened(0.15) if is_evolved() else color))
	Sfx.play("whip", 0.08)


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
	pr.color = color
	pr.evolved = is_evolved()
	pr.kb = 0.6
	g.add_projectile(pr)
	Sfx.play("shoot", 0.1)


func _fire_knife(idx: int) -> void:
	var n := _amt()
	var d := p.dir
	var off := (idx - (n - 1) / 2.0) * 9.0 + randf_range(-3.0, 3.0)
	var a := d.angle() + randf_range(-0.05, 0.05)
	var perp := Vector2(-d.y, d.x)
	var pr := Projectile.make("knife", p.position + Vector2(0, -4) + perp * off, Vector2.from_angle(a) * _spd(),
		_dmg(), int(s.pierce), _dur(), 6.0, self)
	pr.color = color
	pr.evolved = is_evolved()
	pr.kb = 0.4
	g.add_projectile(pr)
	Sfx.play("shoot", 0.15)


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
	pr.color = color
	pr.evolved = is_evolved()
	g.add_projectile(pr)
	Sfx.play("shoot", 0.1)


func _fire_spiral(idx: int) -> void:
	var n := _amt()
	var a := angle + float(idx) / float(n) * TAU
	var pr := Projectile.make("scythe", p.position, Vector2.from_angle(a) * 280.0 * _spd(),
		_dmg(), 999, _dur(), 18.0 * _area(), self)
	pr.spin = 14.0
	pr.curve = 1.3
	pr.hit_interval = 0.5
	pr.kb = 0.8
	pr.color = color
	g.add_projectile(pr)
	if idx == 0:
		Sfx.play("whip")


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
	pr.color = color
	pr.evolved = is_evolved()
	g.add_projectile(pr)


func _fire_lightning() -> void:
	var e := g.random_enemy_in_view(1.0)
	if e == null:
		return
	var r := 30.0 * _area()
	var pos := e.position
	g.add_fx(Fx.bolt(pos, g.get_viewport_rect().size.y))
	g.add_fx(Fx.ring(pos, color, r * 1.3, 0.25))
	var dmg := _dmg()
	for t in g.query_enemies(pos, r + 20.0):
		if t.dead:
			continue
		var rr := r + t.radius
		if t.position.distance_squared_to(pos) < rr * rr:
			g.damage_enemy(t, dmg, self, (t.position - pos).normalized(), 0.3)
	g.hit_props(pos, r)
	g.shake(2.0, 0.08)
	Sfx.play("thunder", 0.1)


# ─────────────────────────────────────────────
# 접착 지뢰: 지나간 자리에 깔아 두고, 밟으면 폭발
# ─────────────────────────────────────────────
func _active_mines() -> int:
	var n := 0
	for pr in g.projectiles:
		if pr.weapon == self and pr.kind == "mine" and not pr.dead:
			n += 1
	return n


func _fire_mine(idx: int) -> void:
	if _active_mines() >= int(float(s.get("cap", 5.0))):
		return
	# 플레이어가 온 방향(뒤쪽)에 흩뿌려 깐다
	var pos := p.position - p.dir * (14.0 + float(idx) * 18.0) + Vector2(randf_range(-10.0, 10.0), randf_range(-6.0, 10.0))
	var pr := Projectile.make("mine", pos, Vector2.ZERO, _dmg(), 1, _dur(), 22.0, self)
	pr.aoe = float(s.radius) * _area()
	pr.delay = 0.7          # 설치 직후에는 아직 작동하지 않는다
	pr.kb = 1.0
	pr.color = color
	pr.evolved = is_evolved()
	g.add_projectile(pr)


# ─────────────────────────────────────────────
# 레일건: 가장 단단한 적을 조준해 충전한 뒤 관통 광선
# ─────────────────────────────────────────────
func _fire_rail() -> void:
	var t: Enemy = g.tankiest_in_view(rail_chosen)
	if t == null:
		return
	rail_chosen.append(t)
	var dir := (t.position - p.position).normalized()
	var charge := float(s.get("charge", 0.7))
	rail_pending.append({"t": charge, "dir": dir})
	var width := float(s.width) * _area()
	# 발사 위치를 미리 알려 주는 가느다란 예고선
	g.add_fx(Fx.beam(p.position, dir.angle(), 1300.0, maxf(3.0, width * 0.2), Color(color.r, color.g, color.b, 0.6), charge, true))
	Sfx.play("charge")


func _process_rail(delta: float) -> void:
	for it: Dictionary in rail_pending:
		it.t = float(it.t) - delta
	while not rail_pending.is_empty() and float(rail_pending[0].t) <= 0.0:
		var it: Dictionary = rail_pending.pop_front()
		_rail_shot(it.dir)


func _rail_shot(dir: Vector2) -> void:
	var length := 1300.0
	var width := float(s.width) * _area()
	var origin := p.position
	var dmg := _dmg()
	for e in g.query_enemies(origin + dir * (length * 0.5), length * 0.55):
		if e.dead:
			continue
		var rel := e.position - origin
		var t := clampf(rel.dot(dir), 0.0, length)
		var closest := origin + dir * t
		var reach := width * 0.5 + e.radius
		if e.position.distance_squared_to(closest) < reach * reach:
			g.damage_enemy(e, dmg, self, dir, 0.4)
	for k in 8:
		g.hit_props(origin + dir * length * float(k) / 7.0, width)
	g.add_fx(Fx.beam(origin, dir.angle(), length, width, color, 0.3, false))
	g.shake(4.0, 0.12)
	Sfx.play("rail")


# ─────────────────────────────────────────────
# 냉각 레이저: 주위를 도는 지속 빔
# ─────────────────────────────────────────────
func _update_beam(delta: float) -> void:
	var n := _amt()
	angle += delta * _spd()
	var length := float(s.length) * _area()
	var width := float(s.width) * _area()
	var counter := int(float(s.get("counter", 0.0))) == 1
	tick -= delta
	var hit_now := tick <= 0.0
	if hit_now:
		tick = maxf(0.1, float(s.interval) * (0.5 + 0.5 * p.cd_mult()))
	p.beams.clear()
	for i in n:
		var a := angle * (-1.0 if counter and i % 2 == 1 else 1.0) + TAU * float(i) / float(n)
		var dir := Vector2.from_angle(a)
		p.beams.append({"dir": dir, "len": length, "w": width, "col": color})
		if hit_now:
			_beam_damage(dir, length, width)


func _beam_damage(dir: Vector2, length: float, width: float) -> void:
	var dmg := _dmg()
	for e in g.query_enemies(p.position, length + 30.0):
		if e.dead:
			continue
		var rel := e.position - p.position
		var t := clampf(rel.dot(dir), 0.0, length)
		var closest := p.position + dir * t
		var reach := width * 0.5 + e.radius
		if e.position.distance_squared_to(closest) < reach * reach:
			g.damage_enemy(e, dmg, self, (e.position - closest).normalized(), 0.15)
	for k in 5:
		g.hit_props(p.position + dir * length * float(k) / 4.0, width)


# ─────────────────────────────────────────────
# 반사 방패: 이동 방향에 세우는 방패. 적탄을 막고 닿는 적을 밀어낸다
# ─────────────────────────────────────────────
func _in_shield(ang: float, angles: Array, span: float) -> bool:
	for a: float in angles:
		if absf(angle_difference(a, ang)) < span / 2.0:
			return true
	return false


func _update_shield(delta: float) -> void:
	var n := _amt()
	shield_angle = lerp_angle(shield_angle, p.dir.angle(), 1.0 - exp(-10.0 * delta))
	var radius := float(s.radius) * _area()
	var span := float(s.span)
	var angles: Array = []
	p.shields.clear()
	for i in n:
		var a := shield_angle + TAU * float(i) / float(n)
		angles.append(a)
		p.shields.append({"angle": a, "span": span, "radius": radius, "col": color})

	# 방패에 닿은 적탄은 사라진다. 진화하면 되받아 쏜다.
	for sh in g.shots:
		if sh.dead:
			continue
		var rel := sh.position - p.position
		if absf(rel.length() - radius) > 14.0 + sh.radius:
			continue
		if _in_shield(rel.angle(), angles, span):
			sh.dead = true
			g.add_fx(Fx.puff(sh.position, color, 8.0))
			if float(s.get("reflect", 0.0)) > 0.0:
				var back := Projectile.make("bolt", sh.position, rel.normalized() * 320.0,
					sh.damage * 3.0 * float(p.stats["might"]), 1, 1.6, 7.0, self)
				back.color = color
				back.kb = 0.4
				g.add_projectile(back)

	tick -= delta
	if tick > 0.0:
		return
	tick = maxf(0.12, float(s.interval) * (0.5 + 0.5 * p.cd_mult()))
	var dmg := _dmg()
	for e in g.query_enemies(p.position, radius + 40.0):
		if e.dead:
			continue
		var rel := e.position - p.position
		if absf(rel.length() - radius) < 16.0 + e.radius and _in_shield(rel.angle(), angles, span):
			g.damage_enemy(e, dmg, self, rel.normalized(), float(s.knockback))


# ─────────────────────────────────────────────
# 정비 드론: 스스로 날아가 적을 공격하고 돌아오는 동료
# ─────────────────────────────────────────────
func _rebuild_drones(n: int) -> void:
	for d: Dictionary in drones:
		if is_instance_valid(d.node):
			(d.node as Projectile).dead = true
	drones.clear()
	var cd := _cd()
	for i in n:
		var node := Projectile.make("drone", p.position, Vector2.ZERO, 0.0, 999, INF, 11.0, self)
		node.managed = true
		node.hit_interval = 0.35
		node.kb = 0.6
		node.color = color
		node.evolved = is_evolved()
		g.add_projectile(node)
		drones.append({"node": node, "mode": "orbit", "t": cd * float(i) / float(n) + 0.3, "target": null, "dir": Vector2.RIGHT})


func _update_drones(delta: float) -> void:
	var n := _amt()
	if drones.size() != n:
		_rebuild_drones(n)
	var dmg := _dmg()
	var spd := _spd()
	var area := _area()
	var reach := float(s.range)
	var cd := _cd()
	angle += delta * 1.4
	for i in drones.size():
		var d: Dictionary = drones[i]
		if not is_instance_valid(d.node):
			continue
		var node: Projectile = d.node
		var home := p.position + Vector2.from_angle(angle + float(i) / float(drones.size()) * TAU) * (44.0 + 6.0 * sin(angle * 2.0 + float(i))) + Vector2(0, -6)
		node.radius = 11.0 * area
		match str(d.mode):
			"orbit":
				node.position = node.position.lerp(home, 1.0 - exp(-9.0 * delta))
				node.damage = 0.0
				d.t = float(d.t) - delta
				if float(d.t) <= 0.0:
					var found := g.nearest_enemies(node.position, 1, reach)
					if found.is_empty():
						d.t = 0.25
					else:
						d.mode = "go"
						d.target = found[0]
						d.t = 1.4
			"go":
				var tgt: Variant = d.target
				if not is_instance_valid(tgt) or (tgt as Enemy).dead or float(d.t) <= 0.0:
					d.mode = "back"
					continue
				var to := (tgt as Enemy).position - node.position
				var dist := to.length()
				var dir := to / maxf(dist, 0.001)
				d.dir = dir
				node.position += dir * spd * delta
				node.damage = dmg
				d.t = float(d.t) - delta
				if dist < node.radius + (tgt as Enemy).radius + 2.0:
					d.mode = "slash"      # 목표를 스치고 지나간 뒤 돌아온다
					d.t = 0.2
			"slash":
				node.position += (d.dir as Vector2) * spd * delta
				node.damage = dmg
				d.t = float(d.t) - delta
				if float(d.t) <= 0.0:
					d.mode = "back"
			"back":
				node.damage = 0.0
				var to_home := home - node.position
				var dist_home := to_home.length()
				node.position += to_home.normalized() * minf(dist_home, spd * 1.3 * delta)
				if dist_home < 16.0:
					d.mode = "orbit"
					d.t = cd


# ─────────────────────────────────────────────
# 진공청소기 (오라): 적을 끌어모아 느리게 만들며 피해를 준다
# ─────────────────────────────────────────────
func _update_aura(delta: float) -> void:
	var radius: float = float(s.radius) * float(p.stats["area"])
	p.aura_radius = radius
	p.aura_evolved = is_evolved()
	tick -= delta
	if tick > 0.0:
		return
	tick = maxf(0.15, float(s.interval) * (0.5 + 0.5 * p.cd_mult()))
	var dmg := _dmg()
	var hits := 0
	# 적은 몸에 붙지 않도록 이 거리(고리)까지만 끌어당긴다
	var ring := maxf(44.0, radius * 0.6)
	for e in g.query_enemies(p.position, radius + 25.0):
		if e.dead:
			continue
		var offset := p.position - e.position
		var dist := offset.length()
		if dist < radius + e.radius:
			g.damage_enemy(e, dmg, self, offset / maxf(dist, 0.001), 0.0)
			hits += 1
			if e.dead:
				continue
			e.suction = 0.6         # 붙잡혀서 느려진다
			var gap := dist - ring
			if gap > 2.0:
				var pull := minf(170.0 * float(s.knockback), sqrt(1400.0 * gap))
				e.knock += (offset / maxf(dist, 0.001)) * pull * (1.0 - e.kb_resist)
	g.hit_props(p.position, radius)
	if float(s.get("heal", 0.0)) > 0.0 and hits > 0:
		g.heal_player(minf(3.0, hits * 0.15))


# ─────────────────────────────────────────────
# 위성 구슬 (주위를 도는 구슬)
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
		b.color = color
		b.evolved = is_evolved()
		g.add_projectile(b)
		books.append(b)
