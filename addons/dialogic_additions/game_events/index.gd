@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [
		"res://scripts/dialogic_events/add_discovery_event.gd",
		"res://scripts/dialogic_events/discovery_choice_event.gd",
		"res://scripts/dialogic_events/add_note_event.gd",
		"res://scripts/dialogic_events/end_day_event.gd",
		"res://scripts/dialogic_events/photo_opportunity_event.gd",
		"res://scripts/dialogic_events/start_session_event.gd",
		"res://scripts/dialogic_events/stat_check_event.gd",
	]
