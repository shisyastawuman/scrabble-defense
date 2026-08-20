class_name GameColors
extends Object

const INK := Color(0.96, 0.91, 0.82)
const INK_DARK := Color(0.16, 0.11, 0.08)
const PANEL := Color(0.13, 0.1, 0.08, 0.94)
const PANEL_BORDER := Color(0.52, 0.38, 0.2)
const ACCENT := Color(0.78, 0.28, 0.18)
const FELT := Color(0.14, 0.26, 0.16)


static func wall_fill(health: int) -> Color:
	match maxi(health, 1):
		1:
			return Color(0.94, 0.84, 0.4)
		2:
			return Color(0.93, 0.5, 0.18)
		_:
			return Color(0.84, 0.2, 0.18)


static func enemy_fill(health: int) -> Color:
	match maxi(health, 1):
		1:
			return Color(0.36, 0.78, 0.44)
		2:
			return Color(0.3, 0.5, 0.92)
		_:
			return Color(0.68, 0.34, 0.88)


static func village_fill() -> Color:
	return Color(0.62, 0.22, 0.2)
