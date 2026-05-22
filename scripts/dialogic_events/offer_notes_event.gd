@tool
class_name MindHarvestOfferNotesEvent
extends DialogicEvent
## Shows a notes panel on the right side of the screen.
## The timeline pauses until the player picks a discovery or skips.
## On pick: adds the DiscoveryCard via PatientManager.add_discovery().


### Settings

## Patient whose discovery list to add to.
@export var patient: String = ""
## Prompt shown at the top of the notes panel.
@export var title: String = "What do you note?"
## Comma-separated discovery IDs from DiscoveryRegistry.
@export var discovery_ids: String = ""
## Whether to show a Skip button.
@export var allow_skip: bool = true

var _panel: Node = null


#region EXECUTE
################################################################################

func _execute() -> void:
	if Engine.is_editor_hint() or patient.is_empty() or discovery_ids.is_empty():
		finish()
		return

	var ids: Array[String] = []
	for raw in discovery_ids.split(",", false):
		var s := (raw as String).strip_edges()
		if not s.is_empty():
			ids.append(s)

	if ids.is_empty():
		finish()
		return

	var panel_script = load("res://scripts/ui/notes_panel.gd")
	_panel = panel_script.new()
	_panel.setup(title, ids, allow_skip)
	_panel.chosen.connect(_on_chosen)
	dialogic.get_node("/root").add_child(_panel)


func _on_chosen(discovery_id: String) -> void:
	if not discovery_id.is_empty():
		var pm: Node = dialogic.get_node_or_null("/root/PatientManager")
		if pm:
			pm.add_discovery(patient, discovery_id)
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name        = "Offer Notes"
	event_description = "Pauses the timeline and shows 2-4 note options on the right side of the screen."
	set_default_color("Color3")
	event_category    = "Game"
	event_sorting_index = 3

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "offer_notes"


func get_shortcode_parameters() -> Dictionary:
	return {
		"patient":    {"property": "patient",       "default": ""},
		"title":      {"property": "title",         "default": "What do you note?"},
		"ids":        {"property": "discovery_ids", "default": ""},
		"allow_skip": {"property": "allow_skip",    "default": true},
	}


func build_event_editor() -> void:
	add_header_edit("patient",       ValueType.SINGLELINE_TEXT, {"left_text": "Patient:"})
	add_header_edit("discovery_ids", ValueType.SINGLELINE_TEXT, {"left_text": "IDs (comma-separated):"})
	add_header_edit("allow_skip",    ValueType.BOOL,            {"left_text": "Allow skip:"})
	add_body_edit("title",           ValueType.SINGLELINE_TEXT, {"left_text": "Prompt:"})

#endregion
