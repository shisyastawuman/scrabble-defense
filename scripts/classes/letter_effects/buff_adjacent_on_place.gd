class_name BuffAdjacentOnPlaceEffect
extends LetterEffect

@export var amount: int = 1


func on_placed(game: Node, tile: Node2D) -> void:
	if game.has_method("buff_adjacent_walls"):
		game.buff_adjacent_walls(tile, amount)


func get_description() -> String:
	return "On place, adjacent letters gain +%d strength." % amount
