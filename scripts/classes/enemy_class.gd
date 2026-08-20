class_name EnemyClass
extends Resource

enum Shape { TRIANGLE, SQUARE, DIAMOND, CIRCLE, HEX, STAR }

@export var display_name: String = "Enemy"
@export var health: int = 1
@export var speed: int = 1
@export var damage: int = 1
@export var shape: Shape = Shape.TRIANGLE
@export_multiline var tooltip: String = ""
@export var actions: Array[EnemyAction] = []
@export var spawn_effects: Array[EnemyEffect] = []
@export var death_effects: Array[EnemyEffect] = []
@export var wall_effects: Array[EnemyEffect] = []
