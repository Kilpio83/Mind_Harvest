extends Node
## Manages display preferences (window mode).
## Persists across sessions in user://settings.cfg.

const _CONFIG_PATH := "user://settings.cfg"
const _SECTION      := "display"

enum WindowMode { WINDOWED = 0, FULLSCREEN = 1, FRAMELESS = 2 }
const WINDOW_LABELS := ["Window", "Fullscreen", "Frameless"]


func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(1280, 720))
	_apply_saved()


func get_window_mode() -> int:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return WindowMode.FULLSCREEN
	if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
		return WindowMode.FRAMELESS
	return WindowMode.WINDOWED


func set_window_mode(mode: int) -> void:
	match mode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.FRAMELESS:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			_center_window()
		_:  # WINDOWED
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_center_window()
	_save()


func is_fullscreen() -> bool:
	return get_window_mode() == WindowMode.FULLSCREEN


func toggle_fullscreen() -> void:
	set_window_mode(WindowMode.WINDOWED if is_fullscreen() else WindowMode.FULLSCREEN)


func _apply_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_CONFIG_PATH) != OK:
		DisplayServer.window_set_size(Vector2i(1280, 720))
		_center_window()
		return
	# Migrate legacy boolean "fullscreen" key
	if cfg.has_section_key(_SECTION, "fullscreen"):
		set_window_mode(WindowMode.FULLSCREEN if cfg.get_value(_SECTION, "fullscreen", false) else WindowMode.WINDOWED)
		return
	set_window_mode(cfg.get_value(_SECTION, "window_mode", WindowMode.WINDOWED))


func _center_window() -> void:
	var screen := DisplayServer.screen_get_size()
	var win    := DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen - win) / 2)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(_CONFIG_PATH)
	cfg.set_value(_SECTION, "window_mode", get_window_mode())
	cfg.erase_section_key(_SECTION, "fullscreen")
	cfg.save(_CONFIG_PATH)
