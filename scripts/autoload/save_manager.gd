extends Node
## Handles saving and loading GameSave resources alongside Dialogic's own save state.

const SAVE_DIR := "user://saves/"
const SAVE_EXT := ".tres"
const AUTOSAVE_SLOT := "slot_0"
const MAX_MANUAL_SLOTS := 3

var current_save_slot: String = AUTOSAVE_SLOT


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func autosave() -> void:
	save_to_slot(current_save_slot)


func save_to_slot(slot_name: String) -> void:
	var data := GameSave.new()
	data.day = int(Dialogic.VAR.get_variable("game.day", 1))
	data.photos_by_patient = PatientManager.photos_by_patient.duplicate(true)
	data.notes_by_patient = PatientManager.notes_by_patient.duplicate(true)
	data.bea_relationship = PatientManager.bea_relationship
	data.save_date = Time.get_datetime_string_from_system()
	data.dialogic_save_slot = slot_name

	var path := SAVE_DIR + slot_name + SAVE_EXT
	var err := ResourceSaver.save(data, path)
	if err != OK:
		printerr("[SaveManager] Failed to save to slot '%s': %s" % [slot_name, error_string(err)])
		return

	Dialogic.Save.save(slot_name)


func load_from_slot(slot_name: String) -> bool:
	var path := SAVE_DIR + slot_name + SAVE_EXT
	if not FileAccess.file_exists(path):
		printerr("[SaveManager] No save file at slot '%s'." % slot_name)
		return false

	var data := ResourceLoader.load(path) as GameSave
	if not data:
		printerr("[SaveManager] Could not parse save file at slot '%s'." % slot_name)
		return false

	PatientManager.photos_by_patient = data.photos_by_patient.duplicate(true)
	PatientManager.notes_by_patient = data.notes_by_patient.duplicate(true)
	Dialogic.Save.load(slot_name)
	return true


func slot_exists(slot_name: String) -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot_name + SAVE_EXT)


func get_slot_info(slot_name: String) -> Dictionary:
	if not slot_exists(slot_name):
		return {}
	var data := ResourceLoader.load(SAVE_DIR + slot_name + SAVE_EXT) as GameSave
	if not data:
		return {}
	return {"day": data.day, "date": data.save_date}


func get_manual_slots() -> Array[String]:
	var slots: Array[String] = []
	for i in range(1, MAX_MANUAL_SLOTS + 1):
		var slot := "slot_%d" % i
		if slot_exists(slot):
			slots.append(slot)
	return slots
