extends ColorRect
class_name Shop

var gold_counter: Label
var spells: VBoxContainer
var letters: VBoxContainer 
var enchantments: VBoxContainer
var upgrades: VBoxContainer
var next_level_btn: Button


func _ready() -> void:
	gold_counter = %GoldCounter
	spells = %Spells
	letters = %Letters
	enchantments = %Enchantments
	upgrades = %Upgrades
	next_level_btn = %NextLevelButton
