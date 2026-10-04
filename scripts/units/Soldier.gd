class_name Soldier
extends Node3D

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

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.55, 0.55)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 1.0)
	box.material = mat
	_mesh.mesh = box
	_mesh.position.y = 0.275
	add_child(_mesh)
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
		_return_home(delta)

func _engage_target(delta: float) -> void:
	var dist := global_position.distance_to(_current_target.global_position)
	var attack_dist_world := attack_range * Constants.CELL_SIZE

	if dist > attack_dist_world:
		var dir := (_current_target.global_position - global_position).normalized()
		global_position += dir * move_speed * Constants.CELL_SIZE * delta
	else:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_current_target.take_damage(damage)
			_attack_timer = attack_speed

func _return_home(delta: float) -> void:
	var dist := global_position.distance_to(home_position)
	if dist > 0.1:
		var dir := (home_position - global_position).normalized()
		global_position += dir * move_speed * Constants.CELL_SIZE * delta
	else:
		global_position = home_position

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