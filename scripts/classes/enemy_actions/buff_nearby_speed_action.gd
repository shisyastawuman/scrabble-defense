class_name BuffNearbySpeedAction
extends EnemyAction

@export var amount: int = 1
@export var radius: int = 1


func execute(enemy: Node2D) -> void:
	var game := enemy.get_tree().get_first_node_in_group("game_manager")
	if game == null:
		return
	for other in game.enemy_manager.enemies:
		if other == null or other == enemy or not is_instance_valid(other):
			continue
		var dist: int = absi(other.cell.x - enemy.cell.x) + absi(other.cell.y - enemy.cell.y)
		if dist <= radius:
			other.speed += amount
			other.queue_redraw()
			if game.has_method("popup_at_cell"):
				game.popup_at_cell(other.cell, "+%d spd" % amount, Color(0.6, 0.9, 1.0))
