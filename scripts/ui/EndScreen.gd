extends CanvasLayer

var _root: Control
var _panel: PanelContainer
var _title: Label
var _subtitle: Label

func _ready() -> void:
	_build_ui()
	_root.visible = false

	GameManager.game_won.connect(_on_game_won)
	GameManager.game_over.connect(_on_game_over)

	process_mode = Node.PROCESS_MODE_ALWAYS

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(400, 300)
	_panel.position = Vector2(-200, -150)
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 32)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title)

	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 16)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_subtitle)

	var restart_btn := Button.new()
	restart_btn.text = "🔄 Заново"
	restart_btn.custom_minimum_size = Vector2(0, 50)
	restart_btn.add_theme_font_size_override("font_size", 18)
	restart_btn.pressed.connect(_on_restart)
	vbox.add_child(restart_btn)

	var exit_btn := Button.new()
	exit_btn.text = "🚪 Выход"
	exit_btn.custom_minimum_size = Vector2(0, 50)
	exit_btn.add_theme_font_size_override("font_size", 18)
	exit_btn.pressed.connect(_on_exit)
	vbox.add_child(exit_btn)

func _on_game_won() -> void:
	_title.text = "ПОБЕДА!"
	_title.add_theme_color_override("font_color", Color.GOLD)
	_subtitle.text = "Все волны отбиты"
	_show()

func _on_game_over() -> void:
	_title.text = "ПОРАЖЕНИЕ"
	_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	_subtitle.text = "Ратуша пала"
	_show()

func _show() -> void:
	_root.visible = true
	get_tree().paused = true

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit() -> void:
	get_tree().quit()