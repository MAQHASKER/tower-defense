extends Node3D

# Подключаем по пути, а не через class_name — см. комментарий в StageLoader.gd
const StageLoader := preload("res://scripts/StageLoader.gd")

const WAVE_INTERVAL := 15.0   # для теста 15 сек (в дизайне 30)
const PACK_INTERVAL := 2.0    # пауза между пачками внутри волны
const EARLY_START_BONUS := 25
# Пауза между досрочными стартами: без неё можно выкликать все волны разом
const EARLY_START_COOLDOWN := 3.0
# Радиус свободной зоны у начала пути, в клетках
const SPAWN_ZONE_CELLS := 2.0

var _waves: Array = []
var _time: float = 0.0
var _next_wave_index: int = 0
var _next_wave_time: float = 0.0
var _last_early_start: float = -999.0

var _total_enemies: int = 0
var _spawned_enemies: int = 0
var _all_spawned: bool = false

# Счётчики слотов внутри клетки, отдельно на каждый тип врага
var _slot_counters: Dictionary = {}

@onready var entities: Node3D = get_parent().get_node("Entities")

func _ready() -> void:
	_load_stage(GameManager.selected_stage)
	GameManager.reset()
	GameManager.total_waves = _waves.size()
	GameManager.wave_changed.emit(0, _waves.size())
	GameManager.wave_start_requested.connect(_on_wave_start_requested)
	_next_wave_time = 2.0   # первая волна через 2 сек

func _load_stage(stage_id: int) -> void:
	_waves = StageLoader.get_waves(stage_id)
	_total_enemies = 0
	if _waves.is_empty():
		push_error("Этап %d не найден или в нём нет волн" % stage_id)
		return
	for wave: Dictionary in _waves:
		for entry: Dictionary in wave.enemies:
			_total_enemies += int(entry.get("count", 0))

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

# Враги выходят пачками. Размер пачки = размер раскладки в клетке, поэтому
# группа сразу занимает клетку целиком: 9 гоблинов, 3 всадника, 2 огра.
# Внутри пачки враги появляются в одном кадре — иначе они растянутся
# по пути и группы не будет видно.
func _spawn_wave_async(wave: Dictionary) -> void:
	for entry: Dictionary in wave.enemies:
		var enemy_type: String = String(entry.get("type", "goblin"))
		var pack_size: int = int(max(1, Enemy.get_slot_count(enemy_type)))
		var remaining: int = int(entry.get("count", 1))
		while remaining > 0:
			# Ждём, пока начало пути освободится. Иначе новая пачка появится
			# ровно поверх предыдущей, коробки совпадут, и коллизия
			# заблокирует обе намертво — враги застрянут навсегда.
			await _wait_for_spawn_zone()
			var in_pack: int = int(min(pack_size, remaining))
			# счётчик слотов с нуля — пачка ложится ровным блоком
			_slot_counters[enemy_type] = 0
			for i in range(in_pack):
				_spawn_enemy(enemy_type)
			remaining -= in_pack
			if remaining > 0:
				await get_tree().create_timer(PACK_INTERVAL).timeout

# Зона у начала пути должна быть свободна перед появлением пачки
func _wait_for_spawn_zone() -> void:
	var cells: Array[Vector2i] = get_parent().path.cells
	if cells.is_empty():
		return
	var center := Constants.cell_to_world(cells[0])
	var radius := SPAWN_ZONE_CELLS * Constants.CELL_SIZE
	while _spawn_zone_busy(center, radius):
		await get_tree().create_timer(0.25).timeout

func _spawn_zone_busy(center: Vector3, radius: float) -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(center) < radius:
			return true
	return false

func _spawn_enemy(enemy_type: String) -> void:
	var enemy := Enemy.new()
	# Сначала в дерево: setup() замеряет модель врага по мировым координатам
	entities.add_child(enemy)
	enemy.setup(get_parent().path.cells, enemy_type, _take_slot(enemy_type))
	_spawned_enemies += 1

# Слоты внутри клетки раздаются по кругу для каждого типа врага
func _take_slot(enemy_type: String) -> int:
	var total: int = max(1, Enemy.get_slot_count(enemy_type))
	var slot: int = _slot_counters.get(enemy_type, 0)
	_slot_counters[enemy_type] = (slot + 1) % total
	return slot

func _check_victory() -> void:
	if GameManager.is_game_over:
		return
	var alive := get_tree().get_nodes_in_group("enemies").size()
	if alive == 0:
		GameManager.win_game()

func _on_wave_start_requested() -> void:
	if GameManager.is_game_over:
		return
	if _next_wave_index >= _waves.size():
		return   # все волны уже заспавнены
	if _time - _last_early_start < EARLY_START_COOLDOWN:
		return   # кнопку зажали — не выпускаем волны одна за другой
	_last_early_start = _time
	_start_wave(_next_wave_index)
	_next_wave_index += 1
	_next_wave_time = _time + WAVE_INTERVAL
	GameManager.add_gold(EARLY_START_BONUS)
