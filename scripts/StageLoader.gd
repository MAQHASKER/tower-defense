extends RefCounted

# Единая точка чтения этапов из data/stages.json.
# Используется меню (список этапов), WaveSpawner (волны) и Main (путь).

const STAGES_PATH := "res://data/stages.json"

static var _stages: Array = []
static var _loaded: bool = false

static func load_all() -> Array:
	if not _loaded:
		_loaded = true
		var file := FileAccess.open(STAGES_PATH, FileAccess.READ)
		if not file:
			push_error("Не могу открыть %s" % STAGES_PATH)
			return _stages
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("stages"):
			_stages = parsed["stages"]
		else:
			push_error("%s: нет секции \"stages\"" % STAGES_PATH)
	return _stages

static func get_stage(stage_id: int) -> Dictionary:
	for stage in load_all():
		if typeof(stage) == TYPE_DICTIONARY and int(stage.get("id", -1)) == stage_id:
			return stage
	return {}

static func get_name(stage_id: int) -> String:
	var stage := get_stage(stage_id)
	return String(stage.get("name", "Этап %d" % stage_id))

static func get_waves(stage_id: int) -> Array:
	return get_stage(stage_id).get("waves", [])

static func get_path_corners(stage_id: int) -> Array:
	return get_stage(stage_id).get("path", [])
