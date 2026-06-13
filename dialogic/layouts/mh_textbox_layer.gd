## MH_TextboxLayer — Mind Harvest dialogue panel.
## Disables the textbox scrollbar and implements text paging for overflow.
@tool
extends "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Textbox/vn_textbox_layer.gd"

var _page_queue: Array[String] = []
var _dialog_text: DialogicNode_DialogText
var _generation := 0


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	_dialog_text = %DialogicNode_DialogText
	_dialog_text.scroll_active = false
	var diag := DialogicUtil.autoload()
	diag.Text.about_to_show_text.connect(_on_about_to_show_text)
	diag.Inputs.dialogic_action_priority.connect(_on_action_priority)


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
	var next := _page_queue.pop_front()
	if not _dialog_text.started_revealing_text.is_connected(_check_overflow):
		_dialog_text.started_revealing_text.connect(_check_overflow, CONNECT_ONE_SHOT)
	_dialog_text.finished_revealing_text.connect(_show_next_indicators_after_page, CONNECT_ONE_SHOT)
	_dialog_text.reveal_text(next, false)
	diag.Inputs.action_was_consumed = true


func _show_next_indicators_after_page() -> void:
	DialogicUtil.autoload().Text.show_next_indicators()
