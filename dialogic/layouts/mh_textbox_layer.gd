## MH_TextboxLayer — Mind Harvest dialogue panel.
## Disables scrollbar; implements text paging for overflow.
## Adds History / Auto-advance / Auto-Skip controls in the bottom-right corner.
@tool
extends "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Textbox/vn_textbox_layer.gd"

var _page_queue: Array[String] = []
var _dialog_text: DialogicNode_DialogText
var _generation := 0

var _auto_btn: Button
var _skip_btn: Button
var _sync_t   := 0.0


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	_dialog_text = %DialogicNode_DialogText
	_dialog_text.scroll_active = false
	var diag := DialogicUtil.autoload()
	diag.Text.about_to_show_text.connect(_on_about_to_show_text)
	diag.Inputs.dialogic_action_priority.connect(_on_action_priority)
	_build_controls()


func _build_controls() -> void:
	var panel := %DialogTextPanel
	var font: Font = null
	if ResourceLoader.exists("res://assets/fonts/Mulish-SemiBold.ttf"):
		font = load("res://assets/fonts/Mulish-SemiBold.ttf")

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.size_flags_vertical   = Control.SIZE_SHRINK_END
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var history_btn := _make_btn("History", false, font)
	history_btn.pressed.connect(_on_history_pressed)
	row.add_child(history_btn)

	row.add_child(_make_sep())

	_auto_btn = _make_btn("Auto", true, font)
	_auto_btn.toggled.connect(_on_auto_toggled)
	row.add_child(_auto_btn)

	row.add_child(_make_sep())

	_skip_btn = _make_btn("Skip", true, font)
	_skip_btn.toggled.connect(_on_skip_toggled)
	row.add_child(_skip_btn)

	# Right spacer: keeps buttons clear of the NextIndicator triangle
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(30, 1)
	row.add_child(spacer)


func _make_btn(label_text: String, toggle: bool, font: Font) -> Button:
	var btn := Button.new()
	btn.text        = label_text
	btn.flat        = true
	btn.toggle_mode = toggle
	btn.add_theme_font_size_override("font_size", 12)
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_color_override("font_color",         Color(0.953, 0.933, 0.890, 0.55))
	btn.add_theme_color_override("font_hover_color",   Color(0.886, 0.639, 0.243, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.886, 0.639, 0.243, 1.0))
	btn.add_theme_color_override("font_focus_color",   Color(0.953, 0.933, 0.890, 0.55))
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal",   empty)
	btn.add_theme_stylebox_override("pressed",  empty)
	btn.add_theme_stylebox_override("hover",    empty)
	btn.add_theme_stylebox_override("focus",    empty)
	btn.add_theme_stylebox_override("disabled", empty)
	return btn


func _make_sep() -> Label:
	var sep := Label.new()
	sep.text = "·"
	sep.add_theme_color_override("font_color", Color(0.953, 0.933, 0.890, 0.25))
	sep.add_theme_font_size_override("font_size", 11)
	sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return sep


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not is_instance_valid(_auto_btn):
		return
	_sync_t += delta
	if _sync_t < 0.25:
		return
	_sync_t = 0.0
	if Dialogic.Inputs:
		_auto_btn.set_pressed_no_signal(Dialogic.Inputs.auto_advance.enabled_until_user_input)
		_skip_btn.set_pressed_no_signal(Dialogic.Inputs.auto_skip.enabled)


func _on_history_pressed() -> void:
	if Dialogic.current_timeline and Dialogic.get(&"History"):
		Dialogic.History.open_requested.emit()


func _on_auto_toggled(pressed: bool) -> void:
	if Dialogic.current_timeline and Dialogic.Inputs:
		Dialogic.Inputs.auto_advance.enabled_until_user_input = pressed


func _on_skip_toggled(pressed: bool) -> void:
	if Dialogic.current_timeline and Dialogic.Inputs:
		Dialogic.Inputs.auto_skip.enabled = pressed


# ── Paging ─────────────────────────────────────────────────────────────────────

func _on_about_to_show_text(_info: Dictionary) -> void:
	_page_queue.clear()
	_generation += 1
	if not _dialog_text.started_revealing_text.is_connected(_check_overflow):
		_dialog_text.started_revealing_text.connect(_check_overflow, CONNECT_ONE_SHOT)


func _check_overflow() -> void:
	var gen := _generation
	await get_tree().process_frame
	await get_tree().process_frame
	if gen != _generation or not _dialog_text.revealing:
		return
	if _dialog_text.get_content_height() <= _dialog_text.size.y + 2:
		return

	var visible_lines := _dialog_text.get_visible_line_count()
	if visible_lines <= 0:
		return

	var parsed := _dialog_text.get_parsed_text()
	var cutoff := len(parsed)
	for i in range(len(parsed)):
		if _dialog_text.get_character_line(i) >= visible_lines:
			cutoff = i
			break

	while cutoff > 0 and parsed[cutoff - 1] != " ":
		cutoff -= 1
	if cutoff <= 0:
		return

	var raw := _dialog_text.text
	_page_queue.push_back(raw.substr(cutoff).lstrip(" "))
	_dialog_text.revealing = false
	_dialog_text.text = raw.substr(0, cutoff).rstrip(" ")
	_dialog_text.finish_text(true)


func _on_action_priority() -> void:
	if _page_queue.is_empty():
		return
	var diag := DialogicUtil.autoload()
	diag.Text.hide_next_indicators()
	var next: String = _page_queue.pop_front()
	if not _dialog_text.started_revealing_text.is_connected(_check_overflow):
		_dialog_text.started_revealing_text.connect(_check_overflow, CONNECT_ONE_SHOT)
	_dialog_text.finished_revealing_text.connect(_show_next_indicators_after_page, CONNECT_ONE_SHOT)
	_dialog_text.reveal_text(next, false)
	diag.Inputs.action_was_consumed = true


func _show_next_indicators_after_page() -> void:
	DialogicUtil.autoload().Text.show_next_indicators()
