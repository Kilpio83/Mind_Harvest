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

	var pm: Node = Engine.get_singleton("PatientManager") if false \
		else get_node_or_null("/root/PatientManager")
	if pm == null:
		finish()
		return

	if axis == "therapy_progress":
		pm.add_therapy(patient, amount, reason)
	else:
		pm.add_bond(patient, amount, reason)

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
