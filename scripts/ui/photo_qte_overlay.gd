extends CanvasLayer

@onready var tease_photo: TextureRect = $TeasePhoto
@onready var qte_panel: VBoxContainer = $QtePanel
@onready var snap_button: Button = $QtePanel/SnapButton
@onready var timer_bar: ProgressBar = $QtePanel/TimerBar
@onready var reveal_panel: Control = $RevealPanel
@onready var reveal_photo: TextureRect = $RevealPanel/CenterBox/RevealPhoto
@onready var close_button: Button = $RevealPanel/CenterBox/CloseButton

signal photo_result(success: bool)

var _resolved: bool = false
var _tween: Tween


func _ready() -> void:
	add_to_group("photo_qte")
	snap_button.pressed.connect(_on_snap_pressed)


func show_opportunity(window_ms: float, portrait_path: String) -> bool:
	var texture: Texture2D = null
	if portrait_path != "":
		if ResourceLoader.exists(portrait_path):
			texture = load(portrait_path)
		else:
			push_warning("[PhotoQTE] Portrait not imported or missing: " + portrait_path)

	# Phase 1: tease flash (0.1 s)
	tease_photo.texture = texture
	tease_photo.visible = true
	await get_tree().create_timer(0.1).timeout
	tease_photo.visible = false

	# Phase 2: QTE
	_resolved = false
	qte_panel.visible = true
	timer_bar.max_value = window_ms
	timer_bar.value = window_ms
	_tween = create_tween()
	_tween.tween_property(timer_bar, "value", 0.0, window_ms / 1000.0)
	_tween.tween_callback(_on_timeout)
	var success: bool = await photo_result
	qte_panel.visible = false

	# Phase 3: expanded reveal on success
	if success and texture != null:
		reveal_photo.texture = texture
		reveal_panel.visible = true
		await close_button.pressed
		reveal_panel.visible = false

	return success


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
	photo_result.emit(success)
