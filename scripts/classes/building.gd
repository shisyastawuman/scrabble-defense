class_name Building
extends Node2D

var cell: Vector2i
var tile_size: int = 48
var sprite: Sprite2D


func _ready() -> void:
	sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.visible = false
	queue_redraw()


func setup(p_cell: Vector2i, p_tile_size: int) -> void:
	cell = p_cell
	tile_size = p_tile_size
	z_index = 0
	queue_redraw()


func get_tooltip() -> String:
	return "Village\nIf an enemy reaches this tile, you lose."


func _draw() -> void:
	var half := tile_size * 0.5
	var body := Rect2(Vector2(-12, -4), Vector2(24, 20))
	var fill := GameColors.village_fill()
	draw_colored_polygon(
		PackedVector2Array([Vector2(0, -half + 8), Vector2(16, -2), Vector2(-16, -2)]),
		fill.lightened(0.15)
	)
	draw_rect(body, fill, true)
	draw_rect(body, fill.darkened(0.4), false, 2.0)
	draw_rect(Rect2(Vector2(-5, 4), Vector2(6, 8)), Color(0.95, 0.86, 0.55), true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-20, -half + 6), "V", HORIZONTAL_ALIGNMENT_CENTER, 40, 12, GameColors.INK)
