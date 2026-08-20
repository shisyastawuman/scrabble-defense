class_name GainStrengthEachTurnEffect
extends LetterEffect

@export var amount: int = 1


func on_player_turn(game: Node, tile: Node2D) -> void:
	if tile != null and tile.has_method("heal"):
		tile.heal(amount)
		if game.has_method("popup_at_tile"):
			game.popup_at_tile(tile, "+%d" % amount, Color(1.0, 0.85, 0.3))


func get_description() -> String:
	return "Gains +%d strength every turn." % amount
