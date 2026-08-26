class_name Grid
extends TileMapLayer

enum Terrain { GRASS, BUILDING, ENEMY_SPAWN }

var cols: int = 0
var rows: int = 0
var village_cells: Array[Vector2i] = []


func setup(p_rows: int, p_cols: int, buildings: Array[Vector2i]) -> void:
	clear()
	rows = p_rows
	cols = p_cols
	village_cells.clear()
	for building in buildings:
		if not is_enemy_land(building) and _in_rect(building, p_cols, p_rows):
			village_cells.append(building)
	for y in rows:
		for x in cols:
			var cell := Vector2i(x, y)
			var source_id := Terrain.GRASS
			var atlas := Vector2i(0, 0)
			if is_enemy_land(cell):
				source_id = Terrain.ENEMY_SPAWN
			elif cell in village_cells:
				source_id = Terrain.BUILDING
			set_cell(cell, source_id, atlas, 0)


func _in_rect(cell: Vector2i, p_cols: int, p_rows: int) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < p_cols and cell.y < p_rows


func is_in_bounds(cell: Vector2i) -> bool:
	return _in_rect(cell, cols, rows)


func is_enemy_land(cell: Vector2i) -> bool:
	if cols <= 0 or rows <= 0:
		return false
	if not is_in_bounds(cell):
		return false
	return cell.x == 0 or cell.y == 0 or cell.x == cols - 1 or cell.y == rows - 1


func is_village(cell: Vector2i) -> bool:
	return cell in village_cells


func is_buildable(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not is_enemy_land(cell) and not is_village(cell)


func cell_at_mouse() -> Vector2i:
	var cell := local_to_map(get_local_mouse_position())
	if not is_in_bounds(cell):
		return Vector2i(-9999, -9999)
	return cell


func get_spawn_origins() -> Array[Dictionary]:
	var origins: Array[Dictionary] = []
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1),
	]
	for village in village_cells:
		for dir in dirs:
			var cell := village
			var next := cell + dir
			while is_in_bounds(next):
				cell = next
				next = cell + dir
			if is_enemy_land(cell):
				origins.append({
					"cell": cell,
					"village": village,
					"forward": -dir
				})
	return origins
	
	
func get_spawn_adjacent_origins() -> Array[Dictionary]:
	var origins: Array[Dictionary] = []
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1),
	]
	var spawns := get_spawn_origins()
	var spawn_cells := {}
	for spawn in spawns:
		spawn_cells[spawn.cell] = true
	var seen := {}
	for spawn in spawns:
		for dir in dirs:
			var neighbor: Vector2i = spawn.cell + dir
			if seen.has(neighbor) or spawn_cells.has(neighbor):
				continue
			if not is_enemy_land(neighbor):
				continue
			seen[neighbor] = true
			origins.append({
				"cell": neighbor,
				"forward": spawn.forward
			})
	return origins


func get_border_origins_no_spawn() -> Array[Dictionary]:
	var origins: Array[Dictionary] = []
	var spawn_cells := {}
	for spawn in get_spawn_origins():
		spawn_cells[spawn.cell] = true
	for y in rows:
		for x in cols:
			var cell := Vector2i(x, y)
			if not is_enemy_land(cell) or _is_corner(cell) or spawn_cells.has(cell):
				continue
			origins.append({
				"cell": cell,
				"forward": _opposite_edge_forward(cell)
			})
	return origins


func _is_corner(cell: Vector2i) -> bool:
	var on_vertical := cell.x == 0 or cell.x == cols - 1
	var on_horizontal := cell.y == 0 or cell.y == rows - 1
	return on_vertical and on_horizontal


func _opposite_edge_forward(cell: Vector2i) -> Vector2i:
	if cell.x == 0:
		return Vector2i.RIGHT
	if cell.x == cols - 1:
		return Vector2i.LEFT
	if cell.y == 0:
		return Vector2i.DOWN
	return Vector2i.UP
