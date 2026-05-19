extends CanvasLayer

@onready var slots_container: VBoxContainer = $Panel/VBox/SlotsContainer


func _ready() -> void:
	_build_slots()


func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	for i in range(1, SaveManager.MAX_MANUAL_SLOTS + 1):
		_add_slot_row("slot_%d" % i, i)


func _add_slot_row(slot_name: String, index: int) -> void:
	var info := SaveManager.get_slot_info(slot_name)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	slots_container.add_child(row)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var display := info["name"] if (not info.is_empty() and info["name"] != "") else "Slot %d" % index
	label.text = (
		"%s  —  Day %d" % [display, info["day"]]
		if not info.is_empty() else "Slot %d  —  Empty" % index
	)
	row.add_child(label)

	var new_btn := Button.new()
	new_btn.text = "New Game"
	new_btn.pressed.connect(_on_new_game.bind(slot_name))
	row.add_child(new_btn)

	var load_btn := Button.new()
	load_btn.text = "Continue"
	load_btn.disabled = info.is_empty()
	load_btn.pressed.connect(_on_load.bind(slot_name))
	row.add_child(load_btn)


func _on_new_game(slot_name: String) -> void:
	SaveManager.current_save_slot = slot_name
	GameState.reset_game()
	queue_free()
	Dialogic.start("intro")


func _on_load(slot_name: String) -> void:
	SaveManager.current_save_slot = slot_name
	queue_free()
	SaveManager.load_from_slot(slot_name)
