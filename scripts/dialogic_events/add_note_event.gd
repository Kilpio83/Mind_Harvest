@tool
class_name MindHarvestAddNoteEvent
extends DialogicEvent
## Records a discovered fact to a patient's file via PatientManager.


@export var patient: String = ""
@export var fact_id: String = ""


#region EXECUTE
################################################################################

func _execute() -> void:
	if not patient.is_empty() and not fact_id.is_empty():
		PatientManager.add_note(patient, fact_id)
	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Add Note"
	event_description = "Records a discovered fact to a patient's file."
	set_default_color("Color4")
	event_category = "Game"
	event_sorting_index = 4

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "add_note"


func get_shortcode_parameters() -> Dictionary:
	return {
		"patient": {"property": "patient", "default": ""},
		"fact_id": {"property": "fact_id", "default": ""},
	}


func build_event_editor() -> void:
	add_header_edit("patient", ValueType.SINGLELINE_TEXT, {"left_text": "Patient:"})
	add_header_edit("fact_id", ValueType.SINGLELINE_TEXT, {"left_text": "Fact ID:"})

#endregion
