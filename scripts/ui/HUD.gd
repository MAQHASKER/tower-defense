extends CanvasLayer

var _gold_label: Label
var _wave_label: Label
var _hp_label: Label

func _ready() -> void:
    _build_ui()
    _connect_signals()

    # Показать начальные значения
    _gold_label.text = "💰 %d" % GameManager.gold
    _wave_label.text = "🌊 0 / %d" % GameManager.total_waves
    _hp_label.text = "❤️ %d / %d" % [GameManager.base_hp, GameManager.base_max_hp]

func _build_ui() -> void:
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
    panel.offset_bottom = 50
    add_child(panel)

    var hbox := HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 40)
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    panel.add_child(hbox)

    _gold_label = _make_label()
    _wave_label = _make_label()
    _hp_label = _make_label()

    hbox.add_child(_gold_label)
    hbox.add_child(_wave_label)
    hbox.add_child(_hp_label)

func _make_label() -> Label:
    var label := Label.new()
    label.add_theme_font_size_override("font_size", 22)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    return label

func _connect_signals() -> void:
    GameManager.gold_changed.connect(_on_gold_changed)
    GameManager.wave_changed.connect(_on_wave_changed)
    GameManager.base_hp_changed.connect(_on_hp_changed)

func _on_gold_changed(new_gold: int) -> void:
    _gold_label.text = "💰 %d" % new_gold

func _on_wave_changed(current: int, total: int) -> void:
    _wave_label.text = "🌊 %d / %d" % [current, total]

func _on_hp_changed(new_hp: float, max_hp: float) -> void:
    _hp_label.text = "❤️ %d / %d" % [new_hp, max_hp]
