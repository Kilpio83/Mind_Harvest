extends CanvasLayer

@onready var slots_container: VBoxContainer = $Panel/VBox/SlotsContainer
@onready var close_button: Button = $Panel/VBox/CloseButton

var _name_dialog: PanelContainer
var _name_input: LineEdit
var _pending_slot: String = ""


func _ready() -> void:
	add_to_group("save_menu")
	close_button.add_theme_font_size_override("font_size", MHTokens.FONT_BODY)
	close_button.pressed.connect(queue_free)
	_build_name_dialog()
	_build_slots()
	_build_display_section()


func _build_name_dialog() -> void:
	_name_dialog = PanelContainer.new()
	_name_dialog.anchor_left = 0.5
	_name_dialog.anchor_top = 0.5
	_name_dialog.anchor_right = 0.5
	_name_dialog.anchor_bottom = 0.5
	_name_dialog.offset_left = -155.0
	_name_dialog.offset_top = -70.0
	_name_dialog.offset_right = 155.0
	_name_dialog.offset_bottom = 70.0
	_name_dialog.grow_horizontal = 2
	_name_dialog.grow_vertical = 2
	_name_dialog.visible = false
	add_child(_name_dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_name_dialog.add_child(vbox)

	var prompt := Label.new()
	prompt.text = "Save name:"
	prompt.add_theme_font_size_override("font_size", MHTokens.FONT_BODY)
	vbox.add_child(prompt)

	_name_input = LineEdit.new()
	_name_input.max_length = 32
	_name_input.add_theme_font_size_override("font_size", MHTokens.FONT_BODY)
	_name_input.text_submitted.connect(_on_name_confirmed)
	vbox.add_child(_name_input)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	btn_row.add_child(_btn("Save",   func(): _on_name_confirmed(_name_input.text)))
	btn_row.add_child(_btn("Cancel", func(): _name_dialog.hide()))


func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	# Autosave row (load-only)
	var auto_info := SaveManager.get_slot_info(SaveManager.AUTOSAVE_SLOT)
	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 12)
	slots_container.add_child(auto_row)

	auto_row.add_child(_lbl(
		"Autosave  —  Day %d  —  %s" % [auto_info["day"], auto_info["date"]]
		if not auto_info.is_empty() else "Autosave  —  No save yet"
	))

	if not auto_info.is_empty():
		auto_row.add_child(_btn("Load", _on_load.bind(SaveManager.AUTOSAVE_SLOT)))

	slots_container.add_child(HSeparator.new())

	# Manual slots sorted newest-first, empty at bottom
	for entry in SaveManager.get_manual_slots_sorted():
		_add_slot_row(entry)


func _add_slot_row(entry: Dictionary) -> void:
	var slot_name: String = entry.get("slot", "")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	slots_container.add_child(row)

	if entry.has("day"):
		var display: String = entry["name"] if entry["name"] != "" else slot_name
		row.add_child(_lbl("%s  —  Day %d  —  %s" % [display, entry["day"], entry["date"]]))
		row.add_child(_btn("Load",      _on_load.bind(slot_name)))
		row.add_child(_btn("Overwrite", _show_name_dialog.bind(slot_name, entry["name"])))
	else:
		row.add_child(_lbl("— Empty —"))
		row.add_child(_btn("Save Here", _show_name_dialog.bind(slot_name, "")))


func _build_display_section() -> void:
	var vbox: VBoxContainer = slots_container.get_parent()

	var sep := HSeparator.new()
	vbox.add_child(sep)
	vbox.move_child(sep, close_button.get_index())

	var btn := _btn("", func() -> void: pass)
	btn.text = "Fullscreen" if not SettingsManager.is_fullscreen() else "Windowed"
	btn.pressed.connect(func() -> void:
		SettingsManager.toggle_fullscreen()
		btn.text = "Fullscreen" if not SettingsManager.is_fullscreen() else "Windowed")
	vbox.add_child(btn)
	vbox.move_child(btn, close_button.get_index())


func _show_name_dialog(slot_name: String, default_name: String) -> void:
	_pending_slot = slot_name
	var day: int = int(Dialogic.VAR.get_variable("game.day", 1))
	_name_input.text = default_name if default_name != "" else "Day %d" % day
	_name_dialog.visible = true
	_name_input.grab_focus()
	_name_input.select_all()


func _on_name_confirmed(_text: String = "") -> void:
	var name := _name_input.text.strip_edges()
	if name.is_empty():
		return
	SaveManager.save_to_slot(_pending_slot, name)
	_name_dialog.hide()
	_build_slots()


func _on_load(slot_name: String) -> void:
	queue_free()
	SaveManager.load_from_slot(slot_name)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _name_dialog.visible:
			_name_dialog.hide()
		else:
			queue_free()


# ─── helpers ─────────────────────────────────────────────────────────────────

func _lbl(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", MHTokens.FONT_BODY)
	return l


func _btn(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", MHTokens.FONT_BODY)
	b.pressed.connect(callback)
	return b
