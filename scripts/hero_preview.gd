class_name HeroPreview
extends Control
## 캐릭터 선택 화면에 보이는 캐릭터 그림 (살짝 위아래로 움직임)

var char_id := "knight"
var locked := false
var t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(96, 96)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var pal := Player.palette_for(GameData.character(char_id))
	if locked:
		# 아직 해금하지 않은 캐릭터는 어두운 실루엣으로 표시
		var dark := Color(0.13, 0.11, 0.2)
		pal = {"cloth": dark, "cloth_dark": dark, "skin": dark, "hair": dark, "boot": dark}
	draw_set_transform(size / 2.0 + Vector2(0, 3), 0.0, Vector2(2.5, 2.5))
	Player.draw_hero(self, pal, -absf(sin(t * 3.0)) * 1.5, 0.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if locked:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(size.x / 2.0 - 8, size.y / 2.0 + 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.75, 0.7, 0.95))
