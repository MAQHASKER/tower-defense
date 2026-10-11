extends Control

# Главное меню: Начать игру / Настройки (заглушка) / Выход

const STAGE_SELECT_SCENE := "res://scenes/StageSelect.tscn"

const COLOR_BG := Color(0.08, 0.09, 0.12)
const COLOR_ACCENT := Color(0.95, 0.82, 0.35)
const COLOR_MUTED := Color(0.6, 0.62, 0.7)

var _settings_overlay: Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "TOWER DEFENSE"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "прототип"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", COLOR_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)

	vbox.add_child(_make_button("▶  Начать игру", _on_start_game))
	vbox.add_child(_make_button("⚙  Настройки", _on_settings))
	vbox.add_child(_make_button("✕  Выход", _on_exit))

	_build_settings_overlay()

func _make_button(text: String, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 56)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(handler)
	return btn

func _on_start_game() -> void:
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)

func _on_exit() -> void:
	get_tree().quit()

# --- Настройки (заглушка) ---

func _on_settings() -> void:
	_settings_overlay.visible = true

func _build_settings_overlay() -> void:
	_settings_overlay = Control.new()
	_settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.visible = false
	add_child(_settings_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Настройки"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var note := Label.new()
	note.text = "В разработке"
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", COLOR_MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(note)

	var back := Button.new()
	back.text = "Назад"
	back.custom_minimum_size = Vector2(240, 48)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(func() -> void: _settings_overlay.visible = false)
	vbox.add_child(back)
