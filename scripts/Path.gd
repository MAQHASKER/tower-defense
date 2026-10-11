class_name Path
extends RefCounted

# Путь — список клеток. В stages.json он задаётся ломаной (угловыми точками):
#   "path": [[0,12], [21,12]]          — прямая
#   "path": [[0,12], [15,12], [15,4]]  — с одним изгибом
# Код разворачивает углы в полный список клеток.
var cells: Array[Vector2i] = []

static func from_corners(corners: Array) -> Path:
	var p := Path.new()
	p.cells = expand(corners)
	return p

# Запасной вариант, если в этапе путь не задан.
static func default_straight() -> Path:
	var p := Path.new()
	var y := int(Constants.MAP_HEIGHT / 2.0)
	for x in range(Constants.MAP_WIDTH - 2):
		p.cells.append(Vector2i(x, y))
	return p

# Разворачивает угловые точки в последовательность клеток.
# Отрезки идут по осям: сначала по X, затем по Y.
static func expand(corners: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if corners.size() < 2:
		return result
	var points: Array[Vector2i] = []
	for c in corners:
		points.append(_to_cell(c))
	result.append(points[0])
	for i in range(points.size() - 1):
		_walk(points[i], points[i + 1], result)
	return result

static func _walk(from: Vector2i, to: Vector2i, out: Array[Vector2i]) -> void:
	var cur := from
	while cur.x != to.x:
		cur.x += signi(to.x - cur.x)
		out.append(cur)
	while cur.y != to.y:
		cur.y += signi(to.y - cur.y)
		out.append(cur)

static func _to_cell(raw: Variant) -> Vector2i:
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i.ZERO

func get_start() -> Vector2i:
	return cells[0]

func get_end() -> Vector2i:
	return cells[cells.size() - 1]

func get_world_path() -> Array[Vector3]:
	var world_path: Array[Vector3] = []
	for cell in cells:
		world_path.append(Constants.cell_to_world(cell))
	return world_path
