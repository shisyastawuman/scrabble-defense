class_name Spell
extends Resource

enum TargetMode { NONE, ENEMY, WALL, HAND_LETTER }

@export var display_name: String = "Spell"
@export var description: String = ""
@export var energy_cost: int = 1
@export var target_mode: TargetMode = TargetMode.ENEMY
@export var escalating_cost: bool = false
@export var effects: Array[SpellEffect] = []
