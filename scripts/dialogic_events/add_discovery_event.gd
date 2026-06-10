@tool
class_name MindHarvestAddDiscoveryEvent
extends DialogicEvent
## Records a discovery for a patient.
## The patient is derived automatically from the registry — only the ID is needed.


@export var discovery_id: String = ""


#region EXECUTE
################################################################################

func _execute() -> void:
	if discovery_id.is_empty():
		finish()
		return
	var card := DiscoveryRegistry.get_card(discovery_id)
	if card:
		PatientManager.add_discovery(card.patient, discovery_id)
	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name        = "Add Discovery"
	event_description = "Records a discovery for a patient. Patient is resolved from the registry."
	set_default_color("Color4")
	event_category        = "Game"
	event_sorting_index   = 3

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "add_discovery"


func get_shortcode_parameters() -> Dictionary:
	return {
		"id": {"property": "discovery_id", "default": ""},
	}


func build_event_editor() -> void:
	var options: Array = []
	var ids := DiscoveryRegistry._CARDS.keys()
	ids.sort()
	for id: String in ids:
		var card: Dictionary = DiscoveryRegistry._CARDS[id]
		options.append({
			"label": "[%s]  %s" % [card["patient"].capitalize(), card["label"]],
			"value": id,
		})
	add_header_edit("discovery_id", ValueType.FIXED_OPTIONS, {
		"left_text": "Discovery:",
		"options":   options,
	})

#endregion
