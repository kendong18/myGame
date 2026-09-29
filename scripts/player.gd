class_name Player
extends Node2D
## 플레이어: 이동, 체력, 스탯, 보유 무기/패시브

const RADIUS := 12.0

var character_id := "coco"
var palette: Dictionary = {}
var stats: Dictionary = {}
var hp := GameData.BASE_HP
var max_hp := GameData.BASE_HP
var xp := 0.0
var level := 1
var weapons: Array[Weapon] = []
var passives: Dictionary = {}   # 패시브 id -> 레벨
var revives := 0

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


func setup(char_id: String) -> void:
	character_id = char_id
	palette = palette_for(GameData.character(char_id))
	recalc_stats()
	hp = max_hp
	revives = int(stats["revival"])


func _ready() -> void:
	z_index = 5
	if palette.is_empty():
		setup(character_id)


## 캐릭터 색상표 (빠진 값은 기본값)
static func palette_for(ch: Dictionary) -> Dictionary:
	var p := {
		"style": "human", "suit": Color(0.38, 0.6, 0.95), "suit_dark": Color(0.25, 0.42, 0.75),
		"helmet": Color(0.95, 0.96, 1.0), "accent": Color(1.0, 0.55, 0.35),
	}
	var custom: Dictionary = ch.get("palette", {})
	for k: String in custom:
		p[k] = custom[k]
	return p


func recalc_stats() -> void:
	var s := {
		"might": 1.0, "armor": 0.0, "max_hp_mul": 1.0, "recovery": 0.0,
		"move_speed": 1.0, "cooldown": 1.0, "amount": 0, "area": 1.0,
		"magnet": 1.0, "growth": 1.0, "proj_speed": 1.0, "duration": 1.0,
		"luck": 1.0, "greed": 1.0, "revival": 0.0, "reaction": 1.0,
	}
	# 1) 레벨업으로 얻은 패시브
	for id: String in passives:
		var p: Dictionary = GameData.PASSIVES[id]
		var stat: String = p.stat
		s[stat] = s[stat] + float(p.per) * int(passives[id])
	# 2) 상점에서 산 영구 강화
	for item: Dictionary in GameData.SHOP:
		var lv := SaveData.upgrade_level(item.id)
		if lv > 0:
			var st: String = item.stat
			s[st] = s[st] + float(item.per) * lv
	# 3) 캐릭터 고유 보너스
	var bonus: Dictionary = GameData.character(character_id).bonus
	for st: String in bonus:
		s[st] = s[st] + float(bonus[st])
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
	# 진공청소기: 안쪽으로 빨려 들어가는 소용돌이
	if aura_radius > 0.0:
		var ac := Color(0.75, 0.5, 1.0) if aura_evolved else Color(0.5, 0.9, 0.95)
		var t := float(Time.get_ticks_msec()) / 1000.0
		draw_circle(Vector2.ZERO, aura_radius, Color(ac.r, ac.g, ac.b, 0.08))
		draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 48, Color(ac.r, ac.g, ac.b, 0.35), 2.0)
		for i in 4:
			var a0 := -t * 2.6 + TAU * float(i) / 4.0
			draw_arc(Vector2.ZERO, aura_radius * 0.78, a0, a0 + 0.9, 10, Color(ac.r, ac.g, ac.b, 0.55), 2.5)
			draw_arc(Vector2.ZERO, aura_radius * 0.48, a0 + 1.3, a0 + 2.1, 8, Color(ac.r, ac.g, ac.b, 0.45), 2.0)

	var bob := -absf(sin(walk_t * 12.0)) * 2.0 if moving else 0.0
	var step_off := sin(walk_t * 12.0) * 3.0 if moving else 0.0
	# 부활 직후 무적 중에는 깜빡임
	var blink := invuln > 0.5 and int(invuln * 12.0) % 2 == 0
	if not blink:
		Player.draw_hero(self, palette, bob, step_off, hurt_flash > 0.0)

	# 체력바 (캐릭터가 뒤집혀도 항상 같은 위치)
	if hp < max_hp:
		var w := 26.0
		var ratio := clampf(hp / max_hp, 0.0, 1.0)
		var bx := -w / 2.0
		draw_rect(Rect2(bx - 1, 17, w + 2, 6), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bx, 18, w * ratio, 4), Color(0.9, 0.2, 0.25))


## 캐릭터 그림. 게임 화면과 캐릭터 선택 화면이 함께 사용한다. (ci 자신의 _draw 안에서 호출해야 함)
static func draw_hero(ci: CanvasItem, pal: Dictionary, bob: float, step_off: float, flash: bool) -> void:
	var style: String = pal.style
	var suit: Color = Color.WHITE if flash else pal.suit
	var suit_dark: Color = Color.WHITE if flash else pal.suit_dark
	var helmet: Color = Color.WHITE if flash else pal.helmet
	var accent: Color = Color.WHITE if flash else pal.accent
	var outline := Color(0.1, 0.1, 0.2, 0.75)
	var glass := Color(0.14, 0.2, 0.42)

	ci.draw_colored_polygon(Util.ellipse(Vector2(0, 13), 12, 4), Color(0, 0, 0, 0.35))
	# 배낭 (몸 뒤쪽)
	ci.draw_rect(Rect2(-12, -3 + bob, 6, 11), suit_dark)
	# 발
	if style == "round":
		ci.draw_circle(Vector2(-5, 11 + bob), 3.2, suit_dark)
		ci.draw_circle(Vector2(5, 11 + bob), 3.2, suit_dark)
	else:
		ci.draw_rect(Rect2(-6.5, 9 + bob, 6, 4.5), suit_dark)
		ci.draw_rect(Rect2(0.5, 9 + bob + step_off * 0.3, 6, 4.5), suit_dark)
	# 몸통
	ci.draw_colored_polygon(Util.ellipse(Vector2(0, 3 + bob), 8.5, 8.0, 16), suit)
	ci.draw_arc(Vector2(0, 3 + bob), 8.5, 0.0, TAU, 16, outline, 1.2)
	ci.draw_circle(Vector2(0, 4.5 + bob), 2.6, accent)

	match style:
		"robot":
			ci.draw_line(Vector2(0, -17 + bob), Vector2(0, -22 + bob), suit_dark, 1.5)
			ci.draw_circle(Vector2(0, -23 + bob), 2.0, accent)
			ci.draw_rect(Rect2(-8.5, -17 + bob, 17, 14), helmet)
			ci.draw_rect(Rect2(-8.5, -17 + bob, 17, 14), outline, false, 1.2)
			ci.draw_rect(Rect2(-6.5, -14.5 + bob, 13, 9), glass)
			ci.draw_rect(Rect2(-4.5, -12.5 + bob, 3, 4), accent)
			ci.draw_rect(Rect2(1.5, -12.5 + bob, 3, 4), accent)
		"round":
			ci.draw_circle(Vector2(0, -9 + bob), 10, helmet)
			ci.draw_arc(Vector2(0, -9 + bob), 10, 0.0, TAU, 20, outline, 1.2)
			ci.draw_circle(Vector2(0, -9 + bob), 7.2, glass)
			ci.draw_circle(Vector2(0, -9 + bob), 4.6, accent)
			ci.draw_circle(Vector2(0, -9 + bob), 2.3, Color(0.05, 0.1, 0.2))
			ci.draw_circle(Vector2(-1.2, -10.3 + bob), 1.1, Color.WHITE)
			ci.draw_line(Vector2(0, -19 + bob), Vector2(0, -23 + bob), suit_dark, 1.5)
			ci.draw_circle(Vector2(0, -24 + bob), 1.8, Color(1.0, 0.4, 0.5))
		_:
			# 귀와 안테나 (헬멧 뒤에 그린다)
			match style:
				"cat":
					for sx in [-1.0, 1.0]:
						ci.draw_colored_polygon(PackedVector2Array([Vector2(sx * 9.0, -13 + bob), Vector2(sx * 8.0, -25 + bob), Vector2(sx * 1.5, -18 + bob)]), helmet)
						ci.draw_colored_polygon(PackedVector2Array([Vector2(sx * 7.6, -15 + bob), Vector2(sx * 7.2, -22 + bob), Vector2(sx * 3.2, -17.5 + bob)]), accent)
				"bear":
					for sx in [-1.0, 1.0]:
						ci.draw_circle(Vector2(sx * 8.5, -16 + bob), 4.2, helmet)
						ci.draw_circle(Vector2(sx * 8.5, -16 + bob), 2.2, accent)
				"owl":
					for sx in [-1.0, 1.0]:
						ci.draw_colored_polygon(PackedVector2Array([Vector2(sx * 9.5, -12 + bob), Vector2(sx * 9.0, -23 + bob), Vector2(sx * 2.5, -18 + bob)]), suit_dark)
				_:
					ci.draw_line(Vector2(0, -18 + bob), Vector2(2, -23 + bob), suit_dark, 1.5)
					ci.draw_circle(Vector2(2.5, -24 + bob), 2.0, accent)
			# 헬멧과 얼굴 유리
			ci.draw_circle(Vector2(0, -9 + bob), 10, helmet)
			ci.draw_arc(Vector2(0, -9 + bob), 10, 0.0, TAU, 20, outline, 1.2)
			ci.draw_colored_polygon(Util.ellipse(Vector2(0.5, -8.5 + bob), 7.8, 6.6, 16), glass)
			ci.draw_colored_polygon(Util.ellipse(Vector2(-2.5, -12 + bob), 3.0, 1.3, 8), Color(1, 1, 1, 0.5))
			# 눈 (살짝 앞쪽을 봄)
			Util.eye(ci, Vector2(-2.6, -8 + bob), 2.4, Vector2(0.8, 0.0))
			Util.eye(ci, Vector2(3.6, -8 + bob), 2.4, Vector2(0.8, 0.0))
			ci.draw_circle(Vector2(-5.2, -5.2 + bob), 1.2, Color(1.0, 0.55, 0.65, 0.7))
			ci.draw_circle(Vector2(6.2, -5.2 + bob), 1.2, Color(1.0, 0.55, 0.65, 0.7))
			if style == "cat":
				ci.draw_line(Vector2(6, -6 + bob), Vector2(11, -7 + bob), Color(1, 1, 1, 0.8), 1.0)
				ci.draw_line(Vector2(6, -5 + bob), Vector2(11, -4 + bob), Color(1, 1, 1, 0.8), 1.0)
				ci.draw_line(Vector2(-9, 6 + bob), Vector2(-15, 0 + bob), accent, 3.0)
			elif style == "owl":
				ci.draw_arc(Vector2(-2.6, -8 + bob), 4.2, 0.0, TAU, 12, Color(1.0, 0.85, 0.35), 1.4)
				ci.draw_arc(Vector2(3.6, -8 + bob), 4.2, 0.0, TAU, 12, Color(1.0, 0.85, 0.35), 1.4)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(0.4, -5.5 + bob), Vector2(2.6, -5.5 + bob), Vector2(1.5, -3.2 + bob)]), accent)
