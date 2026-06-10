@tool
class_name MindHarvestDiscoveryChoiceEvent
extends DialogicChoiceEvent
## Choice node designed specifically for discovery options.
##
## Differences from the stock Choice:
##   - Picks up the display text from DiscoveryRegistry automatically.
##   - Always hides itself when the discovery has already been collected.
##   - Accepts an optional activation_condition (stat gate) that is ANDed
##     with the duplicate-guard automatically.
##
## Timeline text format produced by to_text():
##   - Label | [if {discoveries.X} != true] [else="hide" disco="X"]
##   - Label | [if {discoveries.X} != true and {stats.perception} >= 2] [else="hide" disco="X"]
##
## The `disco="X"` tag in the else-block is the marker that lets is_valid_event()
## distinguish these lines from ordinary choices.


@export var discovery_id:         String = ""
@export var choice_text:          String = ""   ## blank → card's short_label is used
@export var activation_condition: String = ""   ## optional stat gate, e.g. {stats.perception} >= 2


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name        = "Discovery Choice"
	event_description = "A choice button that reveals a discovery. Auto-hides if already collected. Accepts an optional stat-gate condition."
	set_default_color("Color4")
	event_category      = "Game"
	event_sorting_index = 1
	can_contain_events  = true
	wants_to_group      = true
	collapse_on_create  = true

#endregion


#region END BRANCH
################################################################################

func _get_end_branch_control() -> Control:
	# Use absolute path — our script lives in a different directory than the original.
	return load("res://addons/dialogic/Modules/Choice/ui_choice_end.tscn").instantiate()

#endregion


#region SAVING / LOADING
################################################################################

func to_text() -> String:
	if discovery_id.is_empty():
		return "- "
	var card := DiscoveryRegistry.get_card(discovery_id)
	var display := choice_text.strip_edges()
	if display.is_empty() and card != null:
		display = card.short_label

	var cond := "{discoveries.%s} != true" % discovery_id
	if not activation_condition.strip_edges().is_empty():
		cond += " and " + activation_condition.strip_edges()

	return '- %s | [if %s] [else="hide" disco="%s"]' % [display, cond, discovery_id]


func from_text(string: String) -> void:
	super.from_text(string)
	discovery_id = extra_data.get("disco", "")
	if discovery_id.is_empty():
		return
	# Recover the optional activation_condition by stripping the auto-generated prefix.
	var prefix := "{discoveries.%s} != true" % discovery_id
	if condition.begins_with(prefix):
		var remainder := condition.substr(prefix.length()).strip_edges()
		activation_condition = remainder.substr(4).strip_edges() if remainder.begins_with("and ") else ""
	# Mirror the parsed text into choice_text so the editor field is populated.
	choice_text = text


func is_valid_event(string: String) -> bool:
	# Only claim lines that carry the disco= marker; plain choices go to DialogicChoiceEvent.
	return string.strip_edges().begins_with("-") and 'disco="' in string

#endregion


#region EDITOR REPRESENTATION
################################################################################

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
	add_header_edit("choice_text", ValueType.SINGLELINE_TEXT, {
		"left_text":   "Label:",
		"placeholder": "(use card label)",
	})
	add_body_edit("", ValueType.LABEL, {"text": "Activation condition (optional stat gate):"})
	add_body_edit("activation_condition", ValueType.CONDITION, {})

#endregion
