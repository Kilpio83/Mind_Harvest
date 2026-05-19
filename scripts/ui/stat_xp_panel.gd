extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var stat_label: Label = $Panel/VBox/StatLabel
@onready var bar: ProgressBar = $Panel/VBox/Bar
@onready var level_label: Label = $Panel/VBox/LevelLabel

var _tween: Tween


func _ready() -> void:
	panel.modulate.a = 0.0
	GameState.stat_xp_changed.connect(_on_xp_changed)


func _on_xp_changed(stat: String, old_xp: int, new_xp: int, old_stat: int, new_stat: int) -> void:
	if _tween:
		_tween.kill()
	stat_label.text = stat.capitalize()
	level_label.text = "Lv %d" % new_stat
	bar.max_value = 10.0
	bar.value = float(old_xp)
	_tween = create_tween().set_parallel(false)
	_tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	if new_stat > old_stat:
		_tween.tween_property(bar, "value", 10.0, 0.6)
		_tween.tween_interval(0.15)
		_tween.tween_property(bar, "value", float(new_xp), 0.3)
		_tween.tween_property(level_label, "modulate", Color.YELLOW, 0.1)
		_tween.tween_property(level_label, "modulate", Color.WHITE, 0.3)
	else:
		_tween.tween_property(bar, "value", float(new_xp), 0.6)
	_tween.tween_interval(1.2)
	_tween.tween_property(panel, "modulate:a", 0.0, 0.3)
