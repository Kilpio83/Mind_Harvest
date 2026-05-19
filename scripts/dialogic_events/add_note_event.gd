@tool
class_name MindHarvestAddNoteEvent
extends DialogicEvent
## Appends a short session note to a patient's file.
## Write the note text directly — it appears verbatim in the Patient Files UI.
## Example: [add_note patient="anna" note="Deflected every direct question about work."]


@export var patient: String = ""
@export var note_text: String = ""


#region EXECUTE
################################################################################

func _execute() -> void:
	if not patient.is_empty() and not note_text.is_empty():
		PatientManager.add_note(patient, note_text)
	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Add Note"
	event_description = "Appends a session note to a patient's file (shown verbatim in Patient Files)."
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
		"patient": {"property": "patient",   "default": ""},
		"note":    {"property": "note_text", "default": ""},
	}


func build_event_editor() -> void:
	add_header_edit("patient",   ValueType.SINGLELINE_TEXT, {"left_text": "Patient:"})
	add_header_edit("note_text", ValueType.SINGLELINE_TEXT, {"left_text": "Note:"})

#endregion
