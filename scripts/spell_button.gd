class_name SpellButton
extends Button

var _spell: Spell
var _name_label: Label
var _cost_label: Label

func setup(spell: Spell, player: PlayerManager) -> void:
	_spell = spell
	_name_label = %Name
	_cost_label = %Cost
	_name_label.text = spell.display_name
	_cost_label.text = str(player.spell_cost(spell))
