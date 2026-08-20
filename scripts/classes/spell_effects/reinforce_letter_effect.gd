class_name ReinforceLetterEffect
extends SpellEffect

@export var amount: int = 1


func apply(game: Node, target: Variant) -> void:
	if target != null and target.has_method("heal"):
		target.heal(amount)
		if game.has_method("popup_at_tile"):
			game.popup_at_tile(target, "+%d" % amount, Color(1.0, 0.85, 0.3))
