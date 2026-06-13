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
var _ctrl_row: HBoxContainer
var _sync_t    := 0.0
var _auto_state: int  = 0   # 0=off  1=normal  2=fast
var _base_fixed_delay: float    = 1.0
var _base_delay_modifier: float = 1.0


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	_dialog_text = %DialogicNode_DialogText
	_dialog_text.scroll_active = false
	var diag := DialogicUtil.autoload()
	diag.Text.about_to_show_text.connect(_on_about_to_show_text)
	diag.Inputs.dialogic_action_priority.connect(_on_action_priority)
	_base_fixed_delay    = diag.Inputs.auto_advance.fixed_delay
	_base_delay_modifier = diag.Inputs.auto_advance.delay_modifier
	_build_controls()


func _build_controls() -> void:
	var panel := %DialogTextPanel
	var font: Font = null
	if ResourceLoader.exists("res://assets/fonts/Mulish-SemiBold.ttf"):
		font = load("res://assets/fonts/Mulish-SemiBold.ttf")

	_ctrl_row = HBoxContainer.new()
	_ctrl_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	_ctrl_row.size_flags_vertical   = Control.SIZE_SHRINK_END
	_ctrl_row.add_theme_constant_override("separation", 8)
	panel.add_child(_ctrl_row)
	var row := _ctrl_row

	var history_btn := _make_btn("History", false, font)
	history_btn.pressed.connect(_on_history_pressed)
	row.add_child(history_btn)

	row.add_child(_make_sep())

	_auto_btn = _make_btn("Auto", false, font)
	_auto_btn.pressed.connect(_on_auto_pressed)
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
	if not Dialogic.Inputs:
		return
	# If Dialogic cancelled auto-advance externally, reset to Off
	if _auto_state != 0 and not Dialogic.Inputs.auto_advance.enabled_until_user_input:
		_auto_state = 0
		_update_auto_btn()
	_skip_btn.set_pressed_no_signal(Dialogic.Inputs.auto_skip.enabled)


func _on_history_pressed() -> void:
	if Dialogic.current_timeline and Dialogic.get(&"History"):
		Dialogic.History.open_requested.emit()


func _on_auto_pressed() -> void:
	if not Dialogic.current_timeline or not Dialogic.Inputs:
		return
	_auto_state = (_auto_state + 1) % 3
	_apply_auto_state()


func _apply_auto_state() -> void:
	var aa := Dialogic.Inputs.auto_advance
	match _auto_state:
		0:
			aa.enabled_until_user_input = false
		1:
			aa.fixed_delay    = _base_fixed_delay
			aa.delay_modifier = _base_delay_modifier
			aa.enabled_until_user_input = true
			aa.autoadvance_timer.stop()
			aa.start()
		2:
			aa.fixed_delay    = _base_fixed_delay * 0.5
			aa.delay_modifier = _base_delay_modifier * 0.5
			aa.enabled_until_user_input = true
			aa.autoadvance_timer.stop()
			aa.start()
	_update_auto_btn()


func _update_auto_btn() -> void:
	match _auto_state:
		0:
			_auto_btn.text = "Auto"
			_auto_btn.add_theme_color_override("font_color", Color(0.953, 0.933, 0.890, 0.55))
		1:
			_auto_btn.text = "Auto 1"
			_auto_btn.add_theme_color_override("font_color", Color(0.886, 0.639, 0.243, 1.0))
		2:
			_auto_btn.text = "Auto 2"
			_auto_btn.add_theme_color_override("font_color", Color(0.886, 0.639, 0.243, 1.0))


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

	# get_combined_minimum_size gives the actual button height, not the container fill height
	var row_h    := maxf(_ctrl_row.get_combined_minimum_size().y if is_instance_valid(_ctrl_row) else 0.0, 20.0)
	var usable_h := _dialog_text.size.y - row_h

	if _dialog_text.get_content_height() <= usable_h + 2:
		return

	# Count lines whose top starts within the usable area (buttons float on top so
	# the bottom of the last line may overlap them slightly — that's acceptable)
	var line_count    := _dialog_text.get_line_count()
	var visible_lines := 0
	for i in range(line_count):
		var line_top := _dialog_text.get_line_offset(i)
		if line_top < usable_h:
			visible_lines += 1
		else:
			break

	if visible_lines <= 0:
		return
	# All lines start in the usable area — last line may overlap buttons slightly, skip paging
	if visible_lines >= line_count:
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
	_dialog_text.text = raw.substr(0, cutoff).rstrip(" ") + " ..."
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
