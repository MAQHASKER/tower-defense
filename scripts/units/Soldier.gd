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

var hp: float = 50.0
var max_hp: float = 50.0
var damage: float = 5.0
var attack_speed: float = 1.0
var attack_range: float = 0.8
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

	collision_layer = LAYER_SOLDIER
	collision_mask = LAYER_BUILDING | LAYER_SOLDIER
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	cs.shape = shape
	cs.position.y = box_size.y / 2.0
	add_child(cs)
	# home_position устанавливается снаружи, после add_child

func _process(delta: float) -> void:
	if _current_target:
		if not is_instance_valid(_current_target):
			_current_target = null
		else:
			var d_home := home_position.distance_to(_current_target.global_position)
			if d_home > detect_range * Constants.CELL_SIZE:
				_current_target = null

	if not _current_target:
		_current_target = _find_enemy()

	if _current_target:
		_engage_target(delta)
	else:
		_return_home()

func _engage_target(delta: float) -> void:
	var dist := global_position.distance_to(_current_target.global_position)
	var attack_dist_world := attack_range * Constants.CELL_SIZE

	if dist > attack_dist_world:
		_move_towards(_current_target.global_position)
	else:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_current_target.take_damage(damage)
			_attack_timer = attack_speed

func _return_home() -> void:
	var dist := global_position.distance_to(home_position)
	if dist > 0.1:
		_move_towards(home_position)
	else:
		global_position = home_position

# Идёт к цели, обходя постройки и других солдат.
# Простое движение «в лоб» не годится: солдат упирается в казарму и стоит,
# поэтому до гоблина за ней он не дойдёт.
func _move_towards(target: Vector3) -> void:
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length_squared() <= 0.000001:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var dir := to_target.normalized()
	velocity = _avoid(dir) * move_speed * Constants.CELL_SIZE
	move_and_slide()

# Если прямо по курсу препятствие, идём не в лоб, а вдоль его стены
func _avoid(dir: Vector3) -> Vector3:
	var half_height := SIZE_CELLS.y * Constants.CELL_SIZE * 0.5
	var from := global_position + Vector3(0, half_height, 0)
	var to := from + dir * AVOID_PROBE_CELLS * Constants.CELL_SIZE

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = LAYER_BUILDING | LAYER_SOLDIER
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

func _find_enemy() -> Enemy:
	var range_world := detect_range * Constants.CELL_SIZE
	var closest: Enemy = null
	var closest_dist := INF

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var d := home_position.distance_to(enemy.global_position)
		if d <= range_world and d < closest_dist:
			closest = enemy
			closest_dist = d

	return closest

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	var parent_barracks = get_parent()
	if parent_barracks and parent_barracks.has_method("on_soldier_died"):
		parent_barracks.on_soldier_died()
	queue_free()
