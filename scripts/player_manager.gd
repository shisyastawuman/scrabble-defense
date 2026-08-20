class_name PlayerManager
extends Node

signal energy_changed(energy: int)
signal hand_changed
signal piles_changed

var bag: Array[Letter] = []
var discard_pile: Array[Letter] = []
var vowel_hand: Array[Letter] = []
var consonant_hand: Array[Letter] = []
var energy: int = 0
var vowel_hand_size: int = 3
var consonant_hand_size: int = 3
var max_energy: int = 8
var spells: Array[Spell] = []
var selected: Letter = null
var spell_extra_costs: Dictionary = {}


func setup_from_state(state: PlayerState) -> void:
	bag.clear()
	discard_pile.clear()
	vowel_hand.clear()
	consonant_hand.clear()
	selected = null
	energy = 0
	spell_extra_costs.clear()
	spells.clear()
	vowel_hand_size = state.vowel_hand_size
	consonant_hand_size = state.consonant_hand_size
	max_energy = maxi(state.max_energy, 1)
	for spell in state.spells:
		spells.append(spell)
	for blueprint in state.owned_letters:
		if blueprint == null:
			continue
		var letter := Letter.from_blueprint(blueprint)
		letter.current_zone = Letter.ZONE.STACK
		bag.append(letter)
	randomize()
	bag.shuffle()
	refill_hand()
	energy_changed.emit(energy)
	piles_changed.emit()
	hand_changed.emit()


func capture_state(state: PlayerState) -> void:
	state.vowel_hand_size = vowel_hand_size
	state.consonant_hand_size = consonant_hand_size
	state.max_energy = max_energy
	state.spells = spells.duplicate()
	state.owned_letters.clear()
	for letter in all_letters():
		state.owned_letters.append(letter.to_blueprint())


func all_letters() -> Array[Letter]:
	var letters: Array[Letter] = []
	letters.append_array(bag)
	letters.append_array(discard_pile)
	letters.append_array(vowel_hand)
	letters.append_array(consonant_hand)
	return letters


func begin_turn() -> void:
	selected = null
	spell_extra_costs.clear()
	hand_changed.emit()


func set_energy(amount: int) -> void:
	energy = clampi(amount, 0, max_energy)
	energy_changed.emit(energy)


func add_energy(amount: int) -> int:
	var before := energy
	set_energy(energy + amount)
	return energy - before


func reduce_energy() -> void:
	set_energy(energy - 1)
	energy_changed.emit(energy)

func discard_energy() -> void:
	set_energy(0)


func spell_cost(spell: Spell) -> int:
	if spell == null:
		return 0
	var extra := int(spell_extra_costs.get(spell, 0))
	return spell.energy_cost + extra


func can_afford(spell: Spell) -> bool:
	return spell != null and energy >= spell_cost(spell)


func spend(cost: int) -> bool:
	if energy < cost:
		return false
	energy -= cost
	energy_changed.emit(energy)
	return true


func note_spell_used(spell: Spell) -> void:
	if spell != null and spell.escalating_cost:
		spell_extra_costs[spell] = int(spell_extra_costs.get(spell, 0)) + 1


func select_letter(letter: Letter) -> void:
	if selected == letter:
		selected = null
	else:
		selected = letter
	hand_changed.emit()


func take_letter(letter: Letter) -> Letter:
	if letter == null:
		return null
	vowel_hand.erase(letter)
	consonant_hand.erase(letter)
	if selected == letter:
		selected = null
	letter.current_zone = Letter.ZONE.BOARD
	hand_changed.emit()
	return letter


func take_selected() -> Letter:
	return take_letter(selected)


func return_letter(letter: Letter) -> void:
	if letter == null:
		return
	if letter.is_blank:
		letter.chosen = false
		letter.char = ""
	letter.current_zone = Letter.ZONE.HAND
	if letter.is_vowel():
		vowel_hand.append(letter)
	else:
		consonant_hand.append(letter)
	hand_changed.emit()


func send_to_discard(letter: Letter) -> void:
	if letter == null:
		return
	if letter.is_blank:
		letter.chosen = false
		letter.char = ""
	letter.current_zone = Letter.ZONE.DISCARD
	discard_pile.append(letter)
	piles_changed.emit()


func discard_from_hand(letter: Letter) -> Letter:
	if letter == null:
		return null
	vowel_hand.erase(letter)
	consonant_hand.erase(letter)
	if selected == letter:
		selected = null
	send_to_discard(letter)
	hand_changed.emit()
	return letter


func refill_hand() -> void:
	while vowel_hand.size() < vowel_hand_size:
		var letter := _draw(true)
		if letter == null:
			break
		letter.current_zone = Letter.ZONE.HAND
		vowel_hand.append(letter)
	while consonant_hand.size() < consonant_hand_size:
		var letter := _draw(false)
		if letter == null:
			break
		letter.current_zone = Letter.ZONE.HAND
		consonant_hand.append(letter)
	selected = null
	hand_changed.emit()
	piles_changed.emit()


func describe_pile(pile: Array[Letter]) -> String:
	if pile.is_empty():
		return "(empty)"
	var glyphs: Array[String] = []
	for letter in pile:
		glyphs.append(letter.display_char())
	glyphs.sort()
	return " ".join(glyphs)


func _draw(want_vowel: bool) -> Letter:
	var found := _take_from_bag(want_vowel)
	if found != null:
		return found
	# Bag often still has the other type, so "empty bag" is the wrong trigger.
	# Shuffle discard in whenever the requested type is missing.
	if not _recycle_discard_into_bag():
		return null
	return _take_from_bag(want_vowel)


func _recycle_discard_into_bag() -> bool:
	if discard_pile.is_empty():
		return false
	var moving: Array[Letter] = discard_pile.duplicate()
	discard_pile.clear()
	for letter in moving:
		if letter == null:
			continue
		letter.current_zone = Letter.ZONE.STACK
		bag.append(letter)
	bag.shuffle()
	piles_changed.emit()
	return true


func _take_from_bag(want_vowel: bool) -> Letter:
	for i in bag.size():
		if bag[i].is_blank:
			# Blanks sit in the consonant hand.
			if want_vowel:
				continue
			var blank: Letter = bag[i]
			bag.remove_at(i)
			blank.current_zone = Letter.ZONE.HAND
			return blank
		if bag[i].is_vowel() == want_vowel:
			var letter: Letter = bag[i]
			bag.remove_at(i)
			letter.current_zone = Letter.ZONE.HAND
			return letter
	return null
