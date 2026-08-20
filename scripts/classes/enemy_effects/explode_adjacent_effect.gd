class_name ExplodeAdjacentEffect
extends EnemyEffect

@export var damage: int = 1


func on_death(enemy: Node2D, board: Node) -> void:
	if enemy == null or board == null:
		return
	var cell: Vector2i = enemy.cell
	var game := enemy.get_tree().get_first_node_in_group("game_manager")
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var probe := cell + Vector2i(dx, dy)
			if board.has_wall(probe):
				var wall = board.get_wall(probe)
				if wall:
					wall.take_damage(damage)
				if game and game.has_method("popup_at_cell"):
					game.popup_at_cell(probe, "-%d" % damage, Color(1.0, 0.45, 0.15))
	if game and game.has_method("play_spell_burst"):
		game.play_spell_burst(enemy.global_position, Color(1.0, 0.5, 0.1))
