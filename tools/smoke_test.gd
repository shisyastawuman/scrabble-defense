extends SceneTree

const Words := preload("res://scripts/word_dictionary.gd")
const LetterType := preload("res://scripts/classes/letter.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: PackedStringArray = []
	if FileAccess.file_exists("user://player_state.tres"):
		DirAccess.remove_absolute("user://player_state.tres")
	var scene: PackedScene = load("res://scenes/game_manager.tscn")
	if scene == null:
		errors.append("Could not load game_manager.tscn")
		_finish(errors)
		return
	var game_root = scene.instantiate()
	if game_root == null:
		errors.append("Could not instantiate game_manager.tscn")
		_finish(errors)
		return
	root.add_child(game_root)
	if not await _wait_until(func() -> bool:
		return game_root.turn >= 1 and game_root.phase == game_root.Phase.PLAYER
	):
		errors.append("Timed out waiting for player turn 1.")
		_finish(errors)
		return
	if not game_root.has_method("_start_player_turn"):
		errors.append("Instantiated root is not GameManager.")
		_finish(errors)
		return
	var pm = game_root.player_manager
	if pm.vowel_hand.size() != 3:
		errors.append("Expected 3 vowels, got %d." % pm.vowel_hand.size())
	if pm.consonant_hand.size() != 3:
		errors.append("Expected 3 consonants, got %d." % pm.consonant_hand.size())
	if pm.bag.size() != 13:
		errors.append("Expected 13 letters left in bag, got %d." % pm.bag.size())
	if pm.spells.size() != 1:
		errors.append("Expected 1 spell.")
	if pm.max_energy != 8:
		errors.append("Expected max energy 8, got %d." % pm.max_energy)
	if game_root.grid.cols != 9 or game_root.grid.rows != 9:
		errors.append("Expected 9x9 grid, got %dx%d." % [game_root.grid.cols, game_root.grid.rows])
	if game_root.grid.village_cells.size() != 1:
		errors.append("Expected 1 village.")
	if game_root.grid.get_spawn_origins().size() != 4:
		errors.append("Expected 4 spawn origins, got %d." % game_root.grid.get_spawn_origins().size())
	if game_root.turn != 1:
		errors.append("Expected turn 1, got %d." % game_root.turn)
	if game_root.levels.size() != 3:
		errors.append("Expected 3 campaign levels, got %d." % game_root.levels.size())
	elif game_root.levels[0].waves.size() != 7:
		errors.append("Level 1 should have 7 waves.")
	elif game_root.levels[1].waves.size() != 10:
		errors.append("Level 2 should have 10 waves.")
	elif game_root.levels[2].waves.size() != 15:
		errors.append("Level 3 should have 15 waves.")
	elif game_root.levels[1].map.cols != 11 or game_root.levels[1].map.buildings.size() != 2:
		errors.append("Level 2 should be 11x11 with 2 houses.")
	elif game_root.levels[2].map.cols != 15 or game_root.levels[2].map.buildings.size() != 3:
		errors.append("Level 3 should be 15x15 with 3 houses.")
	if game_root.shop_catalog == null or game_root.shop_catalog.offers.size() < 10:
		errors.append("Shop catalog is missing offers.")
	if game_root.enemy_manager.enemies.size() != 1:
		errors.append("Expected 1 enemy after wave 1, got %d." % game_root.enemy_manager.enemies.size())
	if not Words.is_word("CAT") or not Words.is_word("STAR") or not Words.is_word("ATE") or not Words.is_word("DIE"):
		errors.append("Expected CAT/STAR/ATE/DIE to be valid.")
	elif Words.is_word("QZXQZX"):
		errors.append("Garbage word should be invalid.")
	elif Words.word_count < 1000:
		errors.append("Dictionary did not load (count=%d)." % Words.word_count)
	_test_word(game_root, errors)
	if errors.is_empty():
		await game_root._on_end_turn()
		if not await _wait_until(func() -> bool:
			return game_root.turn >= 2 and game_root.phase == game_root.Phase.PLAYER
		):
			errors.append("Timed out waiting for player turn 2.")
		elif game_root.board.walls.size() != 3:
			errors.append("Expected 3 walls after CAT, got %d." % game_root.board.walls.size())
		elif game_root.turn != 2:
			errors.append("Expected turn 2 after end turn, got %d." % game_root.turn)
		elif game_root.enemy_manager.enemies.size() < 1:
			errors.append("Expected enemies after wave 2.")
	print("SMOKE_OK vowels=", pm.vowel_hand.size(), " bag=", pm.bag.size(), " dict=", Words.word_count, " shop=", game_root.shop_catalog.offers.size())
	_finish(errors)


func _wait_until(predicate: Callable, seconds: float = 5.0) -> bool:
	var waited := 0.0
	while waited < seconds:
		if predicate.call():
			return true
		await create_timer(0.05).timeout
		waited += 0.05
	return predicate.call()


func _letter(ch: String):
	var letter = LetterType.new()
	letter.char = ch
	letter.health = 1
	letter.original_char = ch
	letter.original_health = 1
	return letter


func _test_word(gm, errors: PackedStringArray) -> void:
	# Stay off the village's row/column so the first raider cannot smash the word.
	gm.board.place_pending(Vector2i(1, 2), _letter("C"))
	gm.board.place_pending(Vector2i(2, 2), _letter("A"))
	gm.board.place_pending(Vector2i(3, 2), _letter("T"))
	if not gm.board.current_result.valid:
		errors.append("CAT should be valid, got: %s" % gm.board.current_result.message)
	elif gm.board.current_result.energy != 3:
		errors.append("CAT should give 3 energy, got %d." % gm.board.current_result.energy)
	else:
		print("SMOKE_WORD ", gm.board.current_result.message)


func _finish(errors: PackedStringArray) -> void:
	if errors.is_empty():
		print("SMOKE_PASSED")
		quit(0)
	else:
		for err in errors:
			push_error(err)
			print("SMOKE_FAIL ", err)
		quit(1)
