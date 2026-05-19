extends Node
## Root scene. Scans all timeline and character files into Dialogic's directory,
## then starts the intro timeline. Everything from here is Dialogic-driven.

func _ready() -> void:
	# Populate Dialogic's runtime directory so 'jump <name>/' works in timelines.
	DialogicResourceUtil.update_directory(".dtl")
	DialogicResourceUtil.update_directory(".dch")
	add_child(load("res://scenes/ui/main_menu.tscn").instantiate())
