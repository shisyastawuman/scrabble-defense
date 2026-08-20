extends SceneTree

func _initialize() -> void:
	var bank_script = load("res://scripts/classes/word_bank.gd")
	var bank = bank_script.new()
	var words := PackedStringArray()
	var seen := {}
	var file := FileAccess.open("res://data/enable1.txt", FileAccess.READ)
	if file == null:
		push_error("Could not open enable1.txt: %s" % FileAccess.get_open_error())
		quit(1)
		return
	while not file.eof_reached():
		var word := file.get_line().strip_edges().to_upper()
		if word.length() < 2:
			continue
		var ok := true
		for i in word.length():
			var code := word.unicode_at(i)
			if code < 65 or code > 90:
				ok = false
				break
		if not ok or seen.has(word):
			continue
		seen[word] = true
		words.append(word)
	for extra in ["A", "I"]:
		if not seen.has(extra):
			words.append(extra)
	bank.words = words
	var path := "res://data/word_bank.res"
	var err := ResourceSaver.save(bank, path)
	if err != OK:
		push_error("Failed to save %s: %s" % [path, err])
		quit(1)
		return
	print("BAKED_DICTIONARY ", words.size(), " words -> ", path)
	quit(0)
