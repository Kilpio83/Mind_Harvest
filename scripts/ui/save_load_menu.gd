extends CanvasLayer

@onready var slots_container: VBoxContainer = $Panel/VBox/SlotsContainer
@onready var close_button: Button = $Panel/VBox/CloseButton

var _name_dialog: PanelContainer
var _name_input: LineEdit
var _pending_slot: String = ""


func _ready() -> void:
	add_to_group("save_menu")
	close_button.pressed.connect(queue_free)
	_build_name_dialog()
	_build_slots()


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
	vbox.add_child(prompt)

	_name_input = LineEdit.new()
	_name_input.max_length = 32
	_name_input.text_submitted.connect(_on_name_confirmed)
	vbox.add_child(_name_input)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var confirm := Button.new()
	confirm.text = "Save"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(func(): _on_name_confirmed(_name_input.text))
	btn_row.add_child(confirm)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func(): _name_dialog.hide())
	btn_row.add_child(cancel)


func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	# Autosave row (load-only)
	var auto_info := SaveManager.get_slot_info(SaveManager.AUTOSAVE_SLOT)
	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 12)
	slots_container.add_child(auto_row)

	var auto_label := Label.new()
	auto_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_label.text = (
		"Autosave  —  Day %d  —  %s" % [auto_info["day"], auto_info["date"]]
		if not auto_info.is_empty() else "Autosave  —  No save yet"
	)
	auto_row.add_child(auto_label)

	if not auto_info.is_empty():
		var load_btn := Button.new()
		load_btn.text = "Load"
		load_btn.pressed.connect(_on_load.bind(SaveManager.AUTOSAVE_SLOT))
		auto_row.add_child(load_btn)

	slots_container.add_child(HSeparator.new())

	# Manual slots sorted newest-first, empty at bottom
	for entry in SaveManager.get_manual_slots_sorted():
		_add_slot_row(entry)


func _add_slot_row(entry: Dictionary) -> void:
	var slot_name: String = entry.get("slot", "")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	slots_container.add_child(row)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if entry.has("day"):
		var display: String = entry["name"] if entry["name"] != "" else slot_name
		label.text = "%s  —  Day %d  —  %s" % [display, entry["day"], entry["date"]]
		row.add_child(label)

		var load_btn := Button.new()
		load_btn.text = "Load"
		load_btn.pressed.connect(_on_load.bind(slot_name))
		row.add_child(load_btn)

		var overwrite_btn := Button.new()
		overwrite_btn.text = "Overwrite"
		overwrite_btn.pressed.connect(_show_name_dialog.bind(slot_name, entry["name"]))
		row.add_child(overwrite_btn)
	else:
		label.text = "— Empty —"
		row.add_child(label)

		var save_btn := Button.new()
		save_btn.text = "Save Here"
		save_btn.pressed.connect(_show_name_dialog.bind(slot_name, ""))
		row.add_child(save_btn)


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
