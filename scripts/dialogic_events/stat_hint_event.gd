@tool
class_name MindHarvestStatHintEvent
extends DialogicEvent
## Calculates the effective check odds and writes a formatted hint string to a
## Dialogic variable so that choice labels can show inline odds.
##
## Usage: [stat_hint stat="perception" base_chance=40]
## Then in a choice: "You don't seem that upset.  {stat_hint}"
## Produces e.g. "[PER · 47%]"


@export var stat: String = ""
@export var base_chance: int = 40
@export var threshold: int = 0
@export var chance_per_point: int = 10
@export var target_variable: String = "stat_hint"


#region EXECUTE
################################################################################

func _execute() -> void:
	var stat_value: int = 0
	if not stat.is_empty():
		stat_value = int(Dialogic.VAR.get_variable("stats." + stat, 0))
	var effective_chance: int = base_chance + max(0, stat_value - threshold) * chance_per_point
	var abbr: String = stat.substr(0, 3).to_upper() if not stat.is_empty() else "RNG"
	Dialogic.VAR.set_variable(target_variable, "[%s · %d%%]" % [abbr, effective_chance])
	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Stat Hint"
	event_description = "Writes formatted odds string to a variable for inline choice hints."
	set_default_color("Color6")
	event_category = "Game"
	event_sorting_index = 3

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "stat_hint"


func get_shortcode_parameters() -> Dictionary:
	return {
		"stat":             {"property": "stat",             "default": ""},
		"base_chance":      {"property": "base_chance",      "default": 40},
		"threshold":        {"property": "threshold",        "default": 0},
		"chance_per_point": {"property": "chance_per_point", "default": 10},
		"var":              {"property": "target_variable",  "default": "stat_hint"},
	}


func build_event_editor() -> void:
	add_header_edit("stat",             ValueType.SINGLELINE_TEXT, {"left_text": "Stat:"})
	add_header_edit("base_chance",      ValueType.NUMBER,          {"left_text": "Base %:"})
	add_header_edit("threshold",        ValueType.NUMBER,          {"left_text": "Threshold:"})
	add_header_edit("chance_per_point", ValueType.NUMBER,          {"left_text": "Per pt:"})
	add_header_edit("target_variable",  ValueType.SINGLELINE_TEXT, {"left_text": "→ Var:"})

#endregion
