extends CanvasLayer

@onready var slots_container: VBoxContainer = $Panel/VBox/SlotsContainer
@onready var close_button: Button = $Panel/VBox/CloseButton


func _ready() -> void:
	close_button.pressed.connect(queue_free)
	_build_slots()


func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	# Autosave row (read-only)
	var auto_info := SaveManager.get_slot_info(SaveManager.AUTOSAVE_SLOT)
	var auto_label := Label.new()
	auto_label.text = "Autosave: " + (
		"Day %d  —  %s" % [auto_info["day"], auto_info["date"]]
		if not auto_info.is_empty() else "—"
	)
	slots_container.add_child(auto_label)
	slots_container.add_child(HSeparator.new())

	# Manual slots 1–3
	for i in range(1, SaveManager.MAX_MANUAL_SLOTS + 1):
		_add_slot_row("slot_%d" % i, i)


func _add_slot_row(slot_name: String, index: int) -> void:
	var info := SaveManager.get_slot_info(slot_name)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	slots_container.add_child(row)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = (
		"Slot %d  —  Day %d  —  %s" % [index, info["day"], info["date"]]
		if not info.is_empty() else "Slot %d  —  Empty" % index
	)
	row.add_child(label)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save.bind(slot_name))
	row.add_child(save_btn)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.disabled = info.is_empty()
	load_btn.pressed.connect(_on_load.bind(slot_name))
	row.add_child(load_btn)


func _on_save(slot_name: String) -> void:
	SaveManager.save_to_slot(slot_name)
	_build_slots()


func _on_load(slot_name: String) -> void:
	queue_free()
	SaveManager.load_from_slot(slot_name)
