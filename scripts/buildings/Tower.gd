class_name Tower
extends Node3D

# Характеристики (хардкод, позже — из balance.json)
var damage: float = 10.0
var range_cells: float = 3.0        # радиус в клетках
var cooldown: float = 0.5           # секунд между выстрелами
var projectile_color: Color = Color(1.0, 1.0, 0.4)

var _cooldown_timer: float = 0.0
var _mesh: MeshInstance3D

func setup(color: Color = Constants.COLOR_TOWER) -> void:
    _mesh = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(1.0, 2.0, 1.0)   # тонкая высокая башня
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    box.material = mat
    _mesh.mesh = box
    _mesh.position.y = 1.0
    add_child(_mesh)

func _process(delta: float) -> void:
    _cooldown_timer -= delta
    if _cooldown_timer > 0.0:
        return

    var target := _find_target()
    if target:
        _shoot(target)
        _cooldown_timer = cooldown

func _find_target() -> Enemy:
    var range_world := range_cells * Constants.CELL_SIZE
    var closest: Enemy = null
    var closest_dist := INF

    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var d := global_position.distance_to(enemy.global_position)
        if d <= range_world and d < closest_dist:
            closest = enemy
            closest_dist = d

    return closest

func _shoot(target: Enemy) -> void:
    var projectile := Projectile.new()
    projectile.setup(target, damage, projectile_color)
    get_parent().add_child(projectile)
    projectile.global_position = global_position + Vector3(0, 2.0, 0)