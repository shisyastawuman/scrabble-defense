class_name LetterTile
extends Node2D

signal damaged(tile: LetterTile)
signal destroyed(tile: LetterTile)

var letter: Letter
var cell: Vector2i
var pending: bool = false
var tile_size: int = 48
var _dying: bool = false


func setup(p_letter: Letter, p_cell: Vector2i, p_pending: bool, p_tile_size: int) -> void:
	letter = p_letter
	cell = p_cell
	pending = p_pending
	tile_size = p_tile_size
	z_index = 3 if pending else 1
	scale = Vector2.ONE
	_dying = false
	queue_redraw()


func heal(amount: int) -> void:
	if pending or letter == null or _dying:
		return
	letter.health += amount
	queue_redraw()


func take_damage(amount: int) -> void:
	if pending or letter == null or _dying:
		return
	letter.health -= amount
	damaged.emit(self)
	queue_redraw()
	if letter.health <= 0:
		_dying = true
		_play_destroy()


func is_blocking() -> bool:
	return not _dying and letter != null and letter.health > 0


func get_tooltip() -> String:
	if letter == null:
		return "Wall"
	var kind := "Pending letter" if pending else "Letter wall"
	var text := "%s\n%s\nHealth: %d" % [kind, letter.display_char(), letter.health]
	var extra := letter.effect_text()
	if not extra.is_empty():
		text += "\n" + extra
	return text


func _play_destroy() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.18)
	tween.tween_callback(func() -> void:
		destroyed.emit(self)
	)


func _draw() -> void:
	if letter == null:
		return
	var half := tile_size * 0.5
	var rect := Rect2(Vector2(-half + 3, -half + 3), Vector2(tile_size - 6, tile_size - 6))
	var fill := GameColors.wall_fill(letter.health)
	if pending:
		fill.a = 0.72
	var light := fill.lightened(0.22)
	var dark := fill.darkened(0.38)
	draw_rect(rect, fill, true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 7)), light, true)
	draw_rect(rect, dark, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := 22
	var text := letter.display_char()
	draw_string(
		font,
		Vector2(-half + 4, 8),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		tile_size - 8,
		font_size,
		GameColors.INK_DARK
	)
	if not pending:
		_draw_pips(letter.health, Vector2(0, half - 9))


func _draw_pips(health: int, origin: Vector2) -> void:
	var pips := mini(maxi(health, 0), 8)
	var pip_w := 5.0
	var gap := 2.0
	var total := pips * pip_w + maxi(pips - 1, 0) * gap
	var x := origin.x - total * 0.5
	for i in pips:
		draw_rect(Rect2(Vector2(x, origin.y), Vector2(pip_w, 5)), GameColors.INK_DARK, true)
		x += pip_w + gap
