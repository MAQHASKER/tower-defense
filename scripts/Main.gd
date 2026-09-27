extends Node3D

@onready var ground: Node3D = $Ground
@onready var entities: Node3D = $Entities
@onready var build_panel: CanvasLayer = $BuildPanel

var path: Path
var grid: Grid
var selected_tower_type: String = ""
var tower_costs: Dictionary = {}

func _ready() -> void:
	path = Path.new()
	grid = Grid.new()
	grid.mark_path(path.cells)
	grid.mark_base(path.get_end())

	build_ground()
	build_path_visual()
	spawn_base()

	_load_tower_costs()
	build_panel.set_costs(tower_costs)
	build_panel.tower_selected.connect(_on_tower_selected)
	build_panel.start_wave_pressed.connect(_on_start_wave_pressed)

func _load_tower_costs() -> void:
	var file := FileAccess.open("res://data/balance.json", FileAccess.READ)
	if not file:
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	for type in data.get("towers", {}):
		tower_costs[type] = data.towers[type].cost

func _on_tower_selected(tower_type: String) -> void:
	selected_tower_type = tower_type
	print("Выбрана башня: ", tower_type)

func _on_start_wave_pressed() -> void:
	print("Начать волну досрочно (пока не работает)")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected_tower_type != "":
				_try_build_tower(event.position)

func _try_build_tower(screen_pos: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 1000
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space.intersect_ray(query)
	if result.is_empty():
		return

	var world_pos: Vector3 = result.position
	var cell := Vector2i(int(world_pos.x / Constants.CELL_SIZE), int(world_pos.z / Constants.CELL_SIZE))

	if not grid.is_free(cell):
		print("Клетка занята")
		return

	var cost: int = tower_costs.get(selected_tower_type, 0)
	if not GameManager.spend_gold(cost):
		print("Не хватает золота")
		return

	var tower := Tower.new()
	tower.position = Constants.cell_to_world(cell)
	tower.setup(selected_tower_type, cell)
	entities.add_child(tower)
	grid.occupy(cell)

	print("Построена башня: ", selected_tower_type, " на ", cell)

# --- Старые методы ---

func build_ground() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(
		Constants.MAP_WIDTH * Constants.CELL_SIZE,
		0.2,
		Constants.MAP_HEIGHT * Constants.CELL_SIZE
	)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Constants.COLOR_GROUND
	mesh.material = mat

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = Vector3(
		Constants.MAP_WIDTH * Constants.CELL_SIZE / 2.0,
		-0.1,
		Constants.MAP_HEIGHT * Constants.CELL_SIZE / 2.0
	)
	ground.add_child(instance)

		# Коллизия для raycast
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	col.shape = shape
	body.add_child(col)
	body.position = instance.position
	ground.add_child(body)

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
		instance.position.y = 0.06
		ground.add_child(instance)

func spawn_base() -> void:
	var base := Base.new()
	base.position = Constants.cell_to_world(path.get_end())
	base.setup()
	entities.add_child(base)
