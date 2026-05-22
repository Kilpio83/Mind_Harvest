extends Node
## Manages per-patient photos, notes, and dual-axis meters. Bridges Dialogic variables with UI scenes.

var photos_by_patient: Dictionary = {}
var notes_by_patient: Dictionary = {}
var bea_relationship: int = 0


func add_bea_relationship(delta: int) -> void:
	bea_relationship += delta
	if Dialogic.VAR:
		Dialogic.VAR.set_variable("game.bea_relationship", bea_relationship)


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


## Adjusts therapy_progress (clamped 0–100) or personal_bond (clamped −50–+50).
## Called from session timelines via  do PatientManager.apply_meter_delta(...).
func apply_meter_delta(patient_name: String, axis: String, delta: int, reason: String = "") -> void:
	var key := "patients." + patient_name + "." + axis
	var current: int = int(Dialogic.VAR.get_variable(key, 0))
	var new_val: int
	if axis == "therapy_progress":
		new_val = clampi(current + delta, 0, 100)
	else:
		new_val = clampi(current + delta, -50, 50)
	Dialogic.VAR.set_variable(key, new_val)

	var sign_str := "+" if delta >= 0 else ""
	print("[METER] %s.%s  %s%d  (%d → %d)" % [patient_name, axis, sign_str, delta, current, new_val])

	if ToastLayer and delta != 0:
		var display_name := patient_name.capitalize()
		var axis_label   := "Therapy" if axis == "therapy_progress" else "Bond"
		var toast_type   := "success" if delta > 0 else "warning"
		ToastLayer.show_toast(
			"%s %s %s%d" % [display_name, axis_label, sign_str, delta],
			reason, toast_type)


func get_next_session_timeline(patient_name: String) -> String:
	var progress: int = int(Dialogic.VAR.get_variable("patients." + patient_name + ".progress", 0))
	var session_num: int = progress + 1
	return "res://dialogic/timelines/patients/%s/session_%d.dtl" % [patient_name, session_num]


func mark_session_done(patient_name: String) -> void:
	var progress_key := "patients." + patient_name + ".progress"
	var progress: int = int(Dialogic.VAR.get_variable(progress_key, 0))
	Dialogic.VAR.set_variable(progress_key, progress + 1)

	var day: int = int(Dialogic.VAR.get_variable("game.day", 1))
	Dialogic.VAR.set_variable("patients." + patient_name + ".next_day", day + 2)


## Returns the quadrant ending family for a patient, or "" if arc should continue.
##   "lover"    — therapy >= 70 AND bond >= +20
##   "graduate" — therapy >= 70 AND bond <  +20
##   "devotee"  — therapy <= 30 AND bond >= +20
##   "nemesis"  — therapy <= 30 AND bond <= -20
##   ""         — intermediate; arc continues
func check_arc_resolution(patient_name: String) -> String:
	var therapy: int = int(Dialogic.VAR.get_variable("patients." + patient_name + ".therapy_progress", 30))
	var bond:    int = int(Dialogic.VAR.get_variable("patients." + patient_name + ".personal_bond",    0))

	if therapy >= 70:
		return "lover" if bond >= 20 else "graduate"
	elif therapy <= 30:
		if bond >= 20:
			return "devotee"
		elif bond <= -20:
			return "nemesis"
	return ""
