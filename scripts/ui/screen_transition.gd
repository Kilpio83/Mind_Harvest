## ScreenTransition — full-screen fade-to-black autoload.
##
## API:
##   await ScreenTransition.fade_out(duration)   # fades to black, holds briefly
##   ScreenTransition.fade_in(duration)           # fades back — fire-and-forget ok
##
## Layer 99 — above everything except ToastLayer (100).
extends CanvasLayer

var _overlay: ColorRect


func _ready() -> void:
	layer = 99
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 0.0
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


## Fades to black over `duration` seconds, then holds for a brief beat.
## Caller should await this before switching timelines.
func fade_out(duration: float = 0.45) -> void:
	var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_overlay, "modulate:a", 1.0, duration)
	await tween.finished
	await get_tree().create_timer(0.15).timeout


## Fades from black over `duration` seconds.
## Safe to call fire-and-forget; does not need to be awaited.
func fade_in(duration: float = 0.5) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_overlay, "modulate:a", 0.0, duration)
	await tween.finished
