class_name Enemy
extends Node3D

# Характеристики — заполняются из balance.json через setup()
var hp: float = 30.0
var max_hp: float = 30.0
var speed: float = 1.5
var damage: float = 5.0
var attack_speed: float = 1.0
var reward: int = 10

# Путь
var path_cells: Array[Vector2i] = []
var current_index: int = 0
var _progress: float = 0.0

# Атака базы
var _attack_timer: float = 0.0
var _reached_base: bool = false

var _mesh: MeshInstance3D

static var _balance_cache: Dictionary = {}

static func _load_balance() -> Dictionary:
	if _balance_cache.is_empty():
		var file := FileAccess.open("res://data/balance.json", FileAccess.READ)
		if file:
			var data: Dictionary = JSON.parse_string(file.get_as_text())
			file.close()
			_balance_cache = data.get("enemies", {})
	return _balance_cache

func setup(path: Array[Vector2i], enemy_type: String = "goblin") -> void:
	path_cells = path
	current_index = 0
	add_to_group("enemies")

	# Читаем характеристики из balance.json
	var color: Color = Constants.COLOR_ENEMY
	var size: float = 1.0

	var balance := _load_balance()
	if balance.has(enemy_type):
		var stats: Dictionary = balance[enemy_type]
		hp = stats.get("hp", 30)
		max_hp = hp
		speed = stats.get("speed", 1.5)
		damage = stats.get("damage", 5)
		attack_speed = stats.get("attack_speed", 1.0)
		reward = stats.get("reward", 10)
		var c: Array = stats.get("color", [0.8, 0.3, 0.3])
		color = Color(c[0], c[1], c[2])
		size = stats.get("size", 1.0)

	# Визуал
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	box.material = mat
	_mesh.mesh = box
	_mesh.position.y = size / 2.0 + 0.01
	add_child(_mesh)

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