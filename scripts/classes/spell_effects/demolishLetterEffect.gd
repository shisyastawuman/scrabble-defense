class_name DemolishLetterEffect
extends SpellEffect


func apply(game: Node, target: Variant) -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(target.letter.health)
		if game.has_method("popup_at_tile"):
			game.popup_at_tile(target, "-%d" % target.letter.health, Color(1.0, 0.0, 0.302, 1.0))
