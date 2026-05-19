extends CanvasLayer

@onready var snap_button: Button = $Panel/SnapButton
@onready var timer_bar: ProgressBar = $Panel/TimerBar

signal photo_result(success: bool)

var _resolved: bool = false
var _tween: Tween


func _ready() -> void:
	add_to_group("photo_qte")
	visible = false
	snap_button.pressed.connect(_on_snap_pressed)


func show_opportunity(window_ms: float) -> bool:
	_resolved = false
	visible = true
	timer_bar.max_value = window_ms
	timer_bar.value = window_ms
	_tween = create_tween()
	_tween.tween_property(timer_bar, "value", 0.0, window_ms / 1000.0)
	_tween.tween_callback(_on_timeout)
	return await photo_result


func _on_snap_pressed() -> void:
	_resolve(true)


func _on_timeout() -> void:
	_resolve(false)


func _resolve(success: bool) -> void:
	if _resolved:
		return
	_resolved = true
	if _tween:
		_tween.kill()
	visible = false
	photo_result.emit(success)
