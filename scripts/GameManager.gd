extends Node

# Сигналы — на них подписывается UI
signal gold_changed(new_gold: int)
signal wave_changed(current: int, total: int)
signal base_hp_changed(new_hp: float, max_hp: float)
signal game_over()
signal game_won()

# Состояние
var gold: int = 200
var base_hp: float = 1000.0
var base_max_hp: float = 1000.0
var current_wave: int = 0
var total_waves: int = 3
var is_game_over: bool = false

func reset() -> void:
    gold = 200
    base_hp = base_max_hp
    current_wave = 0
    is_game_over = false
    gold_changed.emit(gold)
    wave_changed.emit(current_wave, total_waves)
    base_hp_changed.emit(base_hp, base_max_hp)

func add_gold(amount: int) -> void:
    gold += amount
    gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
    if gold < amount:
        return false
    gold -= amount
    gold_changed.emit(gold)
    return true

func damage_base(amount: float) -> void:
    if is_game_over:
        return
    base_hp -= amount
    if base_hp < 0:
        base_hp = 0
    base_hp_changed.emit(base_hp, base_max_hp)
    if base_hp <= 0:
        is_game_over = true
        game_over.emit()

func next_wave() -> void:
    current_wave += 1
    wave_changed.emit(current_wave, total_waves)

func win_game() -> void:
    if is_game_over:
        return
    is_game_over = true
    game_won.emit()