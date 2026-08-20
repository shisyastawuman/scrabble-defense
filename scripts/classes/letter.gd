class_name Letter
extends Resource

enum ZONE {STACK, HAND, BOARD, DISCARD, EXILE}

@export var char: String = ""
@export var health: int = 1
var original_health: int
var original_char: String
var is_blank: bool = false
var chosen: bool = false
var place_effects: Array[LetterEffect] = []
var turn_effects: Array[LetterEffect] = []
var tooltip: String = ""
var current_zone: ZONE = ZONE.STACK


static func from_blueprint(blueprint: LetterBlueprint) -> Letter:
	var letter := Letter.new()
	letter.char = blueprint.char
	letter.health = blueprint.health
	letter.original_char = blueprint.char
	letter.original_health = blueprint.health
	letter.is_blank = blueprint.is_blank
	letter.place_effects = blueprint.place_effects.duplicate()
	letter.turn_effects = blueprint.turn_effects.duplicate()
	letter.tooltip = blueprint.tooltip
	letter.current_zone = ZONE.STACK
	return letter


func to_blueprint() -> LetterBlueprint:
	var bp := LetterBlueprint.new()
	if is_blank:
		bp.char = ""
	else:
		bp.char = original_char if original_char != "" else char
	bp.health = original_health
	bp.is_blank = is_blank
	bp.place_effects = place_effects.duplicate()
	bp.turn_effects = turn_effects.duplicate()
	bp.tooltip = tooltip
	return bp


func is_vowel() -> bool:
	if is_blank and not chosen:
		return false
	return char.to_upper() in ["A", "E", "I", "O", "U"]


func display_char() -> String:
	if is_blank and not chosen:
		return "?"
	return char.to_upper()


func effect_text() -> String:
	var parts: PackedStringArray = []
	if not tooltip.is_empty():
		parts.append(tooltip)
	for effect in place_effects:
		if effect:
			parts.append(effect.get_description())
	for effect in turn_effects:
		if effect:
			parts.append(effect.get_description())
	return "\n".join(parts)
