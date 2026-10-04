class_name Tower
extends Node3D

var tower_type: String = "archer"
var damage: float = 10.0
var range_cells: float = 3.5
var cooldown: float = 0.5
var projectile_color: Color = Color(1.0, 1.0, 0.4)
var cell: Vector2i

var level: int = 1
var base_cost: int = 0
var total_invested: int = 0

var _cooldown_timer: float = 0.0
var _mesh: Node3D
var _base_size: Vector3

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
		base_cost = stats.get("cost", 0)
		total_invested = base_cost
		var c: Array = stats.get("color", [0.4, 0.4, 0.8])
		color = Color(c[0], c[1], c[2])

	# Модель или куб — в зависимости от типа
	if type == "archer":
		var scene: PackedScene = load("res://assets/models/towers/archer_lvl1.glb")
		if scene:
			_mesh = scene.instantiate()
			_base_size = Vector3(1.2, 3.0, 1.2)
		else:
			_mesh = _make_fallback_cube(Vector3(1.2, 3.0, 1.2), color)
			_base_size = Vector3(1.2, 3.0, 1.2)
	else:
		var box := BoxMesh.new()
		if type == "ballista":
			box.size = Vector3(1.3, 4.0, 1.3)
		else:
			box.size = Vector3(1.6, 1.6, 1.6)
		_base_size = box.size
		_mesh = MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		box.material = mat
		_mesh.mesh = box
		_mesh.position.y = box.size.y / 2.0

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
	projectile.global_position = global_position + Vector3(0, _base_size.y, 0)

# --- API для TowerPanel ---

func get_cell() -> Vector2i:
	return cell

func get_display_name() -> String:
	match tower_type:
		"archer": return "🏹 Лучник"
		"ballista": return "🎯 Баллиста"
	return tower_type

func get_stats_text() -> String:
	var lines := []
	lines.append("Уровень: %d / 3" % level)
	lines.append("Урон: %.0f" % damage)
	lines.append("Радиус: %.1f клеток" % range_cells)
	lines.append("Перезарядка: %.1f с" % cooldown)
	return "\n".join(lines)

func get_upgrade_cost() -> int:
	if level >= 3:
		return 0
	return int(base_cost * (0.5 if level == 1 else 1.0))

func get_sell_value() -> int:
	return int(total_invested * 0.7)

func upgrade() -> bool:
	if level >= 3:
		return false
	var cost := get_upgrade_cost()
	if not GameManager.spend_gold(cost):
		return false
	level += 1
	total_invested += cost
	damage *= 1.3
	range_cells *= 1.1
	# Визуально чуть больше
	_mesh.scale = Vector3.ONE * (1.0 + (level - 1) * 0.1)
	return true

func sell() -> void:
	GameManager.add_gold(get_sell_value())
	queue_free()

func _make_fallback_cube(size: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	box.material = mat
	m.mesh = box
	m.position.y = size.y / 2.0
	return m