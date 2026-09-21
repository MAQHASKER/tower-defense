extends Node3D

@onready var ground: Node3D = $Ground
@onready var entities: Node3D = $Entities

func _ready() -> void:
    build_ground()
    spawn_test_cube()

func build_ground() -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(
        Constants.MAP_WIDTH * Constants.CELL_SIZE,
        0.1,
        Constants.MAP_HEIGHT * Constants.CELL_SIZE
    )
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Constants.COLOR_GROUND
    mesh.material = mat

    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = Vector3(
        Constants.MAP_WIDTH * Constants.CELL_SIZE / 2.0,
        -0.05,
        Constants.MAP_HEIGHT * Constants.CELL_SIZE / 2.0
    )
    ground.add_child(instance)

func spawn_test_cube() -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.0, 1.0, 1.0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Constants.COLOR_TOWER
    mesh.material = mat

    var cube := MeshInstance3D.new()
    cube.mesh = mesh
    cube.position = Constants.cell_to_world(Vector2i(5, 5))
    cube.position.y = 0.5
    entities.add_child(cube)