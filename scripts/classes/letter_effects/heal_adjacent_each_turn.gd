class_name HealAdjacentEachTurnEffect
extends LetterEffect

@export var amount: int = 1


func on_player_turn(game: Node, tile: Node2D) -> void:
	if game.has_method("buff_adjacent_walls"):
		game.buff_adjacent_walls(tile, amount)


func get_description() -> String:
	return "Each turn, adjacent walls gain +%d strength." % amount
