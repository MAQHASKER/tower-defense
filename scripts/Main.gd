extends Node3D

@onready var ground: Node3D = $Ground
@onready var entities: Node3D = $Entities

var path: Path

func _ready() -> void:
    path = Path.new()
    build_ground()
    build_path_visual()
    spawn_test_tower()

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

func build_path_visual() -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(Constants.CELL_SIZE * 0.95, 0.05, Constants.CELL_SIZE * 0.95)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Constants.COLOR_PATH
    mesh.material = mat

    for cell in path.cells:
        var instance := MeshInstance3D.new()
        instance.mesh = mesh
        instance.position = Constants.cell_to_world(cell)
        instance.position.y = 0.05
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
    
func spawn_test_enemy() -> void:
    var enemy := Enemy.new()
    enemy.setup(path.cells)
    entities.add_child(enemy)

func spawn_test_tower() -> void:
    var tower := Tower.new()
    tower.position = Constants.cell_to_world(Vector2i(10, 12))   # рядом с путём
    tower.setup()
    entities.add_child(tower)