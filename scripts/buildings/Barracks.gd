class_name Barracks
extends Node3D

const SOLDIER_COUNT := 5
const RESPAWN_TIME := 15.0
const SOLDIER_HP := 50.0
const SOLDIER_DAMAGE := 5.0

var cell: Vector2i
var soldiers: Array[Soldier] = []
var _respawn_queue: Array[float] = []

var _mesh: MeshInstance3D

func setup(barracks_cell: Vector2i) -> void:
	cell = barracks_cell
	add_to_group("barracks")

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 1.6, 1.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.7)
	box.material = mat
	_mesh.mesh = box
	_mesh.position.y = 0.8
	add_child(_mesh)

	for i in range(SOLDIER_COUNT):
		_spawn_soldier(i)

func _spawn_soldier(index: int) -> void:
	var soldier := Soldier.new()
	var offset := _get_offset(index)
	soldier.setup(SOLDIER_HP, SOLDIER_DAMAGE)
	add_child(soldier)
	var home := global_position + offset
	soldier.global_position = home
	soldier.home_position = home
	soldiers.append(soldier)

func _get_offset(index: int) -> Vector3:
	var angle := (float(index) / SOLDIER_COUNT) * TAU
	var radius := 1.4
	return Vector3(cos(angle) * radius, 0, sin(angle) * radius)

func _process(delta: float) -> void:
	var i := _respawn_queue.size() - 1
	while i >= 0:
		_respawn_queue[i] -= delta
		if _respawn_queue[i] <= 0.0:
			_respawn_queue.remove_at(i)
			_spawn_soldier(soldiers.size())
		i -= 1

func on_soldier_died() -> void:
	for i in range(soldiers.size() - 1, -1, -1):
		if not is_instance_valid(soldiers[i]):
			soldiers.remove_at(i)
	_respawn_queue.append(RESPAWN_TIME)