class_name Projectile
extends Node3D

var speed: float = 20.0
var damage: float = 10.0
var target: Enemy = null

var _mesh: MeshInstance3D

func setup(target_enemy: Enemy, dmg: float, color: Color = Color(1.0, 1.0, 0.4)) -> void:
    target = target_enemy
    damage = dmg

    _mesh = MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.15
    sphere.height = 0.3
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    sphere.material = mat
    _mesh.mesh = sphere
    add_child(_mesh)

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        queue_free()
        return

    var target_pos := target.global_position + Vector3(0, 0.5, 0)
    var dir := target_pos - global_position
    var dist := dir.length()

    if dist < 0.3:
        target.take_damage(damage)
        queue_free()
        return

    global_position += dir.normalized() * speed * delta