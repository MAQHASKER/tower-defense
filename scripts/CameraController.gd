extends Camera3D

@export var move_speed := 25.0
@export var zoom_step := 3.0
@export var min_height := 20.0
@export var max_height := 60.0

var is_dragging := false

func _ready() -> void:
	position = Vector3(28, 40, 28)
	rotation_degrees = Vector3(-50, 45, 0)

func _process(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		move.z -= 1
	if Input.is_action_pressed("ui_down"):
		move.z += 1
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_right"):
		move.x += 1

	if move.length() > 0:
		position += move.normalized() * move_speed * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			position.y = clamp(position.y - zoom_step, min_height, max_height)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			position.y = clamp(position.y + zoom_step, min_height, max_height)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = event.pressed
	elif event is InputEventMouseMotion and is_dragging:
		position.x -= event.relative.x * 0.1
		position.z -= event.relative.y * 0.1
