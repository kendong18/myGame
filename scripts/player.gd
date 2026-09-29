class_name Player
extends Node2D
## 플레이어: 이동, 체력, 스탯, 보유 무기/패시브

const RADIUS := 12.0

var stats: Dictionary = {}
var hp := GameData.BASE_HP
var max_hp := GameData.BASE_HP
var xp := 0.0
var level := 1
var weapons: Array[Weapon] = []
var passives: Dictionary = {}   # 패시브 id -> 레벨

var dir := Vector2.RIGHT
var face_x := 1.0
var invuln := 0.0
var hurt_flash := 0.0
var aura_radius := 0.0           # 마늘 무기가 설정, 그리기용
var aura_evolved := false
var walk_t := 0.0
var moving := false
var regen_acc := 0.0
var damage_taken := 0.0


func _ready() -> void:
	z_index = 5
	recalc_stats()
	hp = max_hp


func recalc_stats() -> void:
	var s := {
		"might": 1.0, "armor": 0.0, "max_hp_mul": 1.0, "recovery": 0.0,
		"move_speed": 1.0, "cooldown": 1.0, "amount": 0, "area": 1.0,
		"magnet": 1.0, "growth": 1.0, "proj_speed": 1.0, "duration": 1.0,
		"luck": 1.0, "greed": 1.0,
	}
	for id: String in passives:
		var p: Dictionary = GameData.PASSIVES[id]
		var stat: String = p.stat
		s[stat] = s[stat] + float(p.per) * int(passives[id])
	s["cooldown"] = maxf(0.3, s["cooldown"])
	stats = s
	var ratio := 1.0 if max_hp <= 0.0 else hp / max_hp
	max_hp = GameData.BASE_HP * float(s["max_hp_mul"])
	hp = max_hp * ratio


func add_weapon(id: String) -> Weapon:
	var w := Weapon.new(id)
	weapons.append(w)
	return w


func get_weapon(id: String) -> Weapon:
	for w in weapons:
		if w.id == id:
			return w
	return null


## 매 프레임 이동/타이머 갱신. input 은 길이 0~1 의 이동 벡터
func step(delta: float, input: Vector2) -> void:
	moving = input.length() > 0.05
	if moving:
		dir = input.normalized()
		if absf(input.x) > 0.1:
			face_x = signf(input.x)
		walk_t += delta
	position += input * GameData.BASE_SPEED * float(stats["move_speed"]) * delta
	invuln = maxf(0.0, invuln - delta)
	hurt_flash = maxf(0.0, hurt_flash - delta)

	var rec: float = stats["recovery"]
	if rec > 0.0 and hp < max_hp:
		regen_acc += rec * delta
		if regen_acc >= 1.0:
			var whole := floorf(regen_acc)
			regen_acc -= whole
			heal(whole)
	scale.x = face_x
	queue_redraw()


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


## 피해를 받으면 true 반환. 무적 시간 중에는 false
func take_damage(amount: float) -> bool:
	if invuln > 0.0:
		return false
	var dmg := maxf(1.0, amount - float(stats["armor"]))
	hp -= dmg
	damage_taken += dmg
	invuln = 0.45
	hurt_flash = 0.15
	return true


func _draw() -> void:
	var bob := -absf(sin(walk_t * 12.0)) * 2.0 if moving else 0.0

	# 마늘 오라
	if aura_radius > 0.0:
		var ac := Color(0.75, 0.4, 1.0) if aura_evolved else Color(1.0, 0.92, 0.6)
		draw_circle(Vector2.ZERO, aura_radius, Color(ac.r, ac.g, ac.b, 0.10))
		draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 48, Color(ac.r, ac.g, ac.b, 0.45), 2.0)

	# 그림자
	draw_colored_polygon(Util.ellipse(Vector2(0, 13), 12, 4), Color(0, 0, 0, 0.4))

	var flash := hurt_flash > 0.0
	var cloth := Color.WHITE if flash else Color(0.36, 0.48, 0.72)
	var cloth_dark := Color.WHITE if flash else Color(0.24, 0.32, 0.52)
	var skin := Color.WHITE if flash else Color(0.95, 0.76, 0.6)
	var hair := Color.WHITE if flash else Color(0.55, 0.35, 0.17)
	var boot := Color.WHITE if flash else Color(0.3, 0.2, 0.13)

	# 발
	var step_off := sin(walk_t * 12.0) * 3.0 if moving else 0.0
	draw_rect(Rect2(-6, 8 + bob, 5, 5), boot)
	draw_rect(Rect2(1, 8 + bob + step_off * 0.3, 5, 5), boot)
	# 몸
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, 8 + bob), Vector2(9, 8 + bob), Vector2(7, -3 + bob), Vector2(-7, -3 + bob),
	]), cloth)
	draw_rect(Rect2(-7, 2 + bob, 14, 3), cloth_dark)
	# 머리
	draw_circle(Vector2(0, -9 + bob), 8, skin)
	draw_arc(Vector2(0, -10 + bob), 8, PI, TAU, 12, hair, 4.0)
	draw_rect(Rect2(-8, -11 + bob, 16, 3), hair)
	# 눈
	draw_rect(Rect2(1, -9 + bob, 2, 3), Color(0.1, 0.1, 0.18))
	draw_rect(Rect2(-4, -9 + bob, 2, 3), Color(0.1, 0.1, 0.18))

	# 체력바 (캐릭터가 뒤집혀도 항상 같은 위치)
	if hp < max_hp:
		var w := 26.0
		var ratio := clampf(hp / max_hp, 0.0, 1.0)
		var bx := -w / 2.0
		draw_rect(Rect2(bx - 1, 17, w + 2, 6), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bx, 18, w * ratio, 4), Color(0.9, 0.2, 0.25))
