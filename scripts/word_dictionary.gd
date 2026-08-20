extends Node

const WordBankRes = preload("res://data/word_bank.res")

static var _words: Dictionary = {}
static var _loaded: bool = false
static var word_count: int = 0


func _ready() -> void:
	_ensure_loaded()


static func is_word(text: String) -> bool:
	_ensure_loaded()
	var word := text.strip_edges().to_upper()
	if word.is_empty():
		return false
	return _words.has(word)


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if WordBankRes == null:
		push_error("Word bank resource failed to preload.")
		_load_fallback()
		return
	for word in WordBankRes.words:
		_words[word] = true
	word_count = _words.size()
	if word_count < 1000:
		push_error("Word bank only has %d entries; expected the full ENABLE list." % word_count)
		_load_fallback()


static func _load_fallback() -> void:
	var fallback := PackedStringArray([
		"A", "I",
		"AN", "AT", "AS", "BE", "BY", "DO", "GO", "HE", "IF", "IN", "IS", "IT",
		"ME", "MY", "NO", "OF", "ON", "OR", "SO", "TO", "UP", "US", "WE",
		"AND", "THE", "ATE", "DIE", "CAT", "DOG", "CAR", "RAN", "RUN", "STAR", "SEND"
	])
	for word in fallback:
		_words[word.to_upper()] = true
	word_count = _words.size()
