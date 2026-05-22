extends Node
## Manages the current day, phase, and patient queue.
## This autoload is the bridge between Dialogic variable state and GDScript game logic.

var patient_queue: Array[String] = []


func build_patient_queue() -> void:
	patient_queue.clear()
	var day: int = int(Dialogic.VAR.get_variable("game.day", 1))
	for patient_name in ["anna", "marisol"]:
		var next_day: int = int(Dialogic.VAR.get_variable("patients." + patient_name + ".next_day", 0))
		var progress: int = int(Dialogic.VAR.get_variable("patients." + patient_name + ".progress", 0))
		var ending: String = str(Dialogic.VAR.get_variable("patients." + patient_name + ".ending", ""))
		if next_day <= day and progress < 3 and ending.is_empty():
			patient_queue.append(patient_name)
	# Update Dialogic variable so timelines can gate the "Next Patient" choice
	Dialogic.VAR.set_variable("game.has_patients", not patient_queue.is_empty())


func get_next_patient() -> String:
	if patient_queue.is_empty():
		return ""
	var next: String = patient_queue[0]
	patient_queue.remove_at(0)
	Dialogic.VAR.set_variable("game.has_patients", not patient_queue.is_empty())
	return next


func has_patients() -> bool:
	return not patient_queue.is_empty()


## Decrements morning_slots_left by 1, keeping the value as an integer.
func use_morning_slot() -> void:
	var current: int = int(Dialogic.VAR.get_variable("game.morning_slots_left", 2))
	Dialogic.VAR.set_variable("game.morning_slots_left", current - 1)


## Rolls a plain chance check and writes result to {check_result}.
func roll_chance(base_chance: int) -> void:
	Dialogic.VAR.set_variable("check_result", randi() % 100 < base_chance)



## Adds XP toward a stat. At 10 XP the stat increases by 1 (carry-over style).
## Emits stat_xp_changed so the UI panel can animate.
func add_stat_xp(stat: String, amount: int) -> void:
	var xp_key  := "stats." + stat + "_xp"
	var stat_key := "stats." + stat
	var old_xp   := int(Dialogic.VAR.get_variable(xp_key,  0))
	var old_stat := int(Dialogic.VAR.get_variable(stat_key, 1))
	var new_xp   := old_xp + amount
	var new_stat := old_stat
	while new_xp >= 10 and new_stat < 10:
		new_xp  -= 10
		new_stat += 1
	if new_stat >= 10:
		new_xp = 0
	Dialogic.VAR.set_variable(xp_key,  new_xp)
	Dialogic.VAR.set_variable(stat_key, new_stat)
	print("[XP] %s  +%d  (was %d xp / Lv %d)  →  %d xp / Lv %d" % [stat, amount, old_xp, old_stat, new_xp, new_stat])

	if ToastLayer:
		var stat_display := stat.capitalize()
		if new_stat > old_stat:
			print("[XP] *** LEVEL UP  %s  Lv %d → Lv %d ***" % [stat, old_stat, new_stat])
			ToastLayer.show_toast(
				"%s increased to %d" % [stat_display, new_stat],
				"%d → %d xp carry-over" % [old_xp + amount, new_xp],
				"stat")
		else:
			ToastLayer.show_toast(
				"%s +%d xp" % [stat_display, amount],
				"%d / 10 xp" % new_xp,
				"stat")


## Opens the patient file view as a CanvasLayer overlay over the current scene.
func open_patient_files() -> void:
	var scene: PackedScene = load("res://scenes/ui/patient_file_view.tscn")
	get_tree().root.add_child(scene.instantiate())


## Opens the save/load menu as a CanvasLayer overlay.
func open_save_menu() -> void:
	var scene: PackedScene = load("res://scenes/ui/save_load_menu.tscn")
	get_tree().root.add_child(scene.instantiate())


const MORNING_ACTIVITY_FLAGS := [
	"flags.did_review_files",
	"flags.did_read_book",
	"flags.did_jogging",
	"flags.did_chat_bea",
	"flags.did_analyze_session",
	"flags.did_walk",
]


func reset_game() -> void:
	Dialogic.VAR.reset()
	PatientManager.photos_by_patient      = {}
	PatientManager.notes_by_patient       = {}
	PatientManager.discoveries_by_patient = {}
	PatientManager.bea_relationship       = 0
	patient_queue.clear()


func advance_day() -> void:
	var current_day: int = int(Dialogic.VAR.get_variable("game.day", 1))
	Dialogic.VAR.set_variable("game.day", current_day + 1)
	Dialogic.VAR.set_variable("game.morning_slots_left", 2)
	Dialogic.VAR.set_variable("game.phase", "morning")
	Dialogic.VAR.set_variable("game.has_patients", false)
	for flag in MORNING_ACTIVITY_FLAGS:
		Dialogic.VAR.set_variable(flag, false)
	patient_queue.clear()
