class_name Constants
extends RefCounted

const CELL_SIZE := 2.0
const MAP_WIDTH := 28
const MAP_HEIGHT := 28

const COLOR_GROUND := Color(0.3, 0.5, 0.3)
const COLOR_PATH   := Color(0.6, 0.5, 0.4)
const COLOR_TOWER  := Color(0.4, 0.4, 0.8)
const COLOR_ENEMY  := Color(0.8, 0.3, 0.3)
const COLOR_BASE   := Color(0.9, 0.8, 0.3)

static func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(
		(cell.x + 0.5) * CELL_SIZE,
		0.0,
		(cell.y + 0.5) * CELL_SIZE
	)
