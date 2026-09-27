extends CanvasLayer

signal tower_selected(tower_type: String)
signal start_wave_pressed

var _buttons: Dictionary = {}

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -80
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	_add_tower_button(hbox, "archer", "🏹 Лучник")
	_add_tower_button(hbox, "ballista", "🏹 Баллиста")
	_add_tower_button(hbox, "barracks", "⚔️ Казармы")

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(spacer)

	var wave_btn := Button.new()
	wave_btn.text = "▶ Начать волну"
	wave_btn.custom_minimum_size = Vector2(180, 60)
	wave_btn.add_theme_font_size_override("font_size", 18)
	wave_btn.pressed.connect(func(): start_wave_pressed.emit())
	hbox.add_child(wave_btn)

func _add_tower_button(parent: Node, type: String, label: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(140, 60)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func(): tower_selected.emit(type))
	parent.add_child(btn)
	_buttons[type] = btn
	_update_button(type, label, 0)

func _update_button(type: String, label: String, cost: int) -> void:
	if _buttons.has(type):
		_buttons[type].text = "%s\n💰 %d" % [label, cost]

func set_costs(costs: Dictionary) -> void:
	var labels := {
		"archer": "🏹 Лучник",
		"ballista": "🏹 Баллиста",
		"barracks": "⚔️ Казармы"
	}
	for type in costs:
		_update_button(type, labels.get(type, type), costs[type])