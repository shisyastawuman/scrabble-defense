class_name PlayerState
extends Resource

const SAVE_PATH := "user://player_state.tres"

@export var gold: int = 0
@export var vowel_hand_size: int = 3
@export var consonant_hand_size: int = 4
@export var max_energy: int = 8
@export var energy_gain: int = 1
@export var spells: Array[Spell] = []
@export var owned_letters: Array[LetterBlueprint] = []
@export var purchased_ids: PackedStringArray = PackedStringArray()
@export var level_index: int = 0


static func from_player(player: Player) -> PlayerState:
	var state := PlayerState.new()
	if player == null:
		return state
	state.vowel_hand_size = player.vowel_hand_size
	state.consonant_hand_size = player.consonant_hand_size
	state.max_energy = maxi(player.max_energy, 1)
	state.spells = player.spells.duplicate()
	if player.stack_blueprint:
		for letter_set in player.stack_blueprint.letter_sets:
			if letter_set == null or letter_set.letter_blueprint == null:
				continue
			for _i in letter_set.amount:
				state.owned_letters.append(letter_set.letter_blueprint.duplicate(true))
	return state


func save_to_disk() -> void:
	ResourceSaver.save(self, SAVE_PATH)


static func load_from_disk() -> PlayerState:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var loaded = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is PlayerState:
		return loaded
	return null


func has_purchased(offer_id: String) -> bool:
	return offer_id in purchased_ids


func mark_purchased(offer_id: String) -> void:
	if offer_id.is_empty() or has_purchased(offer_id):
		return
	purchased_ids.append(offer_id)
