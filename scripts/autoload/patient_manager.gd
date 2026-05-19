extends Node
## Manages per-patient photos, notes, and trust. Bridges Dialogic variables with UI scenes.

var photos_by_patient: Dictionary = {}
var notes_by_patient: Dictionary = {}
var bea_relationship: int = 0


func add_bea_relationship(delta: int) -> void:
	bea_relationship += delta


func add_photo(patient_name: String, photo: PhotoData) -> void:
	if not patient_name in photos_by_patient:
		photos_by_patient[patient_name] = []
	photos_by_patient[patient_name].append(photo)
	var count: int = int(Dialogic.VAR.get_variable("photos.count", 0))
	Dialogic.VAR.set_variable("photos.count", count + 1)


func add_note(patient_name: String, fact_id: String) -> void:
	if not patient_name in notes_by_patient:
		notes_by_patient[patient_name] = []
	if not fact_id in notes_by_patient[patient_name]:
		notes_by_patient[patient_name].append(fact_id)


func add_trust(patient_name: String, delta: int) -> void:
	var key := "patients." + patient_name + ".trust"
	var current: int = int(Dialogic.VAR.get_variable(key, 30))
	Dialogic.VAR.set_variable(key, clampi(current + delta, 0, 100))


func get_next_session_timeline(patient_name: String) -> String:
	var progress: int = int(Dialogic.VAR.get_variable("patients." + patient_name + ".progress", 0))
	var session_num: int = progress + 1
	return "res://dialogic/timelines/patients/%s/session_%d.dtl" % [patient_name, session_num]


func mark_session_done(patient_name: String) -> void:
	var progress_key := "patients." + patient_name + ".progress"
	var progress: int = int(Dialogic.VAR.get_variable(progress_key, 0))
	Dialogic.VAR.set_variable(progress_key, progress + 1)

	var day: int = int(Dialogic.VAR.get_variable("game.day", 1))
	Dialogic.VAR.set_variable("patients." + patient_name + ".last_day", day)
	Dialogic.VAR.set_variable("patients." + patient_name + ".next_day", day + 2)
