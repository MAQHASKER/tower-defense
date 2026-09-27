class_name Tower
extends Node3D

var tower_type: String = "archer"
var damage: float = 10.0
var range_cells: float = 3.5
var cooldown: float = 0.5
var projectile_color: Color = Color(1.0, 1.0, 0.4)
var cell: Vector2i

var _cooldown_timer: float = 0.0
var _mesh: MeshInstance3D

static var _balance_cache: Dictionary = {}

static func _load_balance() -> Dictionary:
	if _balance_cache.is_empty():
		var file := FileAccess.open("res://data/balance.json", FileAccess.READ)
		if file:
			var data: Dictionary = JSON.parse_string(file.get_as_text())
			file.close()
			_balance_cache = data.get("towers", {})
	return _balance_cache

func setup(type: String, tower_cell: Vector2i) -> void:
	tower_type = type
	cell = tower_cell

	var balance := _load_balance()
	var color: Color = Constants.COLOR_TOWER

	if balance.has(type):
		var stats: Dictionary = balance[type]
		damage = stats.get("damage", 10)
		range_cells = stats.get("range_cells", 3.5)
		cooldown = stats.get("cooldown", 0.5)
		var c: Array = stats.get("color", [0.4, 0.4, 0.8])
		color = Color(c[0], c[1], c[2])

	# Разный визуал для разных башен
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	if type == "ballista":
		box.size = Vector3(1.3, 4.0, 1.3)
	elif type == "archer":
		box.size = Vector3(1.2, 3.0, 1.2)
	else:
		box.size = Vector3(1.6, 1.6, 1.6)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	box.material = mat
	_mesh.mesh = box
	_mesh.position.y = box.size.y / 2.0
	add_child(_mesh)

func _process(delta: float) -> void:
	if tower_type == "barracks":
		return   # казармы пока не стреляют

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