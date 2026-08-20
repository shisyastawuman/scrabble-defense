class_name EnemyEffect
extends Resource

## Called when the enemy is created on the map.
func on_spawn(_enemy: Node2D, _board: Node) -> void:
	pass


## Called after the enemy's health drops to 0, before it is freed.
func on_death(_enemy: Node2D, _board: Node) -> void:
	pass


## Return true if the enemy should skip the wall (for example, jump over it).
func on_wall_encounter(_enemy: Node2D, _wall: Node2D) -> bool:
	return false
