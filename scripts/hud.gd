class_name HUD
extends CanvasLayer

signal end_turn_pressed
signal letter_pressed(letter: Letter)
signal letter_dropped(letter: Letter, screen_pos: Vector2)
signal spell_pressed(spell: Spell)
signal restart_pressed
signal tally_ok_pressed
signal next_level_pressed
signal shop_buy_pressed(offer: ShopOffer)
signal blank_chosen(letter: Letter, glyph: String)
signal blank_cancelled(letter: Letter)
signal enchant_letter_chosen(letter: Letter)
signal enchant_cancelled

var game: GameManager
var _root: Control
var _status: Label
var _turn_label: Label
var _phase_label: Label
var _gold_label: Label
var _energy_label: Label
var _energy_bar: ProgressBar
var _vowel_row: HBoxContainer
var _consonant_row: HBoxContainer
var _spell_list: VBoxContainer
var _bag_count: Label
var _discard_count: Label
var _end_turn: Button
var _tooltip: PanelContainer
var _tooltip_label: Label
var _popup: PanelContainer
var _popup_label: Label
var _overlay: ColorRect
var _overlay_box: VBoxContainer
var _overlay_title: Label
var _overlay_body: Label
var _overlay_buttons: HBoxContainer
var _energy_popup: Label
var _drag_ghost: Label
var _vowel_buttons: Array[Button] = []
var _consonant_buttons: Array[Button] = []
var _spell_buttons: Array[Button] = []
var _dragging: Letter = null
var _blank_letter: Letter = null


func setup(p_game: GameManager) -> void:
	game = p_game
	_build()
	refresh()


func refresh() -> void:
	if game == null or _turn_label == null:
		return
	var pm := game.player_manager
	_turn_label.text = "Turn %d" % game.turn
	_gold_label.text = "Gold %d" % game.player_state.gold
	_energy_label.text = "Energy %d / %d" % [pm.energy, pm.max_energy]
	_energy_bar.max_value = pm.max_energy
	_energy_bar.value = pm.energy
	if game.phase == GameManager.Phase.PLAYER:
		if game.targeting_spell:
			_status.text = "Target: %s" % game.targeting_spell.display_name
		else:
			_status.text = game.board.current_result.message
	else:
		_status.text = game.status_text
	_end_turn.disabled = game.phase != GameManager.Phase.PLAYER
	_rebuild_hand_if_needed()
	_refresh_hand(_vowel_buttons, pm.vowel_hand)
	_refresh_hand(_consonant_buttons, pm.consonant_hand)
	_bag_count.text = "Bag  %d" % pm.bag.size()
	_discard_count.text = "Discard  %d" % pm.discard_pile.size()
	_refresh_spells()


func set_phase(text: String) -> void:
	if _phase_label:
		_phase_label.text = text


func flash(text: String) -> void:
	_status.text = text


func popup_energy(text: String, color: Color) -> void:
	if _energy_popup == null:
		return
	_energy_popup.text = text
	_energy_popup.modulate = color
	_energy_popup.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_energy_popup, "modulate:a", 0.0, 0.8)


func show_tooltip(text: String, screen_pos: Vector2) -> void:
	if text.is_empty():
		_tooltip.visible = false
		return
	_tooltip_label.text = text
	_tooltip.visible = true
	_tooltip.reset_size()
	var view := get_viewport().get_visible_rect().size
	var pos := screen_pos + Vector2(18, 18)
	var size := _tooltip.get_combined_minimum_size()
	pos.x = minf(pos.x, view.x - size.x - 12)
	pos.y = minf(pos.y, view.y - size.y - 12)
	_tooltip.position = pos


func hide_tooltip() -> void:
	_tooltip.visible = false


func show_pile(title: String, body: String) -> void:
	_popup_label.text = "%s\n\n%s" % [title, body]
	_popup.visible = true


func hide_popup() -> void:
	_popup.visible = false


func hide_overlays() -> void:
	_overlay.visible = false
	_popup.visible = false
	_clear_overlay_buttons()


func show_game_over(won: bool, message: String) -> void:
	_prepare_overlay()
	_overlay_title.text = "Victory" if won else "Defeat"
	_overlay_body.text = message
	_add_overlay_button("Restart run", func() -> void: restart_pressed.emit())


func show_tally(wall_gold: int, crush_bonus: int, purse: int) -> void:
	_prepare_overlay()
	_overlay_title.text = "Raid complete"
	_overlay_body.text = "Wall kills: +%d gold\nCrush bonus: +%d gold\nTotal earned: +%d\n\nPurse: %d gold" % [
		wall_gold, crush_bonus, wall_gold + crush_bonus, purse
	]
	_add_overlay_button("OK", func() -> void: tally_ok_pressed.emit())


func show_shop(state: PlayerState, catalog: ShopCatalog) -> void:
	_prepare_overlay()
	_overlay_title.text = "Shop  —  %d gold" % state.gold
	_overlay_body.text = "Everything you buy is equipped immediately."
	if catalog:
		for offer in catalog.offers:
			if offer == null:
				continue
			var owned := offer.unique and state.has_purchased(offer.id)
			var label := "%s  (%dg)%s\n%s" % [
				offer.display_name,
				offer.cost,
				"  [owned]" if owned else "",
				offer.description
			]
			var btn := _add_overlay_button(label, func(picked := offer) -> void: shop_buy_pressed.emit(picked))
			btn.disabled = owned or state.gold < offer.cost
			btn.custom_minimum_size = Vector2(420, 52)
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		_overlay_body.text = "The shop has nothing in stock. Advance when you are ready."
	_add_overlay_button("Next level", func() -> void: next_level_pressed.emit())


func show_blank_picker(letter: Letter) -> void:
	_blank_letter = letter
	_prepare_overlay()
	_overlay_title.text = "Choose a letter"
	_overlay_body.text = "This blank can be any letter."
	var grid := GridContainer.new()
	grid.columns = 13
	_overlay_box.add_child(grid)
	for code in range(65, 91):
		var glyph := String.chr(code)
		var btn := _button(glyph)
		btn.custom_minimum_size = Vector2(36, 36)
		btn.pressed.connect(func(picked := glyph) -> void:
			hide_overlays()
			blank_chosen.emit(letter, picked)
		)
		grid.add_child(btn)
	_add_overlay_button("Cancel", func() -> void:
		hide_overlays()
		blank_cancelled.emit(letter)
	)


func show_enchant_picker(letters: Array[Letter]) -> void:
	_prepare_overlay()
	_overlay_title.text = "Enchant a letter"
	_overlay_body.text = "The power fires when that letter is placed."
	for letter in letters:
		var extra := letter.effect_text()
		var label := letter.display_char()
		if extra != "":
			label = "%s  —  %s" % [label, extra.replace("\n", " / ")]
		var btn := _add_overlay_button(label, func(picked := letter) -> void:
			hide_overlays()
			enchant_letter_chosen.emit(picked)
		)
		btn.custom_minimum_size = Vector2(420, 40)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_overlay_button("Cancel", func() -> void:
		hide_overlays()
		enchant_cancelled.emit()
	)


func is_over_ui() -> bool:
	if _popup.visible or _overlay.visible:
		return true
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and _dragging == null


func _build() -> void:
	_root = $Control
	#_root = Control.new()
	#_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	#_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#add_child(_root)

	#var top := _panel()
	#top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#top.anchor_left = 0.18
	#top.anchor_right = 0.98
	#top.anchor_top = 0.0
	#top.anchor_bottom = 0.0
	#top.offset_top = 8
	#top.offset_bottom = 92
	#_root.add_child(top)
	#var top_box := VBoxContainer.new()
	#top.add_child(top_box)
	#var top_row := HBoxContainer.new()
	#top_box.add_child(top_row)
	_turn_label = $Control/Top/TopBox/TopRow/Turn
	_phase_label = $Control/Top/TopBox/TopRow/Phase
	_gold_label = $Control/Top/TopBox/TopRow/Gold
	#_turn_label = _label("Turn 1", 20)
	#_phase_label = _label("Player turn", 16)
	#_gold_label = _label("Gold 0", 18)
	#top_row.add_child(_turn_label)
	#top_row.add_child(_phase_label)
	#var spacer := Control.new()
	#spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#top_row.add_child(spacer)
	#top_row.add_child(_gold_label)
	#var energy_row := HBoxContainer.new()
	#energy_row.add_theme_constant_override("separation", 8)
	#top_box.add_child(energy_row)
	_energy_label = $Control/Left/LeftBox/EnergyLabel
	_energy_bar = $Control/Left/LeftBox/EnergyBar
	_energy_label = _label("Energy 0 / 8", 14)
	#energy_row.add_child(_energy_label)
	#_energy_bar = ProgressBar.new()
	#_energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#_energy_bar.custom_minimum_size = Vector2(180, 18)
	_energy_bar.show_percentage = false
	_energy_bar.max_value = 8
	#energy_row.add_child(_energy_bar)
	_energy_popup = _label("", 16)
	_energy_popup.modulate.a = 0.0
	$Control/Left/LeftBox.add_child(_energy_popup)
	#energy_row.add_child(_energy_popup)
	#_status = _label("Place a word.", 15)
	_status = $Control/Top/TopBox/Status
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#top_box.add_child(_status)

	#var left := _panel()
	#left.anchor_left = 0.0
	#left.anchor_right = 0.0
	#left.anchor_top = 0.0
	#left.anchor_bottom = 1.0
	#left.offset_left = 12
	#left.offset_right = 214
	#left.offset_top = 8
	#left.offset_bottom = -176
	#_root.add_child(left)
	#var left_box := VBoxContainer.new()
	#left_box.add_theme_constant_override("separation", 8)
	#left.add_child(left_box)
	#left_box.add_child(_label("Spellbook", 18))
	#var spell_scroll := ScrollContainer.new()
	#spell_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#left_box.add_child(spell_scroll)
	_spell_list = $Control/Left/LeftBox/SpellScroll/SpellList
	#_spell_list = VBoxContainer.new()
	#_spell_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#_spell_list.add_theme_constant_override("separation", 8)
	#spell_scroll.add_child(_spell_list)

	#var bottom := _panel()
	#bottom.anchor_left = 0.0
	#bottom.anchor_right = 1.0
	#bottom.anchor_top = 1.0
	#bottom.anchor_bottom = 1.0
	#bottom.offset_left = 12
	#bottom.offset_right = -12
	#bottom.offset_top = -164
	#bottom.offset_bottom = -10
	#_root.add_child(bottom)
	#var bottom_row := HBoxContainer.new()
	#bottom_row.add_theme_constant_override("separation", 16)
	#bottom.add_child(bottom_row)
#
	#var bag_box := VBoxContainer.new()
	#bottom_row.add_child(bag_box)
	_bag_count = $Control/BottomLeft/BagBox/HBoxContainer2/Bag
	#_bag_count = _label("Bag  0", 16)
	#bag_box.add_child(_bag_count)
	#var bag_btn := _button("Show letters")
	var bag_btn = $Control/BottomLeft/BagBox/HBoxContainer2/ShowBag
	bag_btn.pressed.connect(func() -> void:
		show_pile("Letter bag", game.player_manager.describe_pile(game.player_manager.bag))
	)
	#bag_box.add_child(bag_btn)

	#var hands := HBoxContainer.new()
	#hands.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#hands.add_theme_constant_override("separation", 28)
	#bottom_row.add_child(hands)
	#var vowel_wrap := VBoxContainer.new()
	#vowel_wrap.add_child(_label("Vowels", 14))
	
	#_vowel_row = HBoxContainer.new()
	_vowel_row = $Control/Bottom/Hands/Vowels/VowelRow
	#_vowel_row.add_theme_constant_override("separation", 8)
	#vowel_wrap.add_child(_vowel_row)
	#hands.add_child(vowel_wrap)
	#var cons_wrap := VBoxContainer.new()
	#cons_wrap.add_child(_label("Consonants", 14)
	_consonant_row = $Control/Bottom/Hands/Consonants/ConsonantRow
	#_consonant_row = HBoxContainer.new()
	#_consonant_row.add_theme_constant_override("separation", 8)
	#cons_wrap.add_child(_consonant_row)
	#hands.add_child(cons_wrap)

	#var right_box := VBoxContainer.new()
	#right_box.add_theme_constant_override("separation", 8)
	#bottom_row.add_child(right_box)
	_discard_count = $Control/BottomLeft/BagBox/HBoxContainer/Discard
	#_discard_count = _label("Discard  0", 16)
	#right_box.add_child(_discard_count)
	var discard_btn = $Control/BottomLeft/BagBox/HBoxContainer/ShowDiscard
	#var discard_btn := _button("Show discard")
	discard_btn.pressed.connect(func() -> void:
		show_pile("Discard", game.player_manager.describe_pile(game.player_manager.discard_pile))
	)
	#right_box.add_child(discard_btn)
	_end_turn = $Control/BottomRight/VBoxContainer/EndTurn
	#_end_turn = _button("End Turn  (E)")
	_end_turn.pressed.connect(func() -> void: end_turn_pressed.emit())
	#right_box.add_child(_end_turn)

	_tooltip = _panel()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 20
	_root.add_child(_tooltip)
	_tooltip_label = _label("", 14)
	_tooltip.add_child(_tooltip_label)

	_popup = _panel()
	_popup.visible = false
	_popup.anchor_left = 0.3
	_popup.anchor_right = 0.7
	_popup.anchor_top = 0.28
	_popup.anchor_bottom = 0.7
	_popup.z_index = 30
	_root.add_child(_popup)
	var popup_box := VBoxContainer.new()
	_popup.add_child(popup_box)
	_popup_label = _label("", 16)
	_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_box.add_child(_popup_label)
	var close_btn := _button("Close")
	close_btn.pressed.connect(hide_popup)
	popup_box.add_child(close_btn)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.05, 0.04, 0.03, 0.82)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_overlay.z_index = 40
	_root.add_child(_overlay)
	var overlay_center := CenterContainer.new()
	overlay_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(overlay_center)
	var overlay_panel := _panel()
	overlay_panel.custom_minimum_size = Vector2(520, 280)
	overlay_center.add_child(overlay_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 420)
	overlay_panel.add_child(scroll)
	_overlay_box = VBoxContainer.new()
	_overlay_box.add_theme_constant_override("separation", 10)
	_overlay_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_overlay_box)
	_overlay_title = _label("", 26)
	_overlay_body = _label("", 16)
	_overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay_box.add_child(_overlay_title)
	_overlay_box.add_child(_overlay_body)
	_overlay_buttons = HBoxContainer.new()

	_drag_ghost = _label("", 22)
	_drag_ghost.visible = false
	_drag_ghost.z_index = 50
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_drag_ghost)
	_root.gui_input.connect(_on_root_gui)

	_build_hand_slots()


func _on_root_gui(_event: InputEvent) -> void:
	pass


func _process(_delta: float) -> void:
	if _drag_ghost == null:
		return
	if _dragging == null:
		_drag_ghost.visible = false
		return
	_drag_ghost.visible = true
	_drag_ghost.text = _dragging.display_char()
	_drag_ghost.position = _root.get_local_mouse_position() + Vector2(12, 12)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) == false:
		var letter := _dragging
		_dragging = null
		_drag_ghost.visible = false
		letter_dropped.emit(letter, get_viewport().get_mouse_position())


func _prepare_overlay() -> void:
	_overlay.visible = true
	_clear_overlay_buttons()
	for child in _overlay_box.get_children():
		if child == _overlay_title or child == _overlay_body:
			continue
		_overlay_box.remove_child(child)
		child.queue_free()
	if _overlay_title.get_parent() != _overlay_box:
		_overlay_box.add_child(_overlay_title)
	if _overlay_body.get_parent() != _overlay_box:
		_overlay_box.add_child(_overlay_body)
	_overlay_box.move_child(_overlay_title, 0)
	_overlay_box.move_child(_overlay_body, 1)


func _clear_overlay_buttons() -> void:
	pass


func _add_overlay_button(text: String, callback: Callable) -> Button:
	var btn := _button(text)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(callback)
	_overlay_box.add_child(btn)
	return btn


func _rebuild_hand_if_needed() -> void:
	var vowels := game.player_manager.vowel_hand_size
	var cons := game.player_manager.consonant_hand_size
	if _vowel_buttons.size() != vowels or _consonant_buttons.size() != cons:
		_build_hand_slots()


func _build_hand_slots() -> void:
	_vowel_buttons.clear()
	_consonant_buttons.clear()
	for child in _vowel_row.get_children():
		child.queue_free()
	for child in _consonant_row.get_children():
		child.queue_free()
	var vowels := game.player_manager.vowel_hand_size if game else 3
	var cons := game.player_manager.consonant_hand_size if game else 3
	for i in vowels:
		var btn := _tile_button()
		btn.gui_input.connect(_on_vowel_gui.bind(i))
		btn.pressed.connect(_on_vowel_slot.bind(i))
		_vowel_row.add_child(btn)
		_vowel_buttons.append(btn)
	for i in cons:
		var btn := _tile_button()
		btn.gui_input.connect(_on_consonant_gui.bind(i))
		btn.pressed.connect(_on_consonant_slot.bind(i))
		_consonant_row.add_child(btn)
		_consonant_buttons.append(btn)


func _refresh_hand(buttons: Array[Button], letters: Array[Letter]) -> void:
	for i in buttons.size():
		var btn := buttons[i]
		if i < letters.size():
			var letter := letters[i]
			btn.text = letter.display_char()
			btn.disabled = game.phase != GameManager.Phase.PLAYER or game.word_locked
			btn.modulate = Color(1.15, 1.1, 0.75) if letter == game.player_manager.selected else Color.WHITE
		else:
			btn.text = ""
			btn.disabled = true
			btn.modulate = Color(1, 1, 1, 0.45)


func _on_vowel_gui(event: InputEvent, index: int) -> void:
	_handle_drag_start(event, true, index)


func _on_consonant_gui(event: InputEvent, index: int) -> void:
	_handle_drag_start(event, false, index)


func _handle_drag_start(event: InputEvent, is_vowel: bool, index: int) -> void:
	if game.phase != GameManager.Phase.PLAYER or game.word_locked:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var letters := game.player_manager.vowel_hand if is_vowel else game.player_manager.consonant_hand
	if index < letters.size():
		_dragging = letters[index]


func _on_vowel_slot(index: int) -> void:
	if index < game.player_manager.vowel_hand.size():
		letter_pressed.emit(game.player_manager.vowel_hand[index])


func _on_consonant_slot(index: int) -> void:
	if index < game.player_manager.consonant_hand.size():
		letter_pressed.emit(game.player_manager.consonant_hand[index])


func _clear_button_presses(btn: Button) -> void:
	for conn in btn.pressed.get_connections():
		btn.pressed.disconnect(conn.callable)


func _refresh_spells() -> void:
	var spells := game.player_manager.spells
	while _spell_buttons.size() < spells.size():
		var btn := _button("Spell")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 64)
		_spell_list.add_child(btn)
		_spell_buttons.append(btn)
	for i in _spell_buttons.size():
		var btn := _spell_buttons[i]
		if i >= spells.size():
			btn.visible = false
			continue
		var spell: Spell = spells[i]
		btn.visible = true
		var cost := game.player_manager.spell_cost(spell)
		btn.text = "%s  (%d)\n%s" % [spell.display_name, cost, spell.description]
		btn.disabled = (
			game.phase != GameManager.Phase.PLAYER
			or not game.player_manager.can_afford(spell)
		)
		if btn.get_meta("spell_index", -1) != i:
			_clear_button_presses(btn)
			btn.set_meta("spell_index", i)
			btn.pressed.connect(_on_spell_index.bind(i))


func _on_spell_index(index: int) -> void:
	if index < game.player_manager.spells.size():
		spell_pressed.emit(game.player_manager.spells[index])


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = GameColors.PANEL
	style.border_color = GameColors.PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", GameColors.INK)
	return label


func _button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 32)
	return btn


func _tile_button() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(56, 56)
	btn.add_theme_font_size_override("font_size", 22)
	return btn
