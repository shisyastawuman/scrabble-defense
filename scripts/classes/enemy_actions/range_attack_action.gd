class_name RangeAttackAction
extends EnemyAction

@export var range_tiles: int = 2
@export var damage: int = 1


func execute(enemy: Node2D) -> void:
	if enemy == null:
		return
	var game := enemy.get_tree().get_first_node_in_group("game_manager")
	if game == null:
		return
	var cell: Vector2i = enemy.cell
	var forward: Vector2i = enemy.forward
	for i in range(1, range_tiles + 1):
		var probe: Vector2i = cell + forward * i
		if game.board.has_wall(probe):
			var wall = game.board.get_wall(probe)
			if wall:
				wall.take_damage(damage)
			if game.has_method("popup_at_cell"):
				game.popup_at_cell(probe, "-%d" % damage, Color(1, 0.4, 0.3))
			return
		if game.grid.is_village(probe):
			return
