extends Node
## Manages display preferences (fullscreen toggle).
## Preferences persist across sessions in user://settings.cfg.

const _CONFIG_PATH := "user://settings.cfg"
const _SECTION      := "display"


func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(1280, 720))
	_apply_saved()


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func toggle_fullscreen() -> void:
	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_center_window()
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_save()


func _apply_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_CONFIG_PATH) != OK:
		# First launch — start at 1280×720 centered
		DisplayServer.window_set_size(Vector2i(1280, 720))
		_center_window()
		return
	if cfg.get_value(_SECTION, "fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_center_window()


func _center_window() -> void:
	var screen := DisplayServer.screen_get_size()
	var win    := DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen - win) / 2)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(_SECTION, "fullscreen", is_fullscreen())
	cfg.save(_CONFIG_PATH)
