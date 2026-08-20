class_name VfxLayer
extends Node2D


func popup(local_pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.position = local_pos + Vector2(-18, -18)
	label.z_index = 20
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -28), 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)


func burst(local_pos: Vector2, color: Color) -> void:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var ang := TAU * float(i) / 8.0
		pts.append(Vector2(cos(ang), sin(ang)) * 10.0)
	poly.polygon = pts
	poly.color = color
	poly.position = local_pos
	poly.z_index = 18
	add_child(poly)
	var tween := create_tween()
	tween.tween_property(poly, "scale", Vector2(2.4, 2.4), 0.22)
	tween.parallel().tween_property(poly, "modulate:a", 0.0, 0.22)
	tween.tween_callback(poly.queue_free)
