class_name Projectile
extends Node3D

# Размеры в клетках, чтобы снаряд масштабировался вместе с клеткой
const RADIUS_CELLS := 0.075
const HIT_DISTANCE_CELLS := 0.1
# На какой высоте целиться во врага (доля клетки)
const AIM_HEIGHT_CELLS := 0.25

var speed: float = 20.0
var damage: float = 10.0
var target: Enemy = null

var _mesh: MeshInstance3D

func setup(target_enemy: Enemy, dmg: float, color: Color = Color(1.0, 1.0, 0.4)) -> void:
    target = target_enemy
    damage = dmg

    var radius := RADIUS_CELLS * Constants.CELL_SIZE
    _mesh = MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    sphere.material = mat
    _mesh.mesh = sphere
    add_child(_mesh)

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        queue_free()
        return

    var target_pos := target.global_position + Vector3(0, AIM_HEIGHT_CELLS * Constants.CELL_SIZE, 0)
    var dir := target_pos - global_position
    var dist := dir.length()

    if dist < HIT_DISTANCE_CELLS * Constants.CELL_SIZE:
        target.take_damage(damage)
        queue_free()
        return

    global_position += dir.normalized() * speed * delta
