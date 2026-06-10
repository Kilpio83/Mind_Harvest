extends CanvasLayer

@onready var slots_container: VBoxContainer = $Panel/VBox/SlotsContainer


func _ready() -> void:
	_build_slots()
	_build_display_section()


func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	# Autosave row at top
	var auto_info := SaveManager.get_slot_info(SaveManager.AUTOSAVE_SLOT)
	if not auto_info.is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		slots_container.add_child(row)

		row.add_child(_lbl("Autosave  —  Day %d" % auto_info["day"]))
		row.add_child(_btn("Continue", _on_load.bind(SaveManager.AUTOSAVE_SLOT)))

		slots_container.add_child(HSeparator.new())

	# Manual slots
	for i in range(1, SaveManager.MAX_MANUAL_SLOTS + 1):
		_add_slot_row("slot_%d" % i, i)


func _add_slot_row(slot_name: String, index: int) -> void:
	var info := SaveManager.get_slot_info(slot_name)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	slots_container.add_child(row)

	var display: String = info["name"] if (not info.is_empty() and info["name"] != "") else "Slot %d" % index
	var text: String = (
		"%s  —  Day %d" % [display, info["day"]]
		if not info.is_empty() else "Slot %d  —  Empty" % index
	)
	row.add_child(_lbl(text))
	row.add_child(_btn("New Game", _on_new_game.bind(slot_name)))

	var load_btn := _btn("Continue", _on_load.bind(slot_name))
	load_btn.disabled = info.is_empty()
	row.add_child(load_btn)


func _build_display_section() -> void:
	var vbox: VBoxContainer = slots_container.get_parent()
	vbox.add_child(HSeparator.new())

	var btn := _btn("", func() -> void: pass)  # text set below
	btn.text = "Fullscreen" if not SettingsManager.is_fullscreen() else "Windowed"
	btn.pressed.connect(func() -> void:
		SettingsManager.toggle_fullscreen()
		btn.text = "Fullscreen" if not SettingsManager.is_fullscreen() else "Windowed")
	vbox.add_child(btn)


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


# ─── callbacks ───────────────────────────────────────────────────────────────

func _on_new_game(slot_name: String) -> void:
	SaveManager.current_save_slot = slot_name
	GameState.reset_game()
	queue_free()
	Dialogic.start("intro")


func _on_load(slot_name: String) -> void:
	SaveManager.current_save_slot = slot_name
	queue_free()
	SaveManager.load_from_slot(slot_name)
