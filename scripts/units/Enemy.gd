class_name Enemy
extends Node3D

# Характеристики (пока хардкод, позже — из balance.json)
var hp: float = 30.0
var max_hp: float = 30.0
var speed: float = 1.5          # клеток в секунду
var damage: float = 5.0
var reward: int = 10
var attack_speed: float = 1.0   # секунд между ударами
var _attack_timer: float = 0.0
var _reached_base: bool = false

# Путь
var path_cells: Array[Vector2i] = []
var current_index: int = 0
var _progress: float = 0.0       # 0..1 между текущей и следующей клеткой

# Ссылка на визуал (куб)
var _mesh: MeshInstance3D

func setup(path: Array[Vector2i], color: Color = Constants.COLOR_ENEMY) -> void:
    path_cells = path
    current_index = 0
    add_to_group("enemies")

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
    if _reached_base:
        _attack_timer -= delta
        if _attack_timer <= 0.0:
            GameManager.damage_base(damage)
            _attack_timer = attack_speed
        return

    if path_cells.size() < 2:
        return

    # Останавливаемся за 2 клетки до конца пути (перед ратушей)
    var stop_index: int = max(1, path_cells.size() - 3)
    if current_index >= stop_index:
        _reach_base()
        return

    var from_pos := Constants.cell_to_world(path_cells[current_index])
    var to_pos := Constants.cell_to_world(path_cells[current_index + 1])

    _progress += speed * delta

    if _progress >= 1.0:
        _progress = 0.0
        current_index += 1
        if current_index >= stop_index:
            position = Constants.cell_to_world(path_cells[stop_index])
            _reach_base()
            return

    position = from_pos.lerp(to_pos, _progress)

func _reach_base() -> void:
    _reached_base = true
    _attack_timer = attack_speed

func take_damage(amount: float) -> void:
    hp -= amount
    if hp <= 0:
        die()

func die() -> void:
    GameManager.add_gold(reward)
    queue_free()