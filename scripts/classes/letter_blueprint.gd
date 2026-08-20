class_name LetterBlueprint
extends Resource

@export var char: String = ""
@export var health: int = 1
@export var is_blank: bool = false
@export var place_effects: Array[LetterEffect] = []
@export var turn_effects: Array[LetterEffect] = []
@export_multiline var tooltip: String = ""


func is_vowel() -> bool:
	if is_blank:
		return false
	return char.to_upper() in ["A", "E", "I", "O", "U"]
