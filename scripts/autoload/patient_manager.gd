extends Node
## Manages per-patient photos, notes, and dual-axis meters. Bridges Dialogic variables with UI scenes.

var photos_by_patient:      Dictionary = {}
var notes_by_patient:       Dictionary = {}
var discoveries_by_patient: Dictionary = {}
var bea_relationship: int = 0


func _ready() -> void:
	# Auto-record any discovery choice the player selects.
	# DiscoveryChoiceEvent always stores disco="<id>" in extra_data, which
	# Dialogic merges into choice_info before emitting choice_selected.
	Dialogic.Choices.choice_selected.connect(_on_dialogic_choice_selected)


func _on_dialogic_choice_selected(choice_info: Dictionary) -> void:
	if not "disco" in choice_info:
		return
	var discovery_id: String = str(choice_info["disco"])
	var card := DiscoveryRegistry.get_card(discovery_id)
	if card:
		add_discovery(card.patient, discovery_id)


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


## Adjusts therapy_progress (0–100) for a patient.
## Usage in timelines:  do PatientManager.add_therapy("anna", 10)
func add_therapy(patient_name: String, delta: int, reason: String = "") -> void:
	var key := "patients." + patient_name + ".therapy_progress"
	var current: int = int(Dialogic.VAR.get_variable(key, 30))
	var new_val: int = clampi(current + delta, 0, 100)
	Dialogic.VAR.set_variable(key, new_val)
	var sign_str := "+" if delta >= 0 else ""
	print("[THERAPY] %s  %s%d  (%d → %d)" % [patient_name, sign_str, delta, current, new_val])
	if ToastLayer and delta != 0:
		var toast_type := "success" if delta > 0 else "warning"
		ToastLayer.show_toast(
			"%s Therapy %s%d" % [patient_name.capitalize(), sign_str, delta],
			reason, toast_type)


## Adjusts personal_bond (−50–+50) for a patient.
## Usage in timelines:  do PatientManager.add_bond("anna", 5)
func add_bond(patient_name: String, delta: int, reason: String = "") -> void:
	var key := "patients." + patient_name + ".personal_bond"
	var current: int = int(Dialogic.VAR.get_variable(key, 0))
	var new_val: int = clampi(current + delta, -50, 50)
	Dialogic.VAR.set_variable(key, new_val)
	var sign_str := "+" if delta >= 0 else ""
	print("[BOND] %s  %s%d  (%d → %d)" % [patient_name, sign_str, delta, current, new_val])
	if ToastLayer and delta != 0:
		var toast_type := "success" if delta > 0 else "warning"
		ToastLayer.show_toast(
			"%s Bond %s%d" % [patient_name.capitalize(), sign_str, delta],
			reason, toast_type)


## Adds a discovery by ID. Ignores duplicates. Fires a toast.
func add_discovery(patient_name: String, discovery_id: String) -> void:
	if not patient_name in discoveries_by_patient:
		discoveries_by_patient[patient_name] = []
	var arr: Array = discoveries_by_patient[patient_name]
	for existing in arr:
		if (existing as DiscoveryCard).id == discovery_id:
			return  # already collected
	var card := DiscoveryRegistry.get_card(discovery_id)
	if card == null:
		return
	card.session_added = int(Dialogic.VAR.get_variable(
		"patients." + patient_name + ".progress", 0))
	arr.append(card)
	Dialogic.VAR.set_variable("discoveries." + discovery_id, true)
	print("[DISCOVERY] %s — %s" % [patient_name, discovery_id])
	if ToastLayer:
		ToastLayer.show_toast("Discovery noted", card.short_label, "photo")


func get_discoveries(patient_name: String) -> Array:
	return discoveries_by_patient.get(patient_name, [])


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

	HypothesisManager.unlock_after_session(patient_name)


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
