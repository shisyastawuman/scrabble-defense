class_name DamageEnemyEffect
extends SpellEffect

@export var amount: int = 1


func apply(_game: Node, target: Variant) -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(amount, "spell")
