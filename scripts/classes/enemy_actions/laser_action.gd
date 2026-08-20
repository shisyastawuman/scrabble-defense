class_name LaserAction
extends EnemyAction

@export var interval: int = 3
@export var damage: int = 2


func execute(enemy: Node2D) -> void:
	if enemy == null:
		return
	var existed := int(enemy.get("turns_existed"))
	if existed <= 0 or existed % interval != 0:
		return
	var game := enemy.get_tree().get_first_node_in_group("game_manager")
	if game == null:
		return
	var cell: Vector2i = enemy.cell
	var forward: Vector2i = enemy.forward
	var probe := cell + forward
	while game.grid.is_in_bounds(probe):
		if game.board.has_wall(probe):
			var wall = game.board.get_wall(probe)
			if wall:
				wall.take_damage(damage)
			if game.has_method("popup_at_cell"):
				game.popup_at_cell(probe, "-%d" % damage, Color(1.0, 0.2, 0.2))
		if game.grid.is_village(probe):
			break
		probe += forward
	if game.has_method("play_spell_burst"):
		game.play_spell_burst(enemy.global_position, Color(1.0, 0.25, 0.15))
