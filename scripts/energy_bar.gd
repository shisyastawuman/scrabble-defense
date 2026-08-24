class_name EnergyBar
extends HBoxContainer

@export var filled_texture: Texture2D
@export var empty_texture: Texture2D
@export var increase_texture: Texture2D
@export var decrease_texture: Texture2D

var _max_energy: int = 0
var _energy: int = 0
var _potential_delta: int = 0
var _energy_pips: Array[TextureRect] = []
var _pip_min_size: Vector2 = Vector2(10, 30)
var _pip_max_size: Vector2 = Vector2(100, 30)


func _ready() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_energy_pips.clear()


func set_energy(new_energy: int) -> void:
	_energy = clampi(new_energy, 0, _max_energy)
	_refresh_pip_textures()


func set_maximum_energy(new_max_energy: int) -> void:
	new_max_energy = maxi(new_max_energy, 0)
	while _energy_pips.size() < new_max_energy:
		_create_pip()
	while _energy_pips.size() > new_max_energy:
		var pip: TextureRect = _energy_pips.pop_back()
		pip.queue_free()
	_max_energy = new_max_energy
	_energy = clampi(_energy, 0, _max_energy)
	_refresh_pip_textures()


func set_potential_delta(delta: int) -> void:
	_potential_delta = delta
	_refresh_pip_textures()


func _create_pip() -> void:
	var new_pip := TextureRect.new()
	new_pip.custom_minimum_size = _pip_min_size
	new_pip.custom_maximum_size = _pip_max_size
	new_pip.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
	new_pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	new_pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_pip.texture = empty_texture
	_energy_pips.append(new_pip)
	add_child(new_pip)


func _refresh_pip_textures() -> void:
	var preview := clampi(_energy + _potential_delta, 0, _max_energy)
	var stable := mini(_energy, preview)
	var changed := maxi(_energy, preview)
	for i in _energy_pips.size():
		var pip := _energy_pips[i]
		if i < stable:
			pip.texture = filled_texture
		elif i < changed:
			if preview > _energy:
				pip.texture = increase_texture if increase_texture else filled_texture
			else:
				pip.texture = decrease_texture if decrease_texture else empty_texture
		else:
			pip.texture = empty_texture
