extends Control

# Подключаем по пути, а не через class_name: так работает и до пересканирования
# проекта редактором (кэш глобальных классов обновляет только редактор).
const StageLoader := preload("res://scripts/StageLoader.gd")

# Выбор этапа. Список берётся из stages.json — новый этап не требует правок кода.

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const GAME_SCENE := "res://scenes/Main.tscn"

const COLOR_BG := Color(0.08, 0.09, 0.12)
const COLOR_ACCENT := Color(0.95, 0.82, 0.35)
const COLOR_MUTED := Color(0.6, 0.62, 0.7)

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
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Выбор этапа"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_spacer(24))

	var stages := StageLoader.load_all()
	if stages.is_empty():
		var empty := Label.new()
		empty.text = "Этапы не найдены"
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", COLOR_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty)
	else:
		for stage in stages:
			if typeof(stage) != TYPE_DICTIONARY:
				continue
			var id := int(stage.get("id", 0))
			var stage_name := String(stage.get("name", "Этап %d" % id))
			var btn := Button.new()
			btn.text = "Этап %d — %s" % [id, stage_name]
			btn.custom_minimum_size = Vector2(360, 56)
			btn.add_theme_font_size_override("font_size", 20)
			btn.pressed.connect(_on_stage_pressed.bind(id))
			vbox.add_child(btn)

	vbox.add_child(_make_spacer(24))

	var back := Button.new()
	back.text = "←  Назад"
	back.custom_minimum_size = Vector2(360, 48)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(_on_back)
	vbox.add_child(back)

func _make_spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func _on_stage_pressed(stage_id: int) -> void:
	GameManager.selected_stage = stage_id
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
