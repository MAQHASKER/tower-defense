class_name Enemy
extends Node3D

# Характеристики — заполняются из balance.json через setup()
var hp: float = 30.0
var max_hp: float = 30.0
var speed: float = 1.5
var damage: float = 5.0
var attack_speed: float = 1.0
var reward: int = 10
var can_be_blocked: bool = true

# Габариты в метрах: ширина (X), высота (Y), длина вдоль пути (Z)
var body_size: Vector3 = Vector3.ONE

# Путь
var path_cells: Array[Vector2i] = []
var current_index: int = 0
var _progress: float = 0.0

# Атака базы
var _attack_timer: float = 0.0
var _reached_base: bool = false

# Визуал
var _visual: Node3D
var _body_color: Color = Constants.COLOR_ENEMY

# Раскладка врагов внутри одной клетки: X — поперёк пути, Z — вдоль
var _slot_cols: int = 1
var _slot_rows: int = 1
var _slot_offset: Vector3 = Vector3.ZERO

static var _balance_cache: Dictionary = {}

static func _load_balance() -> Dictionary:
	if _balance_cache.is_empty():
		var file := FileAccess.open("res://data/balance.json", FileAccess.READ)
		if file:
			var data: Dictionary = JSON.parse_string(file.get_as_text())
			file.close()
			_balance_cache = data.get("enemies", {})
	return _balance_cache

# Сколько врагов этого типа помещается в одну клетку
static func get_slot_count(enemy_type: String) -> int:
	var balance := _load_balance()
	if not balance.has(enemy_type):
		return 1
	var stats: Dictionary = balance[enemy_type]
	var cols: int = max(1, int(stats.get("slot_cols", 1)))
	var rows: int = max(1, int(stats.get("slot_rows", 1)))
	return cols * rows

func setup(path: Array[Vector2i], enemy_type: String = "goblin", slot_index: int = 0) -> void:
	path_cells = path
	current_index = 0
	add_to_group("enemies")

	var model_path := ""

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
		_body_color = Color(c[0], c[1], c[2])
		body_size = Vector3(
			float(stats.get("width", 1.0)),
			float(stats.get("height", 1.0)),
			float(stats.get("depth", 1.0))
		)
		model_path = String(stats.get("model", ""))
		_slot_cols = max(1, int(stats.get("slot_cols", 1)))
		_slot_rows = max(1, int(stats.get("slot_rows", 1)))
		can_be_blocked = stats.get("can_be_blocked", true)

	_slot_offset = _compute_slot_offset(slot_index)

	_visual = _create_visual(model_path)
	add_child(_visual)
	# Визуал подгоняется по мировой AABB, поэтому враг обязан быть в дереве:
	# WaveSpawner добавляет его ДО вызова setup().
	_fit_visual(_visual)

	if path_cells.size() > 0:
		# Начальный разворот по первому отрезку пути
		if path_cells.size() >= 2:
			var d := Constants.cell_to_world(path_cells[1]) - Constants.cell_to_world(path_cells[0])
			if d.length_squared() > 0.0001:
				rotation.y = atan2(d.x, d.z)
		position = Constants.cell_to_world(path_cells[0]) + _current_offset()

# --- Визуал ---

func _create_visual(model_path: String) -> Node3D:
	if model_path != "":
		var res: Resource = load(model_path)
		var node: Node3D = null
		if res is PackedScene:
			node = (res as PackedScene).instantiate()
		elif res is Mesh:
			var mi := MeshInstance3D.new()
			mi.mesh = res
			node = mi
		if node != null:
			_paint_if_no_material(node)
			return node
		push_warning("Враг: не удалось загрузить модель %s" % model_path)
	return _make_placeholder_box()

func _make_placeholder_box() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = body_size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _body_color
	box.material = mat
	mi.mesh = box
	mi.position.y = body_size.y / 2.0 + 0.01
	return mi

# Масштабирует модель под высоту из balance.json, центрирует по X/Z
# и ставит низ модели на землю. Так размер задаётся только в balance.json,
# а модель можно экспортировать в любом масштабе.
func _fit_visual(visual: Node3D) -> void:
	var origin := global_position
	var bounds := _measure_world(visual)
	if bounds.size.y <= 0.001:
		return
	var s := body_size.y / bounds.size.y
	visual.scale = Vector3.ONE * s
	var local_min := bounds.position - origin
	var local_center := bounds.get_center() - origin
	visual.position = Vector3(
		-local_center.x * s,
		-local_min.y * s + 0.01,
		-local_center.z * s
	)

# Габариты всех мешей поддерева в мировых координатах
static func _measure_world(root: Node3D) -> AABB:
	var mn := Vector3(1e9, 1e9, 1e9)
	var mx := Vector3(-1e9, -1e9, -1e9)
	var found := false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi: MeshInstance3D = n
			var a: AABB = mi.mesh.get_aabb()
			for i in range(8):
				var w: Vector3 = mi.global_transform * a.get_endpoint(i)
				mn = mn.min(w)
				mx = mx.max(w)
			found = true
		for ch in n.get_children():
			stack.push_back(ch)
	if not found:
		return AABB()
	return AABB(mn, mx - mn)

# Если у модели нет своих материалов (например OBJ без рабочего .mtl) —
# красим её плоским цветом врага. Плоский цвет и задуман в дизайне.
func _paint_if_no_material(root: Node) -> void:
	if not _has_no_material(root):
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _body_color
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			(n as MeshInstance3D).material_override = mat
		for ch in n.get_children():
			stack.push_back(ch)

static func _has_no_material(root: Node) -> bool:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			if mi.mesh != null:
				for i in range(mi.mesh.get_surface_count()):
					if mi.mesh.surface_get_material(i) != null:
						return false
		for ch in n.get_children():
			stack.push_back(ch)
	return true

# --- Раскладка внутри клетки ---

# Позиция слота в долях клетки. Нечётные ряды сдвинуты на полшага —
# так враги стоят в шахматном порядке и не выстраиваются в жёсткую сетку.
func _compute_slot_offset(index: int) -> Vector3:
	var cols: int = max(1, _slot_cols)
	var rows: int = max(1, _slot_rows)
	var col: int = index % cols
	var row: int = int(index / float(cols)) % rows
	var x := (float(col) + 0.5) / float(cols) - 0.5
	var z := (float(row) + 0.5) / float(rows) - 0.5
	if row % 2 == 1:
		x += 0.5 / float(cols)
	return Vector3(x, 0.0, z)

# Смещение слота с учётом разворота врага по направлению движения
func _current_offset() -> Vector3:
	return Basis(Vector3.UP, rotation.y) * (_slot_offset * Constants.CELL_SIZE)

# --- Движение ---

func _process(delta: float) -> void:
	if _reached_base:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			GameManager.damage_base(damage)
			_attack_timer = attack_speed
		return

	# Проверка блокировки воином (всадник не блокируется)
	if can_be_blocked:
		var blocker := _find_blocker()
		if blocker:
			_attack_blocker(blocker, delta)
			return

	if path_cells.size() < 2:
		return

	var stop_index: int = max(1, path_cells.size() - 3)
	if current_index >= stop_index:
		_reach_base()
		return

	var from_pos := Constants.cell_to_world(path_cells[current_index])
	var to_pos := Constants.cell_to_world(path_cells[current_index + 1])

	# Разворот по движению: длина врага (локальная ось Z) смотрит вдоль пути
	var dir := to_pos - from_pos
	if dir.length_squared() > 0.0001:
		rotation.y = atan2(dir.x, dir.z)

	_progress += speed * delta

	if _progress >= 1.0:
		_progress = 0.0
		current_index += 1
		if current_index >= stop_index:
			position = Constants.cell_to_world(path_cells[stop_index]) + _current_offset()
			_reach_base()
			return

	position = from_pos.lerp(to_pos, _progress) + _current_offset()

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

func _find_blocker() -> Soldier:
	var range_world := 1.5 * Constants.CELL_SIZE   # радиус блокировки, в клетках
	var closest: Soldier = null
	var closest_dist := INF

	for soldier in get_tree().get_nodes_in_group("soldiers"):
		if not is_instance_valid(soldier):
			continue
		var d := global_position.distance_to(soldier.global_position)
		if d <= range_world and d < closest_dist:
			closest = soldier
			closest_dist = d

	return closest

func _attack_blocker(soldier: Soldier, delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		soldier.take_damage(damage)
		_attack_timer = attack_speed
