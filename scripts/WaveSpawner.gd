extends Node3D

const WAVE_INTERVAL := 15.0   # для теста 15 сек (в дизайне 30)
const SPAWN_INTERVAL := 0.8   # задержка между врагами внутри волны

var _waves: Array = []
var _time: float = 0.0
var _next_wave_index: int = 0
var _next_wave_time: float = 0.0

var _total_enemies: int = 0
var _spawned_enemies: int = 0
var _all_spawned: bool = false

@onready var entities: Node3D = get_parent().get_node("Entities")

func _ready() -> void:
	_load_stage(1)
	GameManager.reset()
	GameManager.total_waves = _waves.size()
	GameManager.wave_changed.emit(0, _waves.size())
	_next_wave_time = 2.0   # первая волна через 2 сек

func _load_stage(stage_id: int) -> void:
	var file := FileAccess.open("res://data/stages.json", FileAccess.READ)
	if not file:
		push_error("Не могу открыть stages.json")
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	for stage in data.stages:
		if stage.id == stage_id:
			_waves = stage.waves
			for wave in _waves:
				for entry in wave.enemies:
					_total_enemies += entry.count
			return

func _process(delta: float) -> void:
	_time += delta

	if not _all_spawned and _next_wave_index < _waves.size():
		if _time >= _next_wave_time:
			_start_wave(_next_wave_index)
			_next_wave_index += 1
			_next_wave_time = _time + WAVE_INTERVAL

	if _spawned_enemies >= _total_enemies and _total_enemies > 0:
		_all_spawned = true
		_check_victory()

func _start_wave(index: int) -> void:
	GameManager.next_wave()
	_spawn_wave_async(_waves[index])

func _spawn_wave_async(wave: Dictionary) -> void:
	for entry in wave.enemies:
		for i in range(entry.count):
			_spawn_enemy(entry.type)
			await get_tree().create_timer(SPAWN_INTERVAL).timeout

func _spawn_enemy(_type: String) -> void:
	var enemy := Enemy.new()
	enemy.setup(get_parent().path.cells)   # ← берём path здесь
	entities.add_child(enemy)
	_spawned_enemies += 1

func _check_victory() -> void:
	if GameManager.is_game_over:
		return
	var alive := get_tree().get_nodes_in_group("enemies").size()
	print("Живых врагов: ", alive, " / заспавнено: ", _spawned_enemies, " / всего: ", _total_enemies)
	if alive == 0:
		GameManager.win_game()
