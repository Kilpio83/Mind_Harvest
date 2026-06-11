extends Control
## Hypothesis Board overlay — Ubongo-style polyomino puzzle.
## All structure is in hypothesis_board.tscn. This script is logic only.

var patient: String = ""

@onready var _title_lbl:    Label         = $Panel/VBox/Header/TitleLabel
@onready var _close_btn:    Button        = $Panel/VBox/Header/CloseButton
@onready var _dock_stack:   VBoxContainer = $Panel/VBox/Content/Tray/TrayScroll/TrayStack
@onready var _footer_label: Label         = $Panel/VBox/Footer/CommittedLabel
@onready var _panel:        PanelContainer = $Panel

@onready var _heal_canvas:    HypothesisCanvas = $Panel/VBox/Content/CanvasArea/HealCanvas
@onready var _befriend_canvas: HypothesisCanvas = $Panel/VBox/Content/CanvasArea/BefriendCanvas
@onready var _seduce_canvas:  HypothesisCanvas = $Panel/VBox/Content/CanvasArea/SeduceCanvas
@onready var _exploit_canvas: HypothesisCanvas = $Panel/VBox/Content/CanvasArea/ExploitCanvas

var _canvas_nodes: Dictionary = {}   # intent_id → HypothesisCanvas
var _card_orientations: Dictionary = {}
var _active_disc_id: String = ""
var _disc_colors: Dictionary = {}
var _drag_data: Dictionary = {}      # live drag payload; set by TrayTile / GridControl

const INTENT_ORDER: Array = ["heal", "befriend", "seduce", "exploit"]

const DISC_PALETTE: Array = [
	Color(0.937, 0.690, 0.286, 1.0),
	Color(0.592, 0.769, 0.349, 1.0),
	Color(0.447, 0.647, 0.867, 1.0),
	Color(0.867, 0.557, 0.557, 1.0),
	Color(0.753, 0.447, 0.820, 1.0),
	Color(0.353, 0.780, 0.753, 1.0),
	Color(0.890, 0.530, 0.330, 1.0),
	Color(0.630, 0.800, 0.360, 1.0),
]

const INTENT_COLORS: Dictionary = {
	"heal":     Color(0.592, 0.769, 0.349, 1.0),
	"befriend": Color(0.353, 0.624, 0.831, 1.0),
	"seduce":   Color(0.847, 0.659, 0.659, 1.0),
	"exploit":  Color(0.937, 0.690, 0.286, 1.0),
}

const TEXT_PRIMARY: Color = Color(0.961, 0.925, 0.859, 1.0)


func _ready() -> void:
	_ensure_disc_colors()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_title_lbl.text = "Hypothesis Board — %s" % patient.capitalize()
	_close_btn.pressed.connect(queue_free)

	_canvas_nodes = {
		"heal":     _heal_canvas,
		"befriend": _befriend_canvas,
		"seduce":   _seduce_canvas,
		"exploit":  _exploit_canvas,
	}
	for intent_id in INTENT_ORDER:
		_canvas_nodes[intent_id].setup(patient, self)

	_refresh_dock()
	_refresh_footer()

	# Size panel to ~97% of viewport width.
	await get_tree().process_frame
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	_panel.custom_minimum_size = Vector2(minf(vp_size.x * 0.97, 1660), 0)
	_panel.offset_left   = -_panel.custom_minimum_size.x * 0.5
	_panel.offset_right  =  _panel.custom_minimum_size.x * 0.5
	_panel.offset_top    = -vp_size.y * 0.47
	_panel.offset_bottom =  vp_size.y * 0.47


# ─── colour helpers ───────────────────────────────────────────────────────────

func _get_disc_color(disc_id: String) -> Color:
	if disc_id in _disc_colors:
		return _disc_colors[disc_id]
	var idx: int = _disc_colors.size() % DISC_PALETTE.size()
	_disc_colors[disc_id] = DISC_PALETTE[idx]
	return _disc_colors[disc_id]


func _ensure_disc_colors() -> void:
	var discoveries: Array = PatientManager.get_discoveries(patient)
	var ids: Array = []
	for card_res in discoveries:
		var card := card_res as DiscoveryCard
		if card: ids.append(card.id)
	ids.sort()
	for disc_id in ids:
		_get_disc_color(disc_id)


# ─── refresh ──────────────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_refresh_dock()
	for intent_id in INTENT_ORDER:
		_canvas_nodes[intent_id].refresh(patient)
	_refresh_footer()


func _refresh_dock() -> void:
	for child in _dock_stack.get_children():
		child.queue_free()

	var discoveries: Array = PatientManager.get_discoveries(patient)
	if discoveries.is_empty():
		var lbl := Label.new()
		lbl.text = "No pieces yet."
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.5))
		_dock_stack.add_child(lbl)
		return

	var locked_board: bool = HypothesisManager.is_locked(patient)
	var tile_scene: PackedScene = load("res://scenes/ui/tray_tile.tscn")
	for card_res in discoveries:
		var card := card_res as DiscoveryCard
		if card == null: continue
		var tile: TrayTile = tile_scene.instantiate()
		_dock_stack.add_child(tile)
		tile.setup(card.id, self)
		if locked_board:
			tile.modulate = Color(1, 1, 1, 0.45)
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _refresh_footer() -> void:
	var committed: String = HypothesisManager.get_committed_intent(patient)
	if committed.is_empty():
		_footer_label.text = "Committed intent: None"
		_footer_label.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.55))
	else:
		var s: float = HypothesisManager.get_intent_strength(patient, committed)
		_footer_label.text = "Committed: %s  (%.1f)" % [committed.capitalize(), s]
		_footer_label.add_theme_color_override("font_color",
			INTENT_COLORS.get(committed, TEXT_PRIMARY))


# ─── orientation helpers ──────────────────────────────────────────────────────

func _get_orientation(disc_id: String) -> Dictionary:
	if not disc_id in _card_orientations:
		_card_orientations[disc_id] = {"rotation": 0, "flipped": false}
	return _card_orientations[disc_id]


func _set_orientation(disc_id: String, rotation: int, flipped: bool) -> void:
	_card_orientations[disc_id] = {"rotation": rotation, "flipped": flipped}


# ─── key bindings ─────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var dragging: bool = get_viewport().gui_is_dragging()
	# During a drag Godot stops delivering hover events, so _active_disc_id goes stale.
	# Fall back to the live drag payload so rotate/flip always work while holding a piece.
	var disc_id: String = _active_disc_id
	if disc_id.is_empty() and dragging:
		disc_id = _drag_data.get("discovery_id", "")
	match event.keycode:
		KEY_ESCAPE:
			queue_free()
			get_viewport().set_input_as_handled()
		KEY_Q:
			if not disc_id.is_empty():
				_do_rotate(disc_id, -1, dragging)
				get_viewport().set_input_as_handled()
		KEY_E:
			if not disc_id.is_empty():
				_do_rotate(disc_id, 1, dragging)
				get_viewport().set_input_as_handled()
		KEY_R:
			if not disc_id.is_empty():
				_do_flip(disc_id, dragging)
				get_viewport().set_input_as_handled()


func _do_rotate(disc_id: String, delta: int, is_dragging: bool) -> void:
	var orient := _get_orientation(disc_id)
	var new_rot: int = (orient["rotation"] + delta + 4) % 4
	_set_orientation(disc_id, new_rot, orient["flipped"])
	if is_dragging:
		_restart_drag(disc_id, new_rot, orient["flipped"])
	else:
		_try_transform_in_place(disc_id, new_rot, orient["flipped"])
		_update_tray_tile(disc_id, new_rot, orient["flipped"])
		for intent_id in INTENT_ORDER:
			_canvas_nodes[intent_id].refresh(patient)
		_refresh_footer()


func _do_flip(disc_id: String, is_dragging: bool) -> void:
	var orient := _get_orientation(disc_id)
	var new_flip: bool = not orient["flipped"]
	_set_orientation(disc_id, orient["rotation"], new_flip)
	if is_dragging:
		_restart_drag(disc_id, orient["rotation"], new_flip)
	else:
		_try_transform_in_place(disc_id, orient["rotation"], new_flip)
		_update_tray_tile(disc_id, orient["rotation"], new_flip)
		for intent_id in INTENT_ORDER:
			_canvas_nodes[intent_id].refresh(patient)
		_refresh_footer()


func _restart_drag(disc_id: String, new_rot: int, new_flip: bool) -> void:
	## Cancel the active drag and immediately restart it with the new orientation,
	## keeping the same grab-anchor offset so the piece doesn't jump.
	var grab_offset: Vector2 = _drag_data.get("grab_offset", Vector2.ZERO)
	_drag_data["rotation"] = new_rot
	_drag_data["flipped"]  = new_flip
	var data_copy := _drag_data.duplicate()

	var piece := PhysicalPiece.new()
	piece.setup(disc_id, new_rot, new_flip, _get_disc_color(disc_id), PhysicalPiece.CELL_PX)
	piece.set_hovered(true)
	var wrapper := Control.new()
	wrapper.custom_minimum_size = piece.custom_minimum_size
	piece.position = -grab_offset
	wrapper.add_child(piece)

	get_viewport().gui_cancel_drag()
	# force_drag must be deferred one frame to let the cancel propagate.
	(func() -> void:
		if is_instance_valid(self):
			force_drag(data_copy, wrapper)
	).call_deferred()

	for intent_id in INTENT_ORDER:
		_canvas_nodes[intent_id].refresh(patient)


func _update_tray_tile(disc_id: String, new_rot: int, new_flip: bool) -> void:
	for child in _dock_stack.get_children():
		if child is TrayTile and child.discovery_id == disc_id:
			child.update_orientation(new_rot, new_flip)
			return


func _try_transform_in_place(disc_id: String, new_rot: int, new_flip: bool) -> void:
	var canvas_id: String = HypothesisManager.find_placement_canvas(patient, disc_id)
	if canvas_id.is_empty():
		return
	for p in HypothesisManager.get_placements(patient, canvas_id):
		if p["id"] == disc_id:
			if HypothesisManager.can_place(patient, canvas_id, disc_id,
					p["row"], p["col"], new_rot, new_flip, disc_id):
				HypothesisManager.remove_discovery(patient, canvas_id, disc_id)
				HypothesisManager.place_discovery(patient, canvas_id, disc_id,
					p["row"], p["col"], new_rot, new_flip)
			break
