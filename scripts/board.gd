class_name Board
extends Node2D

signal wall_destroyed(tile: LetterTile)

const INVALID_CELL := Vector2i(-9999, -9999)
const Words := preload("res://scripts/word_dictionary.gd")

var rules: Ruleset
var grid: Grid
var walls: Dictionary = {} # Vector2i -> LetterTile
var pending: Dictionary = {} # Vector2i -> Letter
var pending_tiles: Dictionary = {} # Vector2i -> LetterTile
var villages: Dictionary = {} # Vector2i -> Building
var current_result: PlacementResult = PlacementResult.new()
var highlight_cells: Array[Vector2i] = []
var preview_cell: Vector2i = INVALID_CELL
var preview_char: String = ""

var _village_scene := preload("res://scenes/building.tscn")


func setup(p_grid: Grid, _rules: Ruleset) -> void:
	grid = p_grid
	rules = _rules
	for child in get_children():
		child.queue_free()
	walls.clear()
	pending.clear()
	pending_tiles.clear()
	villages.clear()
	for cell in grid.village_cells:
		var village: Building = _village_scene.instantiate()
		village.setup(cell, _tile_size())
		village.position = cell_to_local(cell)
		add_child(village)
		villages[cell] = village
	current_result = PlacementResult.new()
	current_result.valid = false
	current_result.message = "Place letters on one row or column to form a word."
	queue_redraw()


func _tile_size() -> int:
	if grid and grid.tile_set:
		return grid.tile_set.tile_size.x
	return 48


func cell_to_local(cell: Vector2i) -> Vector2:
	return grid.map_to_local(cell)


func has_wall(cell: Vector2i) -> bool:
	return get_wall(cell) != null


func has_pending(cell: Vector2i) -> bool:
	return pending.has(cell)


func get_wall(cell: Vector2i) -> LetterTile:
	var tile: LetterTile = walls.get(cell)
	if tile == null or not is_instance_valid(tile) or not tile.is_blocking():
		return null
	return tile


func adjacent_walls(cell: Vector2i) -> Array[LetterTile]:
	var found: Array[LetterTile] = []
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var probe: Vector2i = cell + dir
		var tile := get_wall(probe)
		if tile:
			found.append(tile)
	return found


func all_wall_letters() -> Array[Letter]:
	var letters: Array[Letter] = []
	for cell in walls:
		var tile: LetterTile = walls[cell]
		if tile and tile.letter:
			letters.append(tile.letter)
	for cell in pending:
		letters.append(pending[cell])
	return letters


func occupancy() -> Dictionary:
	var occ := {}
	for cell in walls:
		occ[cell] = walls[cell].letter
	for cell in pending:
		occ[cell] = pending[cell]
	return occ


func place_pending(cell: Vector2i, letter: Letter) -> void:
	pending[cell] = letter
	letter.current_zone = Letter.ZONE.BOARD
	var tile := LetterTile.new()
	tile.setup(letter, cell, true, _tile_size())
	tile.position = cell_to_local(cell)
	add_child(tile)
	pending_tiles[cell] = tile
	revalidate()


func pickup_pending(cell: Vector2i) -> Letter:
	if not pending.has(cell):
		return null
	var letter: Letter = pending[cell]
	pending.erase(cell)
	if pending_tiles.has(cell):
		pending_tiles[cell].queue_free()
		pending_tiles.erase(cell)
	revalidate()
	return letter


func clear_pending_to_hand(player: PlayerManager) -> void:
	for cell in pending.keys():
		var letter: Letter = pending[cell]
		player.return_letter(letter)
	_clear_pending_visuals()
	pending.clear()
	revalidate()


func _clear_pending_visuals() -> void:
	for cell in pending_tiles:
		pending_tiles[cell].queue_free()
	pending_tiles.clear()


func revalidate() -> PlacementResult:
	current_result = validate_placement()
	queue_redraw()
	return current_result


func validate_placement() -> PlacementResult:
	var result := PlacementResult.new()
	if pending.is_empty():
		result.valid = true
		result.message = "Place letters on one row or column, or end the turn."
		return result
	var cells: Array[Vector2i] = []
	for cell in pending:
		cells.append(cell)
		if has_wall(cell):
			result.message = "That tile already has a wall."
			return result
		if not grid.is_buildable(cell):
			result.message = "Letters can only be placed on the inner field."
			return result
		var pending_letter: Letter = pending[cell]
		if pending_letter.is_blank and not pending_letter.chosen:
			result.message = "Choose a letter for the blank tile."
			return result
	result.new_cells = cells.duplicate()
	var same_row := true
	var same_col := true
	var first: Vector2i = cells[0]
	for cell in cells:
		if cell.y != first.y:
			same_row = false
		if cell.x != first.x:
			same_col = false
	if not same_row and not same_col:
		result.message = "All new letters must share one row or one column."
		return result
	var occ := occupancy()
	if same_row:
		var min_x := first.x
		var max_x := first.x
		for cell in cells:
			min_x = mini(min_x, cell.x)
			max_x = maxi(max_x, cell.x)
		for x in range(min_x, max_x + 1):
			if not occ.has(Vector2i(x, first.y)):
				result.message = "No empty spaces between new letters."
				return result
	else:
		var min_y := first.y
		var max_y := first.y
		for cell in cells:
			min_y = mini(min_y, cell.y)
			max_y = maxi(max_y, cell.y)
		for y in range(min_y, max_y + 1):
			if not occ.has(Vector2i(first.x, y)):
				result.message = "No empty spaces between new letters."
				return result
	var found: Array = []
	var seen := {}
	for cell in cells:
		for horizontal in [true, false]:
			var path := _expand_word(cell, occ, horizontal)
			if path.size() < 2:
				continue
			var key := _path_key(path)
			if seen.has(key):
				continue
			seen[key] = true
			found.append({"text": _path_text(path, occ), "path": path})
	var covered := {}
	for entry in found:
		for cell in entry.path:
			covered[cell] = true
	for cell in cells:
		if covered.has(cell):
			continue
		var glyph: String = pending[cell].display_char()
		if (glyph == "A" or glyph == "I") and _is_isolated(cell, occ):
			var solo: Array[Vector2i] = [cell]
			found.append({"text": glyph, "path": solo})
			covered[cell] = true
		else:
			result.message = "Every new letter must be part of a valid word."
			return result
	for entry in found:
		var text: String = entry.text
		if not Words.is_word(text):
			result.message = "%s is not a valid word." % text
			return result
		result.words.append(text)
		result.word_paths.append(entry.path)
		result.energy = maxi(0, result.energy + text.length() + rules.energy_offset)
	result.valid = true
	result.message = "Play %s  (+%d energy)." % [", ".join(result.words), result.energy]
	return result


func commit() -> Array[Vector2i]:
	var placed: Array[Vector2i] = []
	if not current_result.valid or pending.is_empty():
		return placed
	var word_counts := {}
	for path in current_result.word_paths:
		for cell in path:
			word_counts[cell] = int(word_counts.get(cell, 0)) + 1
	for cell in pending:
		placed.append(cell)
		var letter: Letter = pending[cell]
		var copy: Letter = letter.spawn_wall_copy()
		copy.health = int(word_counts.get(cell, 1))
		var tile: LetterTile = pending_tiles.get(cell)
		if tile == null:
			tile = LetterTile.new()
			add_child(tile)
		tile.setup(copy, cell, false, _tile_size())
		tile.position = cell_to_local(cell)
		if not tile.destroyed.is_connected(_on_wall_destroyed):
			tile.destroyed.connect(_on_wall_destroyed)
		walls[cell] = tile
	for cell in word_counts:
		if pending.has(cell):
			continue
		if not walls.has(cell):
			continue
		var existing: LetterTile = walls[cell]
		existing.letter.health += int(word_counts[cell])
		existing.queue_redraw()
	pending.clear()
	pending_tiles.clear()
	revalidate()
	return placed


func words_through(cell: Vector2i) -> Array[String]:
	var occ := occupancy()
	if not occ.has(cell):
		return []
	var names: Array[String] = []
	for horizontal in [true, false]:
		var path := _expand_word(cell, occ, horizontal)
		if path.size() < 2:
			continue
		var text := _path_text(path, occ)
		if Words.is_word(text) and not names.has(text):
			names.append(text)
	return names


func highlight_from(cell: Vector2i) -> void:
	highlight_cells.clear()
	var occ := occupancy()
	if not occ.has(cell) and not villages.has(cell):
		queue_redraw()
		return
	if occ.has(cell):
		for horizontal in [true, false]:
			var path := _expand_word(cell, occ, horizontal)
			for step in path:
				if not highlight_cells.has(step):
					highlight_cells.append(step)
	if highlight_cells.is_empty():
		highlight_cells.append(cell)
	queue_redraw()


func clear_highlight() -> void:
	if highlight_cells.is_empty() and preview_cell == INVALID_CELL:
		return
	highlight_cells.clear()
	preview_cell = INVALID_CELL
	preview_char = ""
	queue_redraw()


func _on_wall_destroyed(tile: LetterTile) -> void:
	if tile == null:
		return
	if walls.get(tile.cell) == tile:
		walls.erase(tile.cell)
		wall_destroyed.emit(tile)
	tile.queue_free()
	queue_redraw()


func _expand_word(start: Vector2i, occ: Dictionary, horizontal: bool) -> Array[Vector2i]:
	var step := Vector2i(1, 0) if horizontal else Vector2i(0, 1)
	var cells: Array[Vector2i] = [start]
	var cursor := start + step
	while occ.has(cursor):
		cells.append(cursor)
		cursor += step
	cursor = start - step
	while occ.has(cursor):
		cells.insert(0, cursor)
		cursor -= step
	return cells


func _path_text(path: Array[Vector2i], occ: Dictionary) -> String:
	var parts := PackedStringArray()
	for cell in path:
		var letter: Letter = occ[cell]
		parts.append(letter.display_char())
	return "".join(parts)


func _path_key(path: Array[Vector2i]) -> String:
	var bits := PackedStringArray()
	for cell in path:
		bits.append("%d,%d" % [cell.x, cell.y])
	return "|".join(bits)


func _is_isolated(cell: Vector2i, occ: Dictionary) -> bool:
	return _expand_word(cell, occ, true).size() == 1 and _expand_word(cell, occ, false).size() == 1


func _draw() -> void:
	if grid == null:
		return
	var size := float(_tile_size())
	for cell in highlight_cells:
		var pos := cell_to_local(cell) - Vector2(size, size) * 0.5
		draw_rect(Rect2(pos, Vector2(size, size)), Color(1, 0.92, 0.55, 0.22), true)
	if preview_cell != INVALID_CELL and not pending.has(preview_cell) and not walls.has(preview_cell):
		var pos := cell_to_local(preview_cell) - Vector2(size, size) * 0.5
		draw_rect(Rect2(pos, Vector2(size, size)), Color(1, 1, 1, 0.12), true)
