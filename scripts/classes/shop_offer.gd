class_name ShopOffer
extends Resource

enum Kind { SPELL, ENCHANTMENT, LETTER, UPGRADE }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 10
@export var kind: Kind = Kind.SPELL
@export var unique: bool = false
@export var spell: Spell
@export var letter_blueprint: LetterBlueprint
@export var enchantment: LetterEffect
@export var max_energy_bonus: int = 0
@export var vowel_size_bonus: int = 0
@export var consonant_size_bonus: int = 0
