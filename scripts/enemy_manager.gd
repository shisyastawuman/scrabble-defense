class_name EnemyManager
extends Node

signal enemy_reached_village
signal enemies_changed

@export var enemy_scene: PackedScene

var grid: Grid
var board: Board
var level: Level
var enemy_layer: Node2D
var player_manager: PlayerManager
var enemies: Array[Enemy] = []
var next_wave_index: int = 0
var _ended: bool = false

func setup(p_grid: Grid, p_board: Board, p_level: Level, p_layer: Node2D, p_player: PlayerManager) -> void:
	grid = p_grid
	board = p_board
	level = p_level
	enemy_layer = p_layer
	player_manager = p_player
	next_wave_index = 0
	_ended = false
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	enemies_changed.emit()


func has_living_enemies() -> bool:
	_prune()
	return not enemies.is_empty()


func has_remaining_waves() -> bool:
	return level != null and next_wave_index < level.waves.size()


func enemy_at(cell: Vector2i) -> Enemy:
	_prune()
	for enemy in enemies:
		if enemy.cell == cell:
			return enemy
	return null


func enemies_at(cell: Vector2i) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.cell == cell:
			found.append(enemy)
	return found


func crush_cell(cell: Vector2i) -> void:
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.cell == cell:
			enemy.take_damage(99, "crush")


func run_actions() -> void:
	_prune()
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		enemy.turns_existed += 1
		if enemy.frozen or enemy.data == null:
			continue
		for action in enemy.data.actions:
			if action:
				action.execute(enemy)
	enemies_changed.emit()


func run_movement() -> void:
	_prune()
	for enemy in enemies.duplicate():
		if _ended:
			return
		if not is_instance_valid(enemy):
			continue
		await _move_enemy(enemy)
		_restack()
	enemies_changed.emit()


func spawn_next_wave() -> void:
	if not has_remaining_waves():
		return
	var wave: Wave = level.waves[next_wave_index]
	next_wave_index += 1
	if wave == null:
		return
	var origins := grid.get_spawn_origins()
	if origins.is_empty():
		return
	for group in wave.groups:
		if group == null or group.enemy == null:
			continue
		for _i in group.count:
			if _ended:
				return
			var origin: Dictionary = origins.pick_random()
			_spawn(group.enemy, origin)
			await get_tree().create_timer(0.08).timeout
	_restack()
	enemies_changed.emit()


func tooltip_at(cell: Vector2i) -> String:
	var list := enemies_at(cell)
	if list.is_empty():
		return ""
	var parts: PackedStringArray = []
	for enemy in list:
		parts.append(enemy.get_tooltip())
	return "\n\n".join(parts)


func _spawn(blueprint: EnemyClass, origin: Dictionary) -> void:
	var enemy = enemy_scene.instantiate() as Enemy
	enemy.setup(
		blueprint,
		origin.cell,
		origin.village,
		origin.forward,
		board._tile_size()
	)
	enemy.position = board.cell_to_local(origin.cell)
	enemy.died.connect(_on_enemy_died)
	enemy_layer.add_child(enemy)
	enemies.append(enemy)
	if blueprint.spawn_effects:
		for effect in blueprint.spawn_effects:
			if effect:
				effect.on_spawn(enemy, board)


func _move_enemy(enemy: Enemy) -> void:
	var steps := enemy.speed
	for _step in steps:
		if _ended or not is_instance_valid(enemy) or enemy.health <= 0:
			return
		if grid.is_village(enemy.cell):
			_ended = true
			enemy_reached_village.emit()
			return
		var next: Vector2i = enemy.cell + enemy.forward
		if not grid.is_in_bounds(next):
			return
		if grid.is_village(next):
			enemy.cell = next
			await enemy.animate_to(board.cell_to_local(next))
			_ended = true
			enemy_reached_village.emit()
			return
		if board.has_wall(next):
			var wall := board.get_wall(next)
			var jumped := false
			if enemy.data:
				for effect in enemy.data.wall_effects:
					if effect and effect.on_wall_encounter(enemy, wall):
						jumped = true
			if jumped:
				enemy.cell = next
				await enemy.animate_to(board.cell_to_local(next))
				continue
			await _smash(enemy, wall)
			if board.has_wall(next):
				return
			if not is_instance_valid(enemy) or enemy.health <= 0:
				return
			continue
		enemy.cell = next
		await enemy.animate_to(board.cell_to_local(next))


func _smash(enemy: Enemy, wall: LetterTile) -> void:
	if wall:
		wall.take_damage(enemy.damage)
	if is_instance_valid(enemy):
		enemy.take_damage(1, "wall")
	await get_tree().create_timer(0.12).timeout


func unfreeze_all() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.unfreeze()


func freeze_all() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.freeze()


func living() -> Array[Enemy]:
	_prune()
	return enemies.duplicate()


func _on_enemy_died(enemy: Enemy) -> void:
	if enemy and enemy.data:
		for effect in enemy.data.death_effects:
			if effect:
				effect.on_death(enemy, board)
	enemies.erase(enemy)
	if is_instance_valid(enemy):
		enemy.queue_free()
	enemies_changed.emit()


func _prune() -> void:
	var living: Array[Enemy] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.health > 0:
			living.append(enemy)
	enemies = living


func _restack() -> void:
	var buckets := {}
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not buckets.has(enemy.cell):
			buckets[enemy.cell] = []
		buckets[enemy.cell].append(enemy)
	for cell in buckets:
		var stack: Array = buckets[cell]
		for i in stack.size():
			var offset := Vector2(i * 5, -i * 5)
			stack[i].position = board.cell_to_local(cell) + offset
