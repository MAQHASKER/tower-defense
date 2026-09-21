class_name Enemy
extends Node3D

# Характеристики (пока хардкод, позже — из balance.json)
var hp: float = 30.0
var max_hp: float = 30.0
var speed: float = 1.5          # клеток в секунду
var damage: float = 5.0
var reward: int = 10

# Путь
var path_cells: Array[Vector2i] = []
var current_index: int = 0
var _progress: float = 0.0       # 0..1 между текущей и следующей клеткой

# Ссылка на визуал (куб)
var _mesh: MeshInstance3D

func setup(path: Array[Vector2i], color: Color = Constants.COLOR_ENEMY) -> void:
    path_cells = path
    current_index = 0

    _mesh = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(1.0, 1.0, 1.0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    box.material = mat
    _mesh.mesh = box
    _mesh.position.y = 0.5
    add_child(_mesh)

    # Ставим в начало пути
    if path_cells.size() > 0:
        position = Constants.cell_to_world(path_cells[0])

func _process(delta: float) -> void:
    if path_cells.size() < 2:
        return
    if current_index >= path_cells.size() - 1:
        return

    var from_pos := Constants.cell_to_world(path_cells[current_index])
    var to_pos := Constants.cell_to_world(path_cells[current_index + 1])

    # Скорость в клетках/сек → доля пути за кадр
    _progress += (speed / 1.0) * delta

    if _progress >= 1.0:
        _progress = 0.0
        current_index += 1
        # Если дошли до конца — пока просто останавливаемся
        if current_index >= path_cells.size() - 1:
            position = Constants.cell_to_world(path_cells[current_index])
            return

    position = from_pos.lerp(to_pos, _progress)

func take_damage(amount: float) -> void:
    hp -= amount
    if hp <= 0:
        die()

func die() -> void:
    queue_free()