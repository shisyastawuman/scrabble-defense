class_name FreezeEnemiesEffect
extends SpellEffect


func apply(game: Node, _target: Variant) -> void:
	if game.has_method("freeze_all_enemies"):
		game.freeze_all_enemies()
