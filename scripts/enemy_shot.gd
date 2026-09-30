class_name EnemyShot
extends Node2D
## 적이 쏘는 탄. 플레이어에게만 맞는다.

var vel := Vector2.ZERO
var damage := 5.0
var radius := 6.0
var life := 5.0
var color := Color(1.0, 0.35, 0.5)
var dead := false
var source := "원거리 공격"
var slow := 0.0     # 맞으면 플레이어가 느려지는 시간


static func make(pos: Vector2, p_vel: Vector2, dmg: float, col: Color = Color(1.0, 0.35, 0.5), r: float = 6.0, src: String = "원거리 공격", p_slow: float = 0.0) -> EnemyShot:
	var s := EnemyShot.new()
	s.position = pos
	s.vel = p_vel
	s.damage = dmg
	s.color = col
	s.radius = r
	s.source = src
	s.slow = p_slow
	s.z_index = 4
	return s


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 1.9, Color(color.r, color.g, color.b, 0.22))
	draw_circle(Vector2.ZERO, radius * 1.25, Color(color.r, color.g, color.b, 0.55))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.9))
