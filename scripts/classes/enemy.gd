class_name Enemy
extends Node2D

signal died(enemy: Enemy)
signal damaged(enemy: Enemy)

var data: EnemyClass
var health: int = 1
var speed: int = 1
var sprite: Sprite2D
var damage: int = 1
var cell: Vector2i
var origin_cell: Vector2i
#var village_target: Vector2i
var forward: Vector2i = Vector2i.DOWN
var turns_existed: int = 0
var tile_size: int = 48
var frozen: bool = false
var _stored_speed: int = 1
var last_hit: String = "other"
var _dying: bool = false
var _remaining_steps: int = 0


func setup(p_data: EnemyClass, p_cell: Vector2i, p_forward: Vector2i, p_tile_size: int) -> void:
	data = p_data
	health = p_data.health
	speed = p_data.speed
	damage = p_data.damage
	_stored_speed = p_data.speed
	cell = p_cell
	origin_cell = p_cell
	#village_target = p_village
	forward = p_forward
	tile_size = p_tile_size
	z_index = 4
	scale = Vector2.ONE
	_dying = false
	sprite = %Sprite
	sprite.texture = data.sprite
	if data.goal == EnemyClass.Goal.NUMBER_OF_STEPS:
		_remaining_steps = data.goal_steps
	queue_redraw()


func freeze() -> void:
	if frozen:
		return
	frozen = true
	_stored_speed = speed
	speed = 0
	queue_redraw()


func unfreeze() -> void:
	if not frozen:
		return
	frozen = false
	speed = maxi(_stored_speed, 0)
	queue_redraw()


func take_damage(amount: int, source: String = "other") -> void:
	if _dying:
		return
	last_hit = source
	health -= amount
	damaged.emit(self)
	queue_redraw()
	if health <= 0:
		_dying = true
		_play_death()


func _play_death() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5)
	tween.parallel().tween_property(self, "rotation_degrees", 359, 0.5)
	tween.tween_callback(func() -> void:
		died.emit(self)
	)


func animate_to(world_pos: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", world_pos, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func get_tooltip() -> String:
	var lines: PackedStringArray = []
	var title := data.display_name if data else "Enemy"
	lines.append(title)
	lines.append("Health: %d" % health)
	lines.append("Speed: %d" % speed)
	lines.append("Damage: %d" % damage)
	lines.append("Facing: %s" % _dir_name())
	if frozen:
		lines.append("Frozen until your next turn.")
	if data and not data.tooltip.is_empty():
		lines.append(data.tooltip)
	else:
		lines.append("Moves toward the village. Smashes walls in its path.")
	return "\n".join(lines)


func _dir_name() -> String:
	if forward.x > 0:
		return "east"
	if forward.x < 0:
		return "west"
	if forward.y > 0:
		return "south"
	return "north"


func _draw() -> void:
	var fill := GameColors.enemy_fill(maxi(health, 1))
	if frozen:
		fill = fill.lerp(Color(0.6, 0.85, 1.0), 0.55)
	var outline := fill.darkened(0.45)
	var radius := 16.0
	_draw_arrow(radius)
	_draw_pips(health, Vector2(0, radius + 6))


func _draw_arrow(radius: float) -> void:
	var dir := Vector2(forward)
	if dir == Vector2.ZERO:
		return
	var tip := dir.normalized() * (radius + 8.0)
	var side := dir.normalized().orthogonal() * 5.0
	var arrow := PackedVector2Array([tip, tip - dir.normalized() * 8.0 + side, tip - dir.normalized() * 8.0 - side])
	draw_colored_polygon(arrow, Color(0.863, 0.0, 0.243, 0.902))


func _draw_pips(hp: int, origin: Vector2) -> void:
	var pips := mini(maxi(hp, 0), 10)
	var pip_w := 4.0
	var gap := 1.5
	var total := pips * pip_w + maxi(pips - 1, 0) * gap
	var x := origin.x - total * 0.5
	for i in pips:
		draw_rect(Rect2(Vector2(x, origin.y), Vector2(pip_w, 4)), Color.WHITE, true)
		x += pip_w + gap
