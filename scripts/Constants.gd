class_name Constants
extends RefCounted

const CELL_SIZE := 3.0
const MAP_WIDTH := 24
const MAP_HEIGHT := 24

# Модели из Blender. Пока выключены — вместо них рисуются кубы-заглушки.
# Поставь true, чтобы вернуть модель башни лучника и гоблина.
const USE_MODELS := false

# Пауза между досрочными стартами волн. Лежит здесь, а не в WaveSpawner,
# потому что кнопка «Начать волну» показывает этот же кулдаун
const EARLY_START_COOLDOWN := 3.0

const COLOR_GROUND := Color(0.3, 0.5, 0.3)
const COLOR_PATH   := Color(0.6, 0.5, 0.4)
const COLOR_TOWER  := Color(0.4, 0.4, 0.8)
const COLOR_ENEMY  := Color(0.8, 0.3, 0.3)
const COLOR_BASE   := Color(0.9, 0.8, 0.3)

static func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(
		(cell.x + 0.5) * CELL_SIZE,
		0.0,
		(cell.y + 0.5) * CELL_SIZE
	)

# Центр карты в мировых координатах — вокруг него вращается камера.
static func map_center() -> Vector3:
	return Vector3(
		MAP_WIDTH * CELL_SIZE / 2.0,
		0.0,
		MAP_HEIGHT * CELL_SIZE / 2.0
	)

# Центральная клетка карты.
static func center_cell() -> Vector2i:
	return Vector2i(
		int(MAP_WIDTH / 2.0),
		int(MAP_HEIGHT / 2.0)
	)
