class_name EnergyEachTurnEffect
extends LetterEffect

@export var amount: int = 1


func on_player_turn(game: Node, tile: Node2D) -> void:
	if game.has_method("add_energy"):
		game.add_energy(amount, "letter")
		if game.has_method("popup_at_tile"):
			game.popup_at_tile(tile, "+%d energy" % amount, Color(0.55, 0.85, 1.0))


func get_description() -> String:
	return "Player gains +%d energy every turn." % amount
