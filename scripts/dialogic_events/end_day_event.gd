@tool
class_name MindHarvestEndDayEvent
extends DialogicEvent
## Custom event: saves the game, advances the day counter, resets morning state,
## and jumps back to the morning_menu timeline.


#region EXECUTE
################################################################################

func _execute() -> void:
	var game_state: Node = dialogic.get_node_or_null("/root/GameState")
	if not game_state:
		printerr("[EndDay] GameState autoload not found!")
		finish()
		return

	# Fade to black before switching timeline.
	var trans: Node = dialogic.get_node_or_null("/root/ScreenTransition")
	if trans:
		await trans.fade_out()

	# advance_day also calls SaveManager.autosave()
	game_state.advance_day()

	var morning_menu := DialogicResourceUtil.get_timeline_resource("morning_menu")
	if morning_menu:
		dialogic.start_timeline(morning_menu)
		# Morning menu is now running behind the black screen — fade back in.
		if trans:
			trans.fade_in()   # fire-and-forget; no await needed
	else:
		printerr("[EndDay] Could not find 'morning_menu' timeline. Check that update_directory was called.")
		if trans:
			trans.fade_in()
		finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "End Day"
	event_description = "Saves the game, advances the day, resets morning slots, and returns to the morning menu."
	set_default_color("Color4")
	event_category = "Game"
	event_sorting_index = 0

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "end_day"


func build_event_editor() -> void:
	add_header_label("End Day")

#endregion
