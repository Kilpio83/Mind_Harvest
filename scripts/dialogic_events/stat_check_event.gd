@tool
class_name MindHarvestStatCheckEvent
extends DialogicEvent
## Rolls a stat-modified probability check and writes the result to a Dialogic variable.
##
## Effective chance = base_chance + max(0, stat_value - threshold) * chance_per_point
## Optional quality output: "crit" | "pass" | "fail"
## Crit threshold: roll < base_chance - 30
##
## Set beat=true to fire a screen-flash before the roll (use when the player
## should consciously notice something unusual happening).


### Settings

## One of: perception, intellect, knowledge, composure, nerve. Leave blank for a pure RNG check.
@export var stat: String = ""
## Stat value must exceed this before chance_per_point kicks in.
@export var threshold: int = 0
## Base success probability (0–100).
@export var base_chance: int = 40
## Extra success % added per stat point above threshold.
@export var chance_per_point: int = 10
## Dialogic variable that receives true/false.
@export var result_variable: String = "check_result"
## Optional variable that receives "crit" / "pass" / "fail". Leave blank to skip.
@export var quality_variable: String = ""
## Play a screen beat (amber flash) before the dice roll animation.
@export var beat: bool = false


#region EXECUTE
################################################################################

func _execute() -> void:
	var stat_value: int = 0
	if not stat.is_empty():
		stat_value = int(Dialogic.VAR.get_variable("stats." + stat, 0))

	var effective_chance: int = base_chance + max(0, stat_value - threshold) * chance_per_point
	var roll: int = randi() % 100
	var success: bool = roll >= (100 - effective_chance)

	var quality: String
	if success and roll >= (130 - base_chance):
		quality = "crit"
	elif success:
		quality = "pass"
	else:
		quality = "fail"

	Dialogic.VAR.set_variable(result_variable, success)
	if not quality_variable.is_empty():
		Dialogic.VAR.set_variable(quality_variable, quality)

	print("[STAT CHECK] stat=%s  value=%d  threshold=%d  base=%d%%  per_pt=%d  effective=%d%%  need≥%d  roll=%d  →  %s" % [
		stat if not stat.is_empty() else "none",
		stat_value, threshold, base_chance, chance_per_point,
		effective_chance, 100 - effective_chance, roll,
		quality.to_upper()
	])

	# Animate with DiceRoll overlay if available; fall back to toast otherwise.
	var dice_roll: Node = Engine.get_main_loop().root.get_node_or_null("DiceRoll")
	if dice_roll != null:
		if beat:
			dice_roll.play_beat()
			await dice_roll.beat_finished
		dice_roll.play_roll(
			stat if not stat.is_empty() else "",
			effective_chance, roll, success, quality)
		await dice_roll.roll_finished
	elif ToastLayer:
		var stat_display := stat.capitalize() if not stat.is_empty() else "Chance"
		if success:
			ToastLayer.show_toast("%s check passed" % stat_display, "", "success")
		else:
			ToastLayer.show_toast("%s check failed" % stat_display, "", "warning")

	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Stat Check"
	event_description = "Rolls a stat-modified probability check and writes the result to a Dialogic variable."
	set_default_color("Color6")
	event_category = "Game"
	event_sorting_index = 2

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "stat_check"


func get_shortcode_parameters() -> Dictionary:
	return {
		"stat":             {"property": "stat",             "default": ""},
		"threshold":        {"property": "threshold",        "default": 0},
		"base_chance":      {"property": "base_chance",      "default": 40},
		"chance_per_point": {"property": "chance_per_point", "default": 10},
		"result":           {"property": "result_variable",  "default": "check_result"},
		"quality":          {"property": "quality_variable", "default": ""},
		"beat":             {"property": "beat",             "default": false},
	}


func build_event_editor() -> void:
	add_header_edit("stat",             ValueType.SINGLELINE_TEXT, {"left_text": "Stat:"})
	add_header_edit("threshold",        ValueType.NUMBER,          {"left_text": "Threshold:"})
	add_header_edit("base_chance",      ValueType.NUMBER,          {"left_text": "Base %:"})
	add_header_edit("chance_per_point", ValueType.NUMBER,          {"left_text": "Per pt:"})
	add_header_edit("result_variable",  ValueType.SINGLELINE_TEXT, {"left_text": "→ Result var:"})
	add_header_edit("quality_variable", ValueType.SINGLELINE_TEXT, {"left_text": "→ Quality var:"})
	add_header_edit("beat",             ValueType.BOOL,            {"left_text": "Beat:"})

#endregion
