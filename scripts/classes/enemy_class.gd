class_name EnemyClass
extends Resource

enum SpawnMode { VILLAGE_RAY, ADJACENT_TO_SPAWN, RANDOM_BORDER }
enum Goal { VILLAGE, OPPOSITE_EDGE, NUMBER_OF_STEPS }

@export var display_name: String = "Enemy"
@export var health: int = 1
@export var speed: int = 1
@export var damage: int = 1
@export var sprite: Texture2D
@export_multiline var tooltip: String = ""
@export var actions: Array[EnemyAction] = []
@export var spawn_effects: Array[EnemyEffect] = []
@export var death_effects: Array[EnemyEffect] = []
@export var wall_effects: Array[EnemyEffect] = []
@export var spawn_mode: SpawnMode = SpawnMode.VILLAGE_RAY
@export var goal: Goal = Goal.VILLAGE
@export var goal_steps: int = 1
@export var counts_for_win: bool = true
