class_name Soldier
extends CharacterBody3D

# Слои физики: солдат опирается на постройки и на других солдат.
# С врагами он не сталкивается — блокировка врагов считается по расстоянию.
const LAYER_BUILDING := 1 << 2
const LAYER_SOLDIER := 1 << 3

# Размер коробки-заглушки в клетках (до появления модели из Blender)
const SIZE_CELLS := Vector3(0.3, 0.6, 0.3)

# Длина "щупа" вперёд в клетках. Если щуп упёрся в стену — солдат идёт вдоль неё.
const AVOID_PROBE_CELLS := 0.45

# Мягкое расталкивание. Жёсткая коллизия между солдатами заставляла их дрожать,
# толкаясь коробками, а полное её отсутствие — слипаться. Поэтому разводим
# силой, пропорциональной перекрытию.
# Радиус обязан быть МЕНЬШЕ шага строя (CELL_SIZE / 3 = 1.0 м), иначе солдаты
# начнут расталкивать друг друга прямо на точке сбора и снова задрожат.
const SEPARATION_RADIUS_CELLS := 0.31
const SEPARATION_SPEED := 3.0

var hp: float = 50.0
var max_hp: float = 50.0
var damage: float = 5.0
var attack_speed: float = 1.0
# Зазор до поверхности врага, при котором начинается бой (в клетках).
# Считается до граней коробки врага, а не до центра: у всадника центр
# внутри длинного тела, и солдат залезал бы внутрь него.
var attack_gap: float = 0.12
var detect_range: float = 4.5
var move_speed: float = 4.0
var home_position: Vector3 = Vector3.ZERO

var _attack_timer: float = 0.0
var _current_target: Enemy = null
var _mesh: MeshInstance3D

func setup(hp_val: float = 50.0, dmg: float = 5.0) -> void:
	hp = hp_val
	max_hp = hp_val
	damage = dmg
	add_to_group("soldiers")

	var box_size := SIZE_CELLS * Constants.CELL_SIZE
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = box_size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 1.0)
	box.material = mat
	_mesh.mesh = box
	_mesh.position.y = box_size.y / 2.0
	add_child(_mesh)

	# Солдаты не сталкиваются друг с другом: в тесноте они толкались коробками
	# и постоянно дёргались. Друг от друга их держит строй на точке сбора.
	collision_layer = LAYER_SOLDIER
	collision_mask = LAYER_BUILDING
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	cs.shape = shape
	cs.position.y = box_size.y / 2.0
	add_child(cs)
	# home_position устанавливается снаружи, после add_child

func _process(delta: float) -> void:
	if _current_target != null:
		if not is_instance_valid(_current_target):
			_release_target()
		elif _is_claimed_by_other(_current_target):
			# цель перехватил другой солдат
			_release_target()
		elif home_position.distance_to(_current_target.global_position) > detect_range * Constants.CELL_SIZE:
			_release_target()

	if _current_target == null:
		_set_target(_find_enemy())

	if _current_target != null:
		_engage_target(delta)
	else:
		_return_home()

func _engage_target(delta: float) -> void:
	var in_range: bool = _surface_gap(_current_target) <= attack_gap * Constants.CELL_SIZE
	var dir := Vector3.ZERO
	if not in_range:
		dir = _current_target.global_position - global_position
		dir.y = 0.0
		if dir.length_squared() > 0.000001:
			dir = dir.normalized()
	# двигаемся всегда — даже в бою, чтобы мягко развестись с соседями
	_move(dir)

	if in_range:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_current_target.take_damage(damage)
			_attack_timer = attack_speed

# Зазор между коробкой солдата и коробкой врага. Ноль — они соприкасаются.
func _surface_gap(enemy: Enemy) -> float:
	var to_enemy := enemy.global_position - global_position
	to_enemy.y = 0.0
	# переводим в систему координат врага: X — поперёк, Z — вдоль
	var local := Basis(Vector3.UP, -enemy.rotation.y) * to_enemy
	var half := Vector2(enemy.body_size.x * 0.5, enemy.body_size.z * 0.5)
	var outside := Vector2(
		maxf(absf(local.x) - half.x, 0.0),
		maxf(absf(local.z) - half.y, 0.0)
	)
	var self_half := SIZE_CELLS.x * Constants.CELL_SIZE * 0.5
	return maxf(outside.length() - self_half, 0.0)

func _return_home() -> void:
	var to_home := home_position - global_position
	to_home.y = 0.0
	var dist := to_home.length()
	var dir := Vector3.ZERO
	if dist > 0.1:
		dir = to_home.normalized()
	_move(dir)

# Двигается в заданном направлении, обходя постройки, и всегда применяет
# мягкое расталкивание — даже когда стоит на месте. Иначе в бою солдаты,
# дошедшие до врага, переставали двигаться и слипались.
func _move(dir: Vector3) -> void:
	var steer := Vector3.ZERO
	if dir.length_squared() > 0.000001:
		steer = _avoid(dir) * move_speed * Constants.CELL_SIZE
	velocity = steer + _separation() * SEPARATION_SPEED
	move_and_slide()

# Вектор расталкивания от соседей: длина равна глубине перекрытия в метрах
func _separation() -> Vector3:
	var push := Vector3.ZERO
	var radius := SEPARATION_RADIUS_CELLS * Constants.CELL_SIZE
	for other in get_tree().get_nodes_in_group("soldiers"):
		if other == self or not is_instance_valid(other):
			continue
		var away: Vector3 = global_position - other.global_position
		away.y = 0.0
		var dist := away.length()
		if dist > 0.001 and dist < radius:
			push += away.normalized() * (radius - dist)
	return push

# Если прямо по курсу препятствие, идём не в лоб, а вдоль его стены
func _avoid(dir: Vector3) -> Vector3:
	var half_height := SIZE_CELLS.y * Constants.CELL_SIZE * 0.5
	var from := global_position + Vector3(0, half_height, 0)
	var to := from + dir * AVOID_PROBE_CELLS * Constants.CELL_SIZE

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = LAYER_BUILDING
	var exclude: Array[RID] = [get_rid()]
	query.exclude = exclude

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return dir

	var normal: Vector3 = hit.normal
	normal.y = 0.0
	if normal.length_squared() < 0.0001:
		return dir
	normal = normal.normalized()

	var tangent := normal.cross(Vector3.UP)
	if tangent.length_squared() < 0.0001:
		tangent = Vector3.RIGHT
	tangent = tangent.normalized()
	# обходим с той стороны, которая ближе к цели, и чуть отходим от стены
	if tangent.dot(dir) < 0.0:
		tangent = -tangent
	return (tangent + normal * 0.35).normalized()

# Один враг — один солдат. Если все враги в радиусе уже заняты, солдат
# остаётся на точке сбора: иначе пятеро сбиваются в кучу на одном гоблине.
# Исключение — враги, которых нельзя заблокировать (всадник): один солдат
# его всё равно не удержит, поэтому бить его могут все, кто достаёт.
func _find_enemy() -> Enemy:
	var range_world := detect_range * Constants.CELL_SIZE
	var closest: Enemy = null
	var closest_dist := INF

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if _is_claimed_by_other(enemy):
			continue
		var d := home_position.distance_to(enemy.global_position)
		if d <= range_world and d < closest_dist:
			closest = enemy
			closest_dist = d

	return closest

func _is_claimed_by_other(enemy: Enemy) -> bool:
	if enemy == null or not enemy.can_be_blocked:
		return false
	if enemy.claimed_by == null or enemy.claimed_by == self:
		return false
	return is_instance_valid(enemy.claimed_by)

func _set_target(enemy: Enemy) -> void:
	_release_target()
	_current_target = enemy
	# Захват ставим только на блокируемых: незаблокированного ведут все
	if enemy != null and enemy.can_be_blocked:
		enemy.claimed_by = self

func _release_target() -> void:
	if _current_target != null and is_instance_valid(_current_target) and _current_target.claimed_by == self:
		_current_target.claimed_by = null
	_current_target = null

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	_release_target()
	var parent_barracks = get_parent()
	if parent_barracks and parent_barracks.has_method("on_soldier_died"):
		parent_barracks.on_soldier_died()
	queue_free()
