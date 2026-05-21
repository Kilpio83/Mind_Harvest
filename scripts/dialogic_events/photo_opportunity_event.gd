@tool
class_name MindHarvestPhotoOpportunityEvent
extends DialogicEvent
## Pauses the timeline and shows a click-to-capture QTE.
## Effective window = window_ms + (stats.perception * perception_bonus_ms).
## Writes flags.last_photo_success and calls PatientManager.add_photo on success.


### Settings

@export var id: String = ""
@export var patient: String = ""
@export var title: String = ""
@export var description: String = ""
@export var portrait: String = ""
@export var window_ms: float = 1500.0
@export var perception_bonus_ms: float = 300.0


#region EXECUTE
################################################################################

func _execute() -> void:
	var photo := PhotoData.new()
	photo.id = id
	photo.patient = patient
	photo.title = title
	photo.description = description
	photo.portrait_path = portrait
	photo.day_taken = int(Dialogic.VAR.get_variable("game.day", 1))

	var perception: int = int(Dialogic.VAR.get_variable("stats.perception", 1))
	var effective_ms: float = window_ms + perception * perception_bonus_ms

	var overlay = dialogic.get_tree().get_first_node_in_group("photo_qte")
	var success: bool = await overlay.show_opportunity(effective_ms, portrait)

	Dialogic.VAR.set_variable("flags.last_photo_success", success)
	if success:
		PatientManager.add_photo(patient, photo)
		if ToastLayer:
			ToastLayer.show_toast("Photo captured", photo.title, "photo")

	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Photo Opportunity"
	event_description = "Shows a timed click-to-capture QTE. Sets flags.last_photo_success."
	set_default_color("Color5")
	event_category = "Game"
	event_sorting_index = 3

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "photo_opportunity"


func get_shortcode_parameters() -> Dictionary:
	return {
		"id":                  {"property": "id",                  "default": ""},
		"patient":             {"property": "patient",             "default": ""},
		"title":               {"property": "title",               "default": ""},
		"description":         {"property": "description",         "default": ""},
		"portrait":            {"property": "portrait",            "default": ""},
		"window_ms":           {"property": "window_ms",           "default": 1500.0},
		"perception_bonus_ms": {"property": "perception_bonus_ms", "default": 300.0},
	}


func build_event_editor() -> void:
	add_header_edit("id",                  ValueType.SINGLELINE_TEXT, {"left_text": "ID:"})
	add_header_edit("patient",             ValueType.SINGLELINE_TEXT, {"left_text": "Patient:"})
	add_header_edit("title",               ValueType.SINGLELINE_TEXT, {"left_text": "Title:"})
	add_header_edit("description",         ValueType.SINGLELINE_TEXT, {"left_text": "Description:"})
	add_header_edit("portrait",            ValueType.SINGLELINE_TEXT, {"left_text": "Portrait:"})
	add_header_edit("window_ms",           ValueType.NUMBER,          {"left_text": "Window ms:"})
	add_header_edit("perception_bonus_ms", ValueType.NUMBER,          {"left_text": "Bonus ms/pt:"})

#endregion
