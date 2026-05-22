@tool
class_name MindHarvestApplyMeterDeltaEvent
extends DialogicEvent
## Adjusts therapy_progress (0–100) or personal_bond (−50–+50) for a patient
## and fires a toast notification.


### Settings

## Key from project.godot patients dict: "anna" | "marisol"
@export var patient: String = ""
## Which axis to adjust.
@export var axis: String = "therapy_progress"   # "therapy_progress" | "personal_bond"
## Positive or negative integer delta.
@export var amount: int = 0
## Short reason shown in the toast subtitle (optional).
@export var reason: String = ""


#region EXECUTE
################################################################################

func _execute() -> void:
	if patient.is_empty():
		finish()
		return

	var key := "patients." + patient + "." + axis
	var current: int = int(Dialogic.VAR.get_variable(key, 0))
	var new_val: int

	if axis == "therapy_progress":
		new_val = clampi(current + amount, 0, 100)
	else:
		new_val = clampi(current + amount, -50, 50)

	Dialogic.VAR.set_variable(key, new_val)

	var sign_str := "+" if amount >= 0 else ""
	print("[METER] %s.%s  %s%d  (%d → %d)" % [patient, axis, sign_str, amount, current, new_val])

	if ToastLayer and amount != 0:
		var display_name := patient.capitalize()
		var axis_label  := "Therapy" if axis == "therapy_progress" else "Bond"
		var toast_type  := "success" if amount > 0 else "warning"
		ToastLayer.show_toast(
			"%s %s %s%d" % [display_name, axis_label, sign_str, amount],
			reason,
			toast_type)

	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name        = "Apply Meter Delta"
	event_description = "Adjusts therapy_progress or personal_bond for a patient and fires a toast."
	set_default_color("Color5")
	event_category    = "Game"
	event_sorting_index = 1

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "apply_meter_delta"


func get_shortcode_parameters() -> Dictionary:
	return {
		"patient": {"property": "patient", "default": ""},
		"axis":    {"property": "axis",    "default": "therapy_progress"},
		"amount":  {"property": "amount",  "default": 0},
		"reason":  {"property": "reason",  "default": ""},
	}


func build_event_editor() -> void:
	add_header_edit("patient", ValueType.SINGLELINE_TEXT,  {"left_text": "Patient:"})
	add_header_edit("axis",    ValueType.SINGLELINE_TEXT,  {"left_text": "Axis:"})
	add_header_edit("amount",  ValueType.NUMBER,            {"left_text": "Amount:"})
	add_body_edit("reason",    ValueType.SINGLELINE_TEXT,  {"left_text": "Reason:"})

#endregion
