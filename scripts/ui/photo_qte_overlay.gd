extends CanvasLayer

@onready var tease_photo: TextureRect = $TeasePhoto
@onready var qte_panel: VBoxContainer = $QtePanel
@onready var snap_button: Button = $QtePanel/SnapButton
@onready var timer_bar: ProgressBar = $QtePanel/TimerBar
@onready var reveal_panel: Control = $RevealPanel
@onready var reveal_photo: TextureRect = $RevealPanel/RevealPhoto
@onready var close_button: Button = $RevealPanel/CloseButton

signal photo_result(success: bool)

var _resolved: bool = false
var _tween: Tween


func _ready() -> void:
	add_to_group("photo_qte")
	snap_button.pressed.connect(_on_snap_pressed)


func _region_texture(base: Texture2D, region: Rect2) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = base
	at.region = region
	return at


func show_opportunity(window_ms: float, portrait_path: String) -> bool:
	var texture: Texture2D = null
	if portrait_path != "":
		if ResourceLoader.exists(portrait_path):
			texture = load(portrait_path)
		else:
			push_warning("[PhotoQTE] Portrait not imported or missing: " + portrait_path)

	# Phase 1: 3 flashes, each showing a different zoomed region
	if texture != null:
		var s := texture.get_size()
		var crop_h := s.y * 0.4
		var regions := [
			Rect2(0, s.y * 0.6, s.x, crop_h),  # flash 1 — bottom
			Rect2(0, 0,         s.x, crop_h),   # flash 2 — top
			Rect2(0, s.y * 0.3, s.x, crop_h),  # flash 3 — center
		]
		var durations := [[0.04, 0.04], [0.06, 0.04], [0.08, 0.2]]

		tease_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tease_photo.visible = true
		for i in 3:
			tease_photo.texture = _region_texture(texture, regions[i])
			tease_photo.modulate.a = 0.0
			var flash := create_tween()
			flash.tween_property(tease_photo, "modulate:a", 1.0, durations[i][0])
			flash.tween_property(tease_photo, "modulate:a", 0.0, durations[i][1])
			await flash.finished
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
