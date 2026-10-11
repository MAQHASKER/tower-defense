extends CanvasLayer

signal tower_selected(tower_type: String)
signal start_wave_pressed

const WAVE_BUTTON_TEXT := "▶ Начать волну"

var _buttons: Dictionary = {}
var _wave_btn: Button
var _cooldown_left: float = 0.0

func _ready() -> void:
	_build_ui()

# Кнопка «Начать волну» гаснет на время кулдауна и показывает отсчёт,
# иначе непонятно, почему нажатие ничего не делает
func _process(delta: float) -> void:
	if _cooldown_left <= 0.0:
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_refresh_wave_button()

func _refresh_wave_button() -> void:
	if _cooldown_left > 0.0:
		_wave_btn.disabled = true
		_wave_btn.text = "%s  (%.1f с)" % [WAVE_BUTTON_TEXT, _cooldown_left]
	else:
		_wave_btn.disabled = false
		_wave_btn.text = WAVE_BUTTON_TEXT

func _on_wave_pressed() -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = Constants.EARLY_START_COOLDOWN
	_refresh_wave_button()
	start_wave_pressed.emit()

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

	_wave_btn = Button.new()
	_wave_btn.text = WAVE_BUTTON_TEXT
	_wave_btn.custom_minimum_size = Vector2(200, 60)
	_wave_btn.add_theme_font_size_override("font_size", 18)
	_wave_btn.pressed.connect(_on_wave_pressed)
	hbox.add_child(_wave_btn)

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