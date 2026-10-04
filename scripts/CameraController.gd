extends Camera3D

@export var move_speed := 30.0
@export var rotate_speed := 90.0     # градусов в секунду
@export var zoom_speed := 4.0
@export var min_distance := 25.0
@export var max_distance := 90.0

# Точка на земле, куда смотрит камера
var pivot: Vector3 = Vector3(28, 0, 28)
var yaw: float = 45.0       # поворот вокруг Y
var pitch: float = 50.0     # наклон вниз
var distance: float = 50.0  # расстояние от pivot до камеры

func _ready() -> void:
	_update_camera()

func _process(delta: float) -> void:
	var yaw_rad := deg_to_rad(yaw)
	# Направление "вперёд" по земле (в сторону взгляда камеры)
	var forward := Vector3(-sin(yaw_rad), 0, -cos(yaw_rad))
	# Направление "вправо" по земле
	var right := Vector3(cos(yaw_rad), 0, -sin(yaw_rad))

	var move := Vector3.ZERO
	if Input.is_action_pressed("camera_forward"):
		move += forward
	if Input.is_action_pressed("camera_back"):
		move -= forward
	if Input.is_action_pressed("camera_right"):
		move += right
	if Input.is_action_pressed("camera_left"):
		move -= right

	if move.length() > 0.0:
		pivot += move.normalized() * move_speed * delta
		_clamp_pivot()

	if Input.is_action_pressed("camera_rotate_left"):
		yaw += rotate_speed * delta
	if Input.is_action_pressed("camera_rotate_right"):
		yaw -= rotate_speed * delta

	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = clamp(distance - zoom_speed, min_distance, max_distance)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance = clamp(distance + zoom_speed, min_distance, max_distance)
			_update_camera()

func _update_camera() -> void:
	var yaw_rad := deg_to_rad(yaw)
	var pitch_rad := deg_to_rad(pitch)
	var offset := Vector3(
		sin(yaw_rad) * cos(pitch_rad),
		sin(pitch_rad),
		cos(yaw_rad) * cos(pitch_rad)
	) * distance
	position = pivot + offset
	look_at(pivot, Vector3.UP)

func _clamp_pivot() -> void:
	var max_x := Constants.MAP_WIDTH * Constants.CELL_SIZE
	var max_z := Constants.MAP_HEIGHT * Constants.CELL_SIZE
	pivot.x = clamp(pivot.x, 0.0, max_x)
	pivot.z = clamp(pivot.z, 0.0, max_z)