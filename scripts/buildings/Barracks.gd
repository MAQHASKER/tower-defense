class_name Barracks
extends Node3D

const SOLDIER_COUNT := 5
const RESPAWN_TIME := 15.0

var cell: Vector2i
var soldiers: Array[Soldier] = []
var _respawn_queue: Array[float] = []

var level: int = 1
var base_cost: int = 150
var total_invested: int = 0
var soldier_hp: float = 50.0
var soldier_damage: float = 5.0

var _mesh: MeshInstance3D
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

func setup(barracks_cell: Vector2i) -> void:
	cell = barracks_cell
	add_to_group("barracks")

	var balance := _load_balance()
	if balance.has("barracks"):
		base_cost = balance["barracks"].get("cost", 150)
	total_invested = base_cost

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 1.6, 1.6)
	_base_size = box.size
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
	soldier.setup(soldier_hp, soldier_damage)
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

# --- API для TowerPanel ---

func get_cell() -> Vector2i:
	return cell

func get_display_name() -> String:
	return "⚔️ Казармы"

func get_stats_text() -> String:
	var lines := []
	lines.append("Уровень: %d / 3" % level)
	lines.append("Воинов: %d" % SOLDIER_COUNT)
	lines.append("HP воина: %.0f" % soldier_hp)
	lines.append("Урон воина: %.0f" % soldier_damage)
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
	soldier_hp *= 1.3
	soldier_damage *= 1.3
	# Обновляем живых воинов
	for soldier in soldiers:
		if is_instance_valid(soldier):
			soldier.max_hp = soldier_hp
			soldier.hp = soldier_hp
			soldier.damage = soldier_damage
	# Визуально чуть больше
	_mesh.scale = Vector3.ONE * (1.0 + (level - 1) * 0.1)
	return true

func sell() -> void:
	GameManager.add_gold(get_sell_value())
	queue_free()