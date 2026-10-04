extends CanvasLayer

signal upgrade_pressed
signal sell_pressed

var _panel: PanelContainer
var _title: Label
var _stats: Label
var _upgrade_btn: Button
var _sell_btn: Button

var _current: Node3D = null

func _ready() -> void:
	_build_ui()
	_panel.visible = false

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -260
	_panel.offset_right = -20
	_panel.offset_top = 80
	_panel.offset_bottom = 320
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_title)

	_stats = Label.new()
	_stats.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_stats)

	_upgrade_btn = Button.new()
	_upgrade_btn.pressed.connect(func(): upgrade_pressed.emit())
	vbox.add_child(_upgrade_btn)

	_sell_btn = Button.new()
	_sell_btn.pressed.connect(func(): sell_pressed.emit())
	vbox.add_child(_sell_btn)

func show_for(tower: Node3D) -> void:
	_current = tower
	_refresh()
	_panel.visible = true

func hide_panel() -> void:
	_current = null
	_panel.visible = false

func _refresh() -> void:
	if not is_instance_valid(_current):
		hide_panel()
		return

	_title.text = _current.get_display_name()
	_stats.text = _current.get_stats_text()

	var up_cost: int = _current.get_upgrade_cost()
	if up_cost > 0:
		_upgrade_btn.text = "Улучшить (💰 %d)" % up_cost
		_upgrade_btn.disabled = false
	else:
		_upgrade_btn.text = "Макс. уровень"
		_upgrade_btn.disabled = true

	_sell_btn.text = "Продать (💰 %d)" % _current.get_sell_value()

func refresh() -> void:
	_refresh()

func _process(_delta: float) -> void:
	if _current and not is_instance_valid(_current):
		hide_panel()