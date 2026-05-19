extends Node
## Root scene. Scans all timeline and character files into Dialogic's directory,
## then starts the intro timeline. Everything from here is Dialogic-driven.

func _ready() -> void:
	# Populate Dialogic's runtime directory so 'jump <name>/' works in timelines.
	DialogicResourceUtil.update_directory(".dtl")
	DialogicResourceUtil.update_directory(".dch")
	add_child(load("res://scenes/ui/main_menu.tscn").instantiate())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if get_node_or_null("MainMenu") != null:
			return
		if not get_tree().get_nodes_in_group("save_menu").is_empty():
			return
		get_viewport().set_input_as_handled()
		GameState.open_save_menu()
