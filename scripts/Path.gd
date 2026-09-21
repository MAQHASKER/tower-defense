class_name Path
extends RefCounted

# Путь как список клеток. Пока — простой, для теста.
# Позже будем грузить из stages.json
var cells: Array[Vector2i] = [
    Vector2i(0, 14),
    Vector2i(1, 14),
    Vector2i(2, 14),
    Vector2i(3, 14),
    Vector2i(4, 14),
    Vector2i(5, 14),
    Vector2i(6, 14),
    Vector2i(7, 14),
    Vector2i(8, 14),
    Vector2i(9, 14),
    Vector2i(10, 14),
    Vector2i(11, 14),
    Vector2i(12, 14),
    Vector2i(13, 14),
    Vector2i(14, 14),
    Vector2i(15, 14),
    Vector2i(16, 14),
    Vector2i(17, 14),
    Vector2i(18, 14),
    Vector2i(19, 14),
    Vector2i(20, 14),
    Vector2i(21, 14),
    Vector2i(22, 14),
    Vector2i(23, 14),
    Vector2i(24, 14),
    Vector2i(25, 14),
    Vector2i(26, 14),
]

func get_start() -> Vector2i:
    return cells[0]

func get_end() -> Vector2i:
    return cells[cells.size() - 1]

func get_world_path() -> Array[Vector3]:
    var world_path: Array[Vector3] = []
    for cell in cells:
        world_path.append(Constants.cell_to_world(cell))
    return world_path