@tool
class_name MindHarvestStartSessionEvent
extends DialogicEvent
## Custom event: pops the next patient from GameState's queue and starts their
## current session timeline via PatientManager.


### Settings

## Override to force a specific patient instead of pulling from the queue.
@export var patient_override: String = ""


#region EXECUTE
################################################################################

func _execute() -> void:
	var game_state: Node = dialogic.get_node_or_null("/root/GameState")
	var patient_mgr: Node = dialogic.get_node_or_null("/root/PatientManager")

	if not game_state or not patient_mgr:
		printerr("[StartSession] GameState or PatientManager autoload not found!")
		finish()
		return

	var patient_name: String = patient_override
	if patient_name.is_empty():
		patient_name = game_state.get_next_patient()

	if patient_name.is_empty():
		printerr("[StartSession] No patient available in queue!")
		finish()
		return

	Dialogic.VAR.set_variable("game.current_patient", patient_name)
	var timeline_path: String = patient_mgr.get_next_session_timeline(patient_name)

	if not ResourceLoader.exists(timeline_path):
		printerr("[StartSession] Session timeline not found: %s" % timeline_path)
		finish()
		return

	dialogic.start_timeline(timeline_path)

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Start Session"
	event_description = "Starts the next session for the next patient in the queue."
	set_default_color("Color5")
	event_category = "Game"
	event_sorting_index = 1

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "start_session"


func get_shortcode_parameters() -> Dictionary:
	return {
		"patient": {"property": "patient_override", "default": ""},
	}


func build_event_editor() -> void:
	add_header_edit("patient_override", ValueType.SINGLELINE_TEXT, {
		"left_text": "Patient (blank = auto):",
		"placeholder": "auto"
	})

#endregion
