class_name ShootFarthestEachTurnEffect
extends LetterEffect

@export var damage: int = 1


func on_player_turn(game: Node, tile: Node2D) -> void:
	if game.has_method("letter_shoot_farthest"):
		game.letter_shoot_farthest(tile, damage)


func get_description() -> String:
	return "Each turn, shoot the farthest enemy for %d." % damage
