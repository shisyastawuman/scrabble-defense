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
var village_target: Vector2i
var forward: Vector2i = Vector2i.DOWN
var turns_existed: int = 0
var tile_size: int = 48
var frozen: bool = false
var _stored_speed: int = 1
var last_hit: String = "other"
var _dying: bool = false


func setup(p_data: EnemyClass, p_cell: Vector2i, p_village: Vector2i, p_forward: Vector2i, p_tile_size: int) -> void:
	data = p_data
	health = p_data.health
	speed = p_data.speed
	damage = p_data.damage
	_stored_speed = p_data.speed
	cell = p_cell
	village_target = p_village
	forward = p_forward
	tile_size = p_tile_size
	z_index = 4
	scale = Vector2.ONE
	_dying = false
	sprite = %Sprite
	sprite.texture = data.sprite
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
	#var shape := EnemyClass.Shape.TRIANGLE
	#if data and data.sprite:
		#
		#shape = data.shape
	#match shape:
		#EnemyClass.Shape.SQUARE:
			#var rect := Rect2(Vector2(-radius + 2, -radius + 2), Vector2((radius - 2) * 2, (radius - 2) * 2))
			#draw_rect(rect, fill, true)
			#draw_rect(rect, outline, false, 2.0)
		#EnemyClass.Shape.DIAMOND:
			#var pts := PackedVector2Array([
				#Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)
			#])
			#draw_colored_polygon(pts, fill)
			#var diamond_line := PackedVector2Array(pts)
			#diamond_line.append(pts[0])
			#draw_polyline(diamond_line, outline, 2.0, true)
		#EnemyClass.Shape.CIRCLE:
			#draw_circle(Vector2.ZERO, radius, fill)
			#draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, outline, 2.0, true)
		#EnemyClass.Shape.HEX:
			#var hex := PackedVector2Array()
			#for i in 6:
				#var ang := TAU * float(i) / 6.0 - TAU / 12.0
				#hex.append(Vector2(cos(ang), sin(ang)) * radius)
			#draw_colored_polygon(hex, fill)
			#var hex_line := PackedVector2Array(hex)
			#hex_line.append(hex[0])
			#draw_polyline(hex_line, outline, 2.0, true)
		#EnemyClass.Shape.STAR:
			#var star := PackedVector2Array()
			#for i in 10:
				#var ang := TAU * float(i) / 10.0 - PI / 2.0
				#var r := radius if i % 2 == 0 else radius * 0.45
				#star.append(Vector2(cos(ang), sin(ang)) * r)
			#draw_colored_polygon(star, fill)
		#_:
			#var tri := PackedVector2Array([
				#Vector2(0, -radius), Vector2(radius, radius * 0.85), Vector2(-radius, radius * 0.85)
			#])
			#draw_colored_polygon(tri, fill)
			#var tri_line := PackedVector2Array(tri)
			#tri_line.append(tri[0])
			#draw_polyline(tri_line, outline, 2.0, true)
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
