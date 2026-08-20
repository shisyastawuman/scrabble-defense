class_name StormDamageEffect
extends SpellEffect

@export var amount: int = 1
@export var hits: int = 5


func apply(game: Node, _target: Variant) -> void:
	if game.has_method("storm_damage"):
		game.storm_damage(amount, hits)
