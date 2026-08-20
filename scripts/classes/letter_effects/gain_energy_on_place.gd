class_name GainEnergyOnPlaceEffect
extends LetterEffect

@export var amount: int = 2


func on_placed(game: Node, _tile: Node2D) -> void:
	if game.has_method("add_energy"):
		game.add_energy(amount, "place")


func get_description() -> String:
	return "+%d energy when placed." % amount
