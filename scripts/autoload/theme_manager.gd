extends Node
## Central visual-theme switcher.
##
## Call  ThemeManager.apply("evenfall")  from any script or debug panel.
## Available IDs: "mind_harvest", "evenfall", "hearthwood"
##
## What gets switched:
##   - Godot Theme on the scene root (cascades to all Controls in the tree)
##   - Dialogic dialogue style (textbox, choice box colours)
##
## Limitation: existing UI nodes that override colours in GDScript via
## MHTokens consts will not update until they are rebuilt or reconnected
## to the theme_changed signal.

signal theme_changed(id: String)

var current_id: String = "evenfall"

const _GODOT_THEMES := {
	"mind_harvest": "res://assets/theme/mind_harvest_theme.tres",
	"evenfall":     "res://assets/theme/evenfall_theme.tres",
	"hearthwood":   "res://assets/theme/hearthwood_theme.tres",
}

const _DIALOGIC_STYLES := {
	"mind_harvest": "Mind Harvest",
	"evenfall":     "Evenfall",
	"hearthwood":   "Hearthwood",
}


func _ready() -> void:
	# Apply Godot theme immediately so the UI is correct from frame 1.
	# Dialogic style is deferred one frame — Dialogic's own subsystems finish
	# their _ready() after all autoloads, so calling change_style() here directly
	# can crash. The deferred call runs after the full scene tree is up.
	_apply_godot_theme(current_id)
	call_deferred("_apply_dialogic_style", current_id)


func apply(theme_id: String) -> void:
	if not theme_id in _DIALOGIC_STYLES:
		push_warning("ThemeManager: unknown theme id '%s'" % theme_id)
		return
	current_id = theme_id
	_apply_godot_theme(theme_id)
	_apply_dialogic_style(theme_id)
	theme_changed.emit(theme_id)


func _apply_godot_theme(theme_id: String) -> void:
	var path: String = _GODOT_THEMES.get(theme_id, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		get_tree().root.theme = load(path)
	else:
		get_tree().root.theme = null


func _apply_dialogic_style(theme_id: String) -> void:
	var style_name: String = _DIALOGIC_STYLES.get(theme_id, "Evenfall")
	Dialogic.Styles.change_style(style_name)


func get_dialogic_style_name() -> String:
	return _DIALOGIC_STYLES.get(current_id, "Mind Harvest")
