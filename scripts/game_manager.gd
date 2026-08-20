class_name GameManager
extends Node

enum Phase { PLAYER, ENEMY_ACTIONS, ENEMY_MOVEMENT, ENEMY_SPAWN, GAME_OVER, TALLY, SHOP }

@export var levels: Array[Level]
@export var player: Player
@export var shop_catalog: ShopCatalog

var player_manager: PlayerManager
var enemy_manager: EnemyManager
var grid: Grid
var board: Board
var hud: HUD
var world: Node2D
var enemy_layer: Node2D
var vfx: VfxLayer

var player_state: PlayerState
var turn: int = 0
var phase: Phase = Phase.PLAYER
var word_locked: bool = false
var targeting_spell: Spell = null
var status_text: String = ""
var turn_start_energy: int = 0
var gold_wall: int = 0
var gold_crush: int = 0
var pending_shop_enchantment: LetterEffect = null
var _layout_margins := Rect2(220, 96, 24, 176)


func _ready() -> void:
	add_to_group("game_manager")
	world = $World
	grid = $World/Grid
	board = $World/Board
	enemy_layer = $World/Enemies
	player_manager = $PlayerManager
	enemy_manager = $EnemyManager
	hud = $HUD
	vfx = $World/Vfx
	player_state = PlayerState.load_from_disk()
	if player_state == null or player_state.owned_letters.is_empty():
		player_state = PlayerState.from_player(player)
	hud.setup(self)
	hud.end_turn_pressed.connect(_on_end_turn)
	hud.letter_pressed.connect(_on_letter_pressed)
	hud.letter_dropped.connect(_on_letter_dropped)
	hud.spell_pressed.connect(_on_spell_pressed)
	hud.restart_pressed.connect(_restart_run)
	hud.tally_ok_pressed.connect(_open_shop)
	hud.next_level_pressed.connect(_start_next_level)
	hud.shop_buy_pressed.connect(_buy_offer)
	hud.blank_chosen.connect(_on_blank_chosen)
	hud.blank_cancelled.connect(_on_blank_cancelled)
	hud.enchant_letter_chosen.connect(_apply_enchantment_to_letter)
	hud.enchant_cancelled.connect(_on_enchant_cancelled)
	board.wall_destroyed.connect(_on_wall_destroyed)
	enemy_manager.enemy_reached_village.connect(_on_village_reached)
	enemy_manager.enemies_changed.connect(_on_enemies_changed)
	player_manager.energy_changed.connect(func(_e: int) -> void: hud.refresh())
	player_manager.hand_changed.connect(func() -> void: hud.refresh())
	player_manager.piles_changed.connect(func() -> void: hud.refresh())
	get_viewport().size_changed.connect(_layout_world)
	_load_level_index(player_state.level_index)
	_layout_world()
	_on_end_turn()


func _load_level_index(index: int) -> void:
	if levels.is_empty():
		push_error("No levels configured.")
		return
	player_state.level_index = clampi(index, 0, levels.size() - 1)
	load_level(levels[player_state.level_index])


func load_level(level: Level) -> void:
	if level == null or level.map == null:
		push_error("Level is missing a map.")
		return
	gold_wall = 0
	gold_crush = 0
	turn = 0
	word_locked = false
	targeting_spell = null
	phase = Phase.PLAYER
	grid.setup(level.map.rows, level.map.cols, level.map.buildings)
	board.setup(grid)
	player_manager.setup_from_state(player_state)
	enemy_manager.setup(grid, board, level, enemy_layer, player_manager)
	_connect_enemy_signals()
	_layout_world()
	hud.refresh()


func _connect_enemy_signals() -> void:
	pass


func current_level() -> Level:
	if player_state.level_index >= 0 and player_state.level_index < levels.size():
		return levels[player_state.level_index]
	return null


func _start_player_turn() -> void:
	if phase == Phase.GAME_OVER or phase == Phase.TALLY or phase == Phase.SHOP:
		return
	turn += 1
	phase = Phase.PLAYER
	word_locked = false
	targeting_spell = null
	enemy_manager.unfreeze_all()
	player_manager.begin_turn()
	# Walls smashed last enemy phase land in discard after the previous refill.
	player_manager.refill_hand()
	_run_letter_turn_effects()
	turn_start_energy = player_manager.energy
	status_text = "Player turn — place a word or cast spells."
	hud.set_phase("Player turn")
	hud.refresh()


func _on_end_turn() -> void:
	if phase != Phase.PLAYER:
		return
	targeting_spell = null
	if not board.pending.is_empty():
		if not board.current_result.valid:
			hud.flash(board.current_result.message)
			return
		_commit_word()
	player_manager.refill_hand()
	await _resolve_after_player()
	if phase == Phase.GAME_OVER or phase == Phase.TALLY:
		return
	_start_player_turn()


func _resolve_after_player() -> void:
	phase = Phase.ENEMY_ACTIONS
	status_text = "Enemy actions..."
	hud.set_phase("Enemy actions")
	hud.refresh()
	enemy_manager.run_actions()
	await get_tree().create_timer(0.15).timeout
	if phase == Phase.GAME_OVER:
		return
	phase = Phase.ENEMY_MOVEMENT
	status_text = "Enemies moving..."
	hud.set_phase("Enemies moving")
	hud.refresh()
	await enemy_manager.run_movement()
	if phase == Phase.GAME_OVER:
		return
	phase = Phase.ENEMY_SPAWN
	status_text = "Enemies spawning..."
	hud.set_phase("Enemies spawning")
	hud.refresh()
	await enemy_manager.spawn_next_wave()
	if phase == Phase.GAME_OVER:
		return
	_check_win()


func _commit_word() -> void:
	var placed := board.commit()
	word_locked = true
	turn_start_energy = player_manager.energy
	for cell in placed:
		var tile: LetterTile = board.get_wall(cell)
		if tile:
			_fire_place_effects(tile)
			enemy_manager.crush_cell(cell)
			play_spell_burst(tile.position, Color(1.0, 0.85, 0.3))
	_check_win()
	hud.refresh()


func _fire_place_effects(tile: LetterTile) -> void:
	if tile == null or tile.letter == null:
		return
	for effect in tile.letter.place_effects:
		if effect:
			effect.on_placed(self, tile)


func _run_letter_turn_effects() -> void:
	for cell in board.walls.keys():
		var tile: LetterTile = board.walls[cell]
		if tile == null or tile.letter == null:
			continue
		for effect in tile.letter.turn_effects:
			if effect:
				effect.on_player_turn(self, tile)


func _on_letter_pressed(letter: Letter) -> void:
	if phase != Phase.PLAYER:
		return
	if targeting_spell and targeting_spell.target_mode == Spell.TargetMode.HAND_LETTER:
		_cast_spell(targeting_spell, letter)
		return
	if word_locked:
		return
	player_manager.select_letter(letter)
	hud.refresh()


func _on_letter_dropped(letter: Letter, screen_pos: Vector2) -> void:
	if phase != Phase.PLAYER or word_locked or letter == null:
		return
	var cell := _cell_from_screen(screen_pos)
	if cell.x < -9000:
		return
	player_manager.selected = letter
	_on_cell_clicked(cell)


func _on_spell_pressed(spell: Spell) -> void:
	if phase != Phase.PLAYER or spell == null:
		return
	if not player_manager.can_afford(spell):
		hud.flash("Not enough energy.")
		return
	if not board.pending.is_empty() and not word_locked:
		if not board.current_result.valid:
			hud.flash("Form a valid word before casting.")
			return
		_commit_word()
	if spell.target_mode == Spell.TargetMode.NONE:
		_cast_spell(spell, null)
		return
	targeting_spell = spell
	match spell.target_mode:
		Spell.TargetMode.ENEMY:
			hud.flash("Choose an enemy for %s." % spell.display_name)
		Spell.TargetMode.WALL:
			hud.flash("Choose a letter wall for %s." % spell.display_name)
		Spell.TargetMode.HAND_LETTER:
			hud.flash("Choose a hand letter for %s." % spell.display_name)
	hud.refresh()


func _cast_spell(spell: Spell, target: Variant) -> void:
	var cost := player_manager.spell_cost(spell)
	if not player_manager.spend(cost):
		return
	popup_energy(-cost)
	player_manager.note_spell_used(spell)
	for effect in spell.effects:
		if effect:
			effect.apply(self, target)
	play_spell_burst(Vector2.ZERO, Color(0.7, 0.85, 1.0))
	targeting_spell = null
	turn_start_energy = player_manager.energy
	_check_win()
	hud.refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E and phase == Phase.PLAYER:
			_on_end_turn()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_R and phase == Phase.GAME_OVER:
			_restart_run()
			get_viewport().set_input_as_handled()
			return
	if phase != Phase.PLAYER:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if hud.is_over_ui():
		return
	var cell := grid.cell_at_mouse()
	if cell.x < -9000:
		return
	_on_cell_clicked(cell)
	get_viewport().set_input_as_handled()


func _on_cell_clicked(cell: Vector2i) -> void:
	if targeting_spell:
		_try_spell_target(cell)
		return
	if word_locked:
		return
	if board.has_pending(cell):
		var letter := board.pickup_pending(cell)
		player_manager.return_letter(letter)
		_sync_energy_from_board()
		hud.refresh()
		return
	if player_manager.selected == null:
		return
	if not grid.is_buildable(cell):
		hud.flash("Cannot build there.")
		return
	if board.has_wall(cell):
		hud.flash("That tile already has a wall.")
		return
	var placed := player_manager.take_selected()
	board.place_pending(cell, placed)
	if placed.is_blank and not placed.chosen:
		hud.show_blank_picker(placed)
	_sync_energy_from_board()
	hud.refresh()


func _try_spell_target(cell: Vector2i) -> void:
	var spell := targeting_spell
	if spell.target_mode == Spell.TargetMode.ENEMY:
		var enemy := enemy_manager.enemy_at(cell)
		if enemy == null:
			hud.flash("Choose an enemy.")
			return
		_cast_spell(spell, enemy)
		return
	if spell.target_mode == Spell.TargetMode.WALL:
		var wall := board.get_wall(cell)
		if wall == null:
			hud.flash("Choose a letter wall.")
			return
		_cast_spell(spell, wall)


func _on_blank_chosen(letter: Letter, glyph: String) -> void:
	if letter == null:
		return
	letter.char = glyph
	letter.chosen = true
	board.revalidate()
	_sync_energy_from_board()
	hud.refresh()


func _cancel() -> void:
	if targeting_spell:
		targeting_spell = null
		hud.refresh()
		return
	if phase == Phase.PLAYER and not word_locked:
		player_manager.selected = null
		hud.refresh()


func _sync_energy_from_board() -> void:
	if word_locked:
		return
	if board.current_result.valid:
		player_manager.set_energy(turn_start_energy + board.current_result.energy)
	else:
		player_manager.set_energy(turn_start_energy)


func add_energy(amount: int, _reason: String = "") -> void:
	var gained := player_manager.add_energy(amount)
	if gained != 0:
		popup_energy(gained)


func popup_energy(delta: int) -> void:
	var text := ("+%d" % delta) if delta > 0 else str(delta)
	var color := Color(0.55, 0.9, 1.0) if delta > 0 else Color(1.0, 0.45, 0.35)
	if hud:
		hud.popup_energy(text, color)


func popup_at_tile(tile: Node2D, text: String, color: Color) -> void:
	if vfx and tile:
		vfx.popup(tile.position, text, color)


func popup_at_cell(cell: Vector2i, text: String, color: Color) -> void:
	if vfx:
		vfx.popup(board.cell_to_local(cell), text, color)


func play_spell_burst(local_pos: Vector2, color: Color) -> void:
	if vfx == null:
		return
	if local_pos == Vector2.ZERO:
		local_pos = Vector2(grid.cols, grid.rows) * 24.0
	vfx.burst(local_pos, color)


func buff_adjacent_walls(tile: Node2D, amount: int) -> void:
	if tile == null or not ("cell" in tile):
		return
	for other in board.adjacent_walls(tile.cell):
		other.heal(amount)
		popup_at_tile(other, "+%d" % amount, Color(1.0, 0.85, 0.3))


func kill_random_weak_enemy(max_health: int) -> void:
	var candidates: Array[Enemy] = []
	for enemy in enemy_manager.living():
		if enemy.health <= max_health:
			candidates.append(enemy)
	if candidates.is_empty():
		return
	var target: Enemy = candidates.pick_random()
	popup_at_cell(target.cell, "slain", Color(1.0, 0.7, 0.2))
	target.take_damage(99, "letter")


func letter_shoot_farthest(tile: Node2D, damage: int) -> void:
	var best: Enemy = null
	var best_dist := -1
	var origin: Vector2i = tile.cell
	for enemy in enemy_manager.living():
		var dist := absi(enemy.cell.x - origin.x) + absi(enemy.cell.y - origin.y)
		if dist > best_dist:
			best_dist = dist
			best = enemy
	if best == null:
		return
	best.take_damage(damage, "letter")
	popup_at_cell(best.cell, "-%d" % damage, Color(1.0, 0.5, 0.2))


func discard_and_redraw(target: Variant) -> void:
	var letter := target as Letter
	if letter == null:
		return
	player_manager.discard_from_hand(letter)
	player_manager.refill_hand()


func storm_damage(amount: int, hits: int) -> void:
	var pool := enemy_manager.living()
	if pool.is_empty():
		return
	for _i in hits:
		pool = enemy_manager.living()
		if pool.is_empty():
			return
		var enemy: Enemy = pool.pick_random()
		enemy.take_damage(amount, "spell")
		popup_at_cell(enemy.cell, "-%d" % amount, Color(0.7, 0.8, 1.0))
	play_spell_burst(Vector2.ZERO, Color(0.5, 0.7, 1.0))


func freeze_all_enemies() -> void:
	enemy_manager.freeze_all()
	hud.flash("Enemies freeze until your next turn.")


func _on_wall_destroyed(tile: LetterTile) -> void:
	if tile and tile.letter:
		player_manager.send_to_discard(tile.letter)
		popup_at_cell(tile.cell, "-HP", Color(1.0, 0.4, 0.3))


func _on_enemy_damaged(enemy: Enemy) -> void:
	if enemy:
		popup_at_cell(enemy.cell, "-HP", Color(1.0, 0.45, 0.35))


func _on_enemy_killed(enemy: Enemy) -> void:
	if enemy == null:
		return
	if enemy.last_hit == "crush":
		gold_wall += 1
		gold_crush += 2
		player_state.gold += 3
		popup_at_cell(enemy.cell, "+3g", Color(1.0, 0.85, 0.3))
	elif enemy.last_hit == "wall":
		gold_wall += 1
		player_state.gold += 1
		popup_at_cell(enemy.cell, "+1g", Color(1.0, 0.85, 0.3))


func _on_village_reached() -> void:
	_lose("An enemy reached the village.")


func _on_enemies_changed() -> void:
	if phase != Phase.PLAYER and phase != Phase.TALLY and phase != Phase.SHOP:
		_check_win()
	# Hook newly spawned enemies for VFX/gold.
	for enemy in enemy_manager.enemies:
		if is_instance_valid(enemy) and not enemy.died.is_connected(_on_enemy_killed):
			enemy.died.connect(_on_enemy_killed)
			enemy.damaged.connect(_on_enemy_damaged)


func _check_win() -> void:
	if phase == Phase.GAME_OVER or phase == Phase.TALLY or phase == Phase.SHOP:
		return
	if enemy_manager.has_living_enemies():
		return
	if enemy_manager.has_remaining_waves():
		return
	if enemy_manager.next_wave_index == 0:
		return
	_win()


func _win() -> void:
	phase = Phase.TALLY
	status_text = "Level cleared."
	_collect_letters_into_state()
	player_state.save_to_disk()
	hud.show_tally(gold_wall, gold_crush, player_state.gold)
	hud.refresh()


func _lose(message: String) -> void:
	phase = Phase.GAME_OVER
	status_text = message
	hud.show_game_over(false, message)
	hud.refresh()


func _collect_letters_into_state() -> void:
	if not board.pending.is_empty():
		board.clear_pending_to_hand(player_manager)
	for cell in board.walls.keys():
		var tile: LetterTile = board.walls[cell]
		if tile and tile.letter:
			player_manager.bag.append(tile.letter)
		if tile:
			tile.queue_free()
	board.walls.clear()
	player_manager.capture_state(player_state)


func _open_shop() -> void:
	phase = Phase.SHOP
	hud.show_shop(player_state, shop_catalog)


func _start_next_level() -> void:
	if player_state.level_index >= levels.size() - 1:
		phase = Phase.GAME_OVER
		hud.show_game_over(true, "All villages stand. You cleared every raid.")
		return
	player_state.level_index += 1
	player_state.save_to_disk()
	hud.hide_overlays()
	_load_level_index(player_state.level_index)
	_on_end_turn()


func _buy_offer(offer: ShopOffer) -> void:
	if offer == null:
		return
	if player_state.gold < offer.cost:
		hud.flash("Not enough gold.")
		return
	if offer.unique and player_state.has_purchased(offer.id):
		hud.flash("Already owned.")
		return
	match offer.kind:
		ShopOffer.Kind.SPELL:
			if offer.spell == null:
				return
			if player_state.spells.size() >= 5:
				hud.flash("Spellbook is full (5).")
				return
			for owned in player_state.spells:
				if owned == offer.spell or owned.display_name == offer.spell.display_name:
					hud.flash("You already have that spell.")
					return
			player_state.spells.append(offer.spell)
			player_manager.spells = player_state.spells.duplicate()
		ShopOffer.Kind.LETTER:
			if offer.letter_blueprint == null:
				return
			var bought := offer.letter_blueprint.duplicate(true)
			player_state.owned_letters.append(bought)
			player_manager.bag.append(Letter.from_blueprint(bought))
		ShopOffer.Kind.ENCHANTMENT:
			if offer.enchantment == null:
				return
			pending_shop_enchantment = offer.enchantment
			hud.show_enchant_picker(player_manager.all_letters())
			return
		ShopOffer.Kind.UPGRADE:
			player_state.max_energy += offer.max_energy_bonus
			player_state.vowel_hand_size += offer.vowel_size_bonus
			player_state.consonant_hand_size += offer.consonant_size_bonus
			player_manager.max_energy = player_state.max_energy
			player_manager.vowel_hand_size = player_state.vowel_hand_size
			player_manager.consonant_hand_size = player_state.consonant_hand_size
	player_state.gold -= offer.cost
	player_state.mark_purchased(offer.id)
	player_manager.capture_state(player_state)
	player_state.save_to_disk()
	hud.show_shop(player_state, shop_catalog)
	hud.flash("Bought %s." % offer.display_name)


func _on_blank_cancelled(letter: Letter) -> void:
	if letter == null:
		return
	for cell in board.pending.keys():
		if board.pending[cell] == letter:
			board.pickup_pending(cell)
			player_manager.return_letter(letter)
			_sync_energy_from_board()
			hud.refresh()
			return


func _on_enchant_cancelled() -> void:
	pending_shop_enchantment = null
	hud.show_shop(player_state, shop_catalog)


func _apply_enchantment_to_letter(letter: Letter) -> void:
	if pending_shop_enchantment == null or letter == null:
		return
	var offer_cost := 10
	if shop_catalog:
		for offer in shop_catalog.offers:
			if offer.kind == ShopOffer.Kind.ENCHANTMENT and offer.enchantment == pending_shop_enchantment:
				offer_cost = offer.cost
				break
	if player_state.gold < offer_cost:
		hud.flash("Not enough gold.")
		pending_shop_enchantment = null
		return
	letter.place_effects.append(pending_shop_enchantment)
	player_state.gold -= offer_cost
	pending_shop_enchantment = null
	player_manager.capture_state(player_state)
	player_state.save_to_disk()
	hud.show_shop(player_state, shop_catalog)
	hud.flash("Letter enchanted.")


func _restart_run() -> void:
	player_state = PlayerState.from_player(player)
	player_state.save_to_disk()
	hud.hide_overlays()
	_load_level_index(0)
	_on_end_turn()


func _cell_from_screen(screen_pos: Vector2) -> Vector2i:
	var local := grid.get_global_transform_with_canvas().affine_inverse() * screen_pos
	var cell := grid.local_to_map(local)
	if not grid.is_in_bounds(cell):
		return Vector2i(-9999, -9999)
	return cell


func _layout_world() -> void:
	if grid == null or grid.cols == 0:
		return
	var tile := 48
	if grid.tile_set:
		tile = grid.tile_set.tile_size.x
	var grid_px := Vector2(grid.cols * tile, grid.rows * tile)
	var view := get_viewport().get_visible_rect().size
	var left := _layout_margins.position.x
	var top := _layout_margins.position.y
	var right := _layout_margins.size.x
	var bottom := _layout_margins.size.y
	var area := Vector2(view.x - left - right, view.y - top - bottom)
	var world_scale := minf(area.x / grid_px.x, area.y / grid_px.y) * 0.92
	world.scale = Vector2(world_scale, world_scale)
	var scaled := grid_px * world_scale
	world.position = Vector2(
		left + (area.x - scaled.x) * 0.5,
		top + (area.y - scaled.y) * 0.5
	)


func _process(_delta: float) -> void:
	if hud == null or grid == null:
		return
	if hud.is_over_ui() or phase == Phase.GAME_OVER or phase == Phase.TALLY or phase == Phase.SHOP:
		hud.hide_tooltip()
		board.clear_highlight()
		return
	var cell := grid.cell_at_mouse()
	if cell.x < -9000:
		hud.hide_tooltip()
		board.clear_highlight()
		return
	var text := _tooltip_for(cell)
	if text.is_empty():
		hud.hide_tooltip()
		board.clear_highlight()
	else:
		hud.show_tooltip(text, get_viewport().get_mouse_position())
		board.highlight_from(cell)
	if phase == Phase.PLAYER and not word_locked and player_manager.selected and grid.is_buildable(cell) and not board.has_wall(cell) and not board.has_pending(cell):
		board.preview_cell = cell
		board.preview_char = player_manager.selected.display_char()
		board.queue_redraw()
	else:
		board.preview_cell = Board.INVALID_CELL


func _tooltip_for(cell: Vector2i) -> String:
	if grid.is_village(cell):
		var village: Building = board.villages.get(cell)
		return village.get_tooltip() if village else "Village"
	var enemy_text := enemy_manager.tooltip_at(cell)
	if board.has_wall(cell) or board.has_pending(cell):
		var tile: LetterTile = board.walls.get(cell)
		if tile == null:
			tile = board.pending_tiles.get(cell)
		var wall_text := tile.get_tooltip() if tile else "Letter"
		var words := board.words_through(cell)
		if not words.is_empty():
			wall_text += "\nWords: %s" % ", ".join(words)
		if enemy_text.is_empty():
			return wall_text
		return wall_text + "\n\n" + enemy_text
	if not enemy_text.is_empty():
		return enemy_text
	if grid.is_enemy_land(cell):
		return "Enemy land\nRaiders spawn here. You cannot build on this tile."
	return ""
