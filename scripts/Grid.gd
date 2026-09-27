class_name Grid
extends RefCounted

var occupied: Dictionary = {}

func occupy(cell: Vector2i, cell_type: String = "tower") -> void:
	occupied[cell] = cell_type

func is_free(cell: Vector2i) -> bool:
	if occupied.has(cell):
		return false
	if cell.x < 0 or cell.x >= Constants.MAP_WIDTH:
		return false
	if cell.y < 0 or cell.y >= Constants.MAP_HEIGHT:
		return false
	return true

func release(cell: Vector2i) -> void:
	occupied.erase(cell)

func mark_path(cells: Array[Vector2i]) -> void:
	for cell in cells:
		occupied[cell] = "path"

func mark_base(center: Vector2i) -> void:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var c := Vector2i(center.x + dx, center.y + dy)
			occupied[c] = "base"