class_name DiscardAndRedrawEffect
extends SpellEffect


func apply(game: Node, target: Variant) -> void:
	if game.has_method("discard_and_redraw"):
		game.discard_and_redraw(target)
