class_name GainSpeedAction
extends EnemyAction

@export var amount: int = 1
@export var interval: int = 2


func execute(enemy: Node2D) -> void:
	if enemy == null:
		return
	var existed := int(enemy.get("turns_existed"))
	if existed > 0 and existed % interval == 0:
		enemy.set("speed", int(enemy.get("speed")) + amount)
		enemy.queue_redraw()
