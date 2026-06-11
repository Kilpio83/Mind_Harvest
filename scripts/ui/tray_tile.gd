class_name TrayTile
extends VBoxContainer
## A piece resting in the discovery tray.
## Scene: tray_tile.tscn — PieceSlot (Control) + InfoRow (HBoxContainer) with NameLabel + PlacementBadge.

@onready var _piece_slot:       Control = $PieceSlot
@onready var _name_lbl:         Label   = $InfoRow/NameLabel
@onready var _placement_badge:  Label   = $InfoRow/PlacementBadge

var board_ref:    Node   = null
var discovery_id: String = ""
var _rotation:    int    = 0
var _flipped:     bool   = false
var _piece_node:  PhysicalPiece = null
var _hovered:     bool   = false

const TRAY_CELL: int = 44


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func setup(disc_id: String, bref: Node) -> void:
	board_ref    = bref
	discovery_id = disc_id
	var orient: Dictionary = bref._get_orientation(disc_id)
	_rotation = orient["rotation"]
	_flipped  = orient["flipped"]
	_rebuild_piece()
	_update_labels()


func update_orientation(new_rot: int, new_flip: bool) -> void:
	_rotation = new_rot
	_flipped  = new_flip
	_rebuild_piece()
	_update_labels()


func _rebuild_piece() -> void:
	if _piece_node:
		_piece_node.queue_free()
		_piece_node = null
	var col: Color = board_ref._get_disc_color(discovery_id)
	_piece_node = PhysicalPiece.new()
	_piece_node.setup(discovery_id, _rotation, _flipped, col, TRAY_CELL)
	_piece_node.set_hovered(_hovered)
	_piece_slot.add_child(_piece_node)
	# Resize slot to match piece.
	_piece_slot.custom_minimum_size = _piece_node.custom_minimum_size


func _update_labels() -> void:
	var card := DiscoveryRegistry.get_card(discovery_id)
	if card:
		_name_lbl.text = card.short_label

	var on_canvas: String = HypothesisManager.find_placement_canvas(board_ref.patient, discovery_id)
	if not on_canvas.is_empty():
		_placement_badge.text    = "→ " + on_canvas.capitalize()
		_placement_badge.visible = true
	else:
		_placement_badge.visible = false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_hovered = true
			if board_ref: board_ref._active_disc_id = discovery_id
			if _piece_node: _piece_node.set_hovered(true)
		NOTIFICATION_MOUSE_EXIT:
			_hovered = false
			if board_ref and board_ref._active_disc_id == discovery_id:
				board_ref._active_disc_id = ""
			if _piece_node: _piece_node.set_hovered(false)


func _get_drag_data(at_pos: Vector2) -> Variant:
	var col: Color = board_ref._get_disc_color(discovery_id)
	var piece := PhysicalPiece.new()
	piece.setup(discovery_id, _rotation, _flipped, col, PhysicalPiece.CELL_PX)
	piece.set_hovered(true)

	# Keep the piece anchored to where the player clicked.
	# _piece_node is TRAY_CELL px/cell; drag preview is CELL_PX px/cell — scale accordingly.
	var grab_offset := Vector2.ZERO
	if _piece_node:
		grab_offset = _piece_node.get_local_mouse_position() \
			* (float(PhysicalPiece.CELL_PX) / float(TRAY_CELL))
	grab_offset = grab_offset.clamp(Vector2.ZERO, piece.custom_minimum_size - Vector2.ONE)

	var wrapper := Control.new()
	wrapper.custom_minimum_size = piece.custom_minimum_size
	piece.position = -grab_offset
	wrapper.add_child(piece)
	set_drag_preview(wrapper)

	var data := {"discovery_id": discovery_id, "rotation": _rotation,
				 "flipped": _flipped, "grab_offset": grab_offset}
	if board_ref: board_ref._drag_data = data.duplicate()
	return data


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		if not HypothesisManager.is_locked(board_ref.patient):
			HypothesisManager._remove_from_all(board_ref.patient, discovery_id)
			if board_ref: board_ref._refresh_all()
			get_viewport().set_input_as_handled()
