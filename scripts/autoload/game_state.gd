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


## Rolls a plain chance check and writes result to {check_result}.
func roll_chance(base_chance: int) -> void:
	Dialogic.VAR.set_variable("check_result", randi() % 100 < base_chance)


## Rolls a 40% chance to boost a random stat by 1 (hard-capped at 10).
## Writes result to {check_result} and the chosen stat name to {game.last_random_stat}.
func roll_random_stat() -> void:
	var success: bool = randi() % 100 < 40
	Dialogic.VAR.set_variable("check_result", success)
	if success:
		var stats := ["intelligence", "patience", "knowledge", "perception"]
		var chosen: String = stats[randi() % stats.size()]
		Dialogic.VAR.set_variable("game.last_random_stat", chosen)
		var key := "stats." + chosen
		var current: int = int(Dialogic.VAR.get_variable(key, 1))
		Dialogic.VAR.set_variable(key, min(current + 1, 10))
	else:
		Dialogic.VAR.set_variable("game.last_random_stat", "")


const MORNING_ACTIVITY_FLAGS := [
	"flags.did_review_files",
	"flags.did_read_book",
	"flags.did_jogging",
	"flags.did_chat_bea",
	"flags.did_analyze_session",
	"flags.did_walk",
]


func advance_day() -> void:
	var current_day: int = int(Dialogic.VAR.get_variable("game.day", 1))
	Dialogic.VAR.set_variable("game.day", current_day + 1)
	Dialogic.VAR.set_variable("game.morning_slots_left", 2)
	Dialogic.VAR.set_variable("game.phase", "morning")
	Dialogic.VAR.set_variable("game.has_patients", false)
	for flag in MORNING_ACTIVITY_FLAGS:
		Dialogic.VAR.set_variable(flag, false)
	patient_queue.clear()
	SaveManager.autosave()
