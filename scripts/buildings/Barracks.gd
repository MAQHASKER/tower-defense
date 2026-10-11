class_name Barracks
extends StaticBody3D

# Слой зданий: солдаты о него опираются и не проходят сквозь
const LAYER_BUILDING := 1 << 2

const SOLDIER_COUNT := 5
const RESPAWN_TIME := 15.0

# Размеры в клетках, чтобы масштабироваться вместе с CELL_SIZE
const SIZE_CELLS := Vector3(0.8, 0.8, 0.8)
# Раскладка солдат на клетке сбора: отряд в две шеренги
const RALLY_COLS := 3

var cell: Vector2i
# Клетка сбора — ближайшая клетка пути. Солдаты встают на дорогу, а не
# вокруг казармы, чтобы сразу перекрывать путь.
var rally_cell: Vector2i
var soldiers: Array[Soldier] = []
var _respawn_queue: Array[float] = []
var _path_cells: Array[Vector2i] = []

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

func setup(barracks_cell: Vector2i, path_cells: Array[Vector2i]) -> void:
	cell = barracks_cell
	_path_cells = path_cells
	rally_cell = _nearest_path_cell(barracks_cell)
	add_to_group("barracks")

	var balance := _load_balance()
	if balance.has("barracks"):
		base_cost = balance["barracks"].get("cost", 150)
	total_invested = base_cost

	var box_size := SIZE_CELLS * Constants.CELL_SIZE
	_base_size = box_size

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = box_size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.7)
	box.material = mat
	_mesh.mesh = box
	_mesh.position.y = box_size.y / 2.0
	add_child(_mesh)

	# Постройка становится твёрдой для солдат
	collision_layer = LAYER_BUILDING
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	cs.shape = shape
	cs.position.y = box_size.y / 2.0
	add_child(cs)

	for i in range(SOLDIER_COUNT):
		_spawn_soldier(i)

# Ближайшая клетка пути — на неё солдаты и встают
func _nearest_path_cell(from: Vector2i) -> Vector2i:
	var best := from
	var best_dist := INF
	for c in _path_cells:
		var d := Vector2(float(c.x - from.x), float(c.y - from.y)).length_squared()
		if d < best_dist:
			best_dist = d
			best = c
	return best

# Место солдата в клетке сбора: небольшой отряд в две шеренги
func _rally_offset(index: int) -> Vector3:
	var cols := RALLY_COLS
	var col := index % cols
	var row := int(index / float(cols))
	var step := Constants.CELL_SIZE / 3.0
	return Vector3(
		(float(col) - float(cols - 1) * 0.5) * step,
		0.0,
		(float(row) - 0.5) * step
	)

func _spawn_soldier(index: int) -> void:
	var soldier := Soldier.new()
	soldier.setup(soldier_hp, soldier_damage)
	add_child(soldier)
	var home := Constants.cell_to_world(rally_cell) + _rally_offset(index)
	soldier.global_position = home
	soldier.home_position = home
	soldiers.append(soldier)

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
	lines.append("Сбор: клетка %s" % str(rally_cell))
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
