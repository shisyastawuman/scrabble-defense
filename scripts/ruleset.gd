extends Resource
class_name Ruleset

@export_category("GOLD REWARDS")
@export var gold_per_crush: int
@export var gold_per_wall_kill: int
@export var gold_per_spell_kill: int
@export_custom(PROPERTY_HINT_NONE, "Offset to nerf enery generation") var energy_offset: int = -2
