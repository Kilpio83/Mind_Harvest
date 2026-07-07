@tool
extends DialogicPortrait

## Universal breathing portrait — drop-in replacement for Dialogic's default portrait.
## Reads the image path from the character's export_overrides and drives the breathing shader.
## Reuses the same scene instance across expression changes to avoid GPU re-initialization flash.

@export_file var image := ""

var _breath_time := 0.0
var _portrait_tween: Tween = null


func _should_do_portrait_update(_character: DialogicCharacter, _portrait: String) -> bool:
	return true


func _update_portrait(passed_character: DialogicCharacter, passed_portrait: String) -> void:
	apply_character_and_portrait(passed_character, passed_portrait)
	if $Portrait.texture == null:
		apply_texture($Portrait, image)
		$Portrait.self_modulate.a = 1.0
	else:
		_crossfade_to_new_image()


func _crossfade_to_new_image() -> void:
	if _portrait_tween:
		_portrait_tween.kill()
	_portrait_tween = create_tween()
	_portrait_tween.tween_property($Portrait, "self_modulate:a", 0.0, 0.15)
	_portrait_tween.tween_callback(func(): apply_texture($Portrait, image))
	_portrait_tween.tween_property($Portrait, "self_modulate:a", 1.0, 0.15)
	_portrait_tween.tween_callback(func(): _portrait_tween = null)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not $Portrait.texture:
		return
	_breath_time += delta
	$Portrait.material.set_shader_parameter("breath", sin(_breath_time * TAU / 3.6))
