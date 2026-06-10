class_name HypothesisCanvas
extends VBoxContainer
## One intent column on the Hypothesis Board.
## intent_id is set as @export in the editor; setup() wires patient + board_ref at runtime.

@export var intent_id: String = ""

@onready var _dot:          ColorRect   = $HeaderPanel/HeaderRow/Dot
@onready var _name_lbl:     Label       = $HeaderPanel/HeaderRow/NameLabel
@onready var _locked_badge: Label       = $HeaderPanel/HeaderRow/LockedBadge
@onready var _desc:         Label       = $Description
@onready var _grid:         GridControl = $Grid
@onready var _strength_bar: ProgressBar = $StrengthRow/StrengthBar
@onready var _strength_val: Label       = $StrengthRow/StrengthValue
@onready var _filled_lbl:   Label       = $FilledLabel

const INTENT_DISPLAY: Dictionary = {
	"heal":     {"name": "Heal",     "desc": "Guide toward genuine breakthrough",   "color": Color(0.592, 0.769, 0.349, 1.0)},
	"befriend": {"name": "Befriend", "desc": "Drop the professional mask",          "color": Color(0.353, 0.624, 0.831, 1.0)},
	"seduce":   {"name": "Seduce",   "desc": "Pursue genuine romance",              "color": Color(0.847, 0.659, 0.659, 1.0)},
	"exploit":  {"name": "Exploit",  "desc": "Use her vulnerability for self-gain", "color": Color(0.937, 0.690, 0.286, 1.0)},
}


func setup(patient: String, board: Node) -> void:
	_grid.intent_id = intent_id
	_grid.patient   = patient
	_grid.board_ref = board

	var info: Dictionary = INTENT_DISPLAY.get(intent_id, {})
	var icolor: Color    = info.get("color", Color.WHITE)
	_dot.color           = icolor
	_name_lbl.text       = info.get("name", intent_id.capitalize())
	_name_lbl.add_theme_color_override("font_color", icolor)
	_desc.text           = info.get("desc", "")

	# Tint header panel bg.
	var header_sb := StyleBoxFlat.new()
	header_sb.bg_color = Color(icolor, 0.22)
	header_sb.set_corner_radius_all(4)
	header_sb.content_margin_left   = 8.0
	header_sb.content_margin_right  = 8.0
	header_sb.content_margin_top    = 6.0
	header_sb.content_margin_bottom = 6.0
	$HeaderPanel.add_theme_stylebox_override("panel", header_sb)

	_strength_bar.add_theme_color_override("font_color", icolor)
	refresh(patient)


func refresh(patient: String) -> void:
	_grid.queue_redraw()
	var strength:   float = HypothesisManager.get_intent_strength(patient, intent_id)
	var full:       bool  = HypothesisManager.is_canvas_full(patient, intent_id)
	var locked_out: bool  = HypothesisManager.is_intent_locked_out(patient, intent_id)
	_strength_bar.value  = strength
	_strength_val.text   = "%.1f" % strength
	_filled_lbl.visible  = full
	_locked_badge.visible = locked_out
