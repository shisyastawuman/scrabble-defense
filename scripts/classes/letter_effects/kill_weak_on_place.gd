class_name KillWeakEnemyOnPlaceEffect
extends LetterEffect

@export var max_health: int = 2


func on_placed(game: Node, _tile: Node2D) -> void:
	if game.has_method("kill_random_weak_enemy"):
		game.kill_random_weak_enemy(max_health)


func get_description() -> String:
	return "On place, kill a random enemy with %d HP or less." % max_health
