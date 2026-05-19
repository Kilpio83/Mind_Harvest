@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [
		"res://scripts/dialogic_events/end_day_event.gd",
		"res://scripts/dialogic_events/photo_opportunity_event.gd",
		"res://scripts/dialogic_events/start_session_event.gd",
		"res://scripts/dialogic_events/stat_check_event.gd",
	]
