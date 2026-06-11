class_name GridControl
extends Control
## Draws one intent canvas and handles drag-drop onto it.
## Placed in hypothesis_canvas.tscn; board_ref and patient are wired by HypothesisCanvas.setup().

@export var intent_id: String = ""

var board_ref: Node    = null
var patient:   String  = ""

var _hover_cell:      Vector2i   = Vector2i(-1, -1)
var _hover_data:      Dictionary = {}
var _hovered_disc_id: String     = ""

const CELL_PX: int = 52

# ── colours ───────────────────────────────────────────────────────────────────
const CELL_BG:   Color = Color(0.110, 0.094, 0.078, 1.0)
const CUTOUT_BG: Color = Color(0.040, 0.034, 0.028, 1.0)
const GRID_LINE: Color = Color(0.280, 0.240, 0.190, 0.5)
const TEXT_PRIMARY: Color = Color(0.961, 0.925, 0.859, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(5 * CELL_PX, 5 * CELL_PX)
	size = custom_minimum_size
	mouse_exited.connect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_mouse_exited() -> void:
	_hover_cell = Vector2i(-1, -1)
	_hover_data = {}
	var old_disc: String = _hovered_disc_id
	_hovered_disc_id = ""
	if board_ref and not old_disc.is_empty() and board_ref._active_disc_id == old_disc:
		board_ref._active_disc_id = ""
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		# Fire immediately when cursor enters so a stationary cursor over a piece is recognised.
		var disc_id: String = _get_disc_at(_pos_to_cell(get_local_mouse_position()))
		if disc_id != _hovered_disc_id:
			_hovered_disc_id = disc_id
			if board_ref: board_ref._active_disc_id = disc_id
			mouse_default_cursor_shape = Control.CURSOR_DRAG if not disc_id.is_empty() else Control.CURSOR_ARROW
			queue_redraw()


func _draw() -> void:
	var canvas: Array = HypothesisManager.CANVASES.get(intent_id, [])
	if canvas.is_empty():
		return

	for r in range(5):
		for c in range(5):
			var rect := Rect2(c * CELL_PX, r * CELL_PX, CELL_PX, CELL_PX)
			if canvas[r][c] == 0:
				draw_rect(rect, CUTOUT_BG)
			else:
				draw_rect(rect, CELL_BG)
				draw_rect(rect, GRID_LINE, false, 1.0)

	for placement in HypothesisManager.get_placements(patient, intent_id):
		var card := DiscoveryRegistry.get_card(placement["id"])
		if card == null:
			continue
		var shape: Array = HypothesisManager.apply_transform(
			card.shape, placement["rotation"], placement["flipped"])
		var piece_col: Color = board_ref._get_disc_color(placement["id"])
		var is_active: bool  = (placement["id"] == board_ref._active_disc_id)
		var cells: Array = HypothesisManager.get_cells(shape)
		for cell: Vector2i in cells:
			var gr: int = int(placement["row"]) + cell.x
			var gc: int = int(placement["col"]) + cell.y
			if gr >= 0 and gr < 5 and gc >= 0 and gc < 5:
				var rect := Rect2(gc * CELL_PX + 2, gr * CELL_PX + 2, CELL_PX - 4, CELL_PX - 4)
				draw_rect(rect, Color(piece_col, 1.0 if is_active else 0.85))
				draw_rect(rect,
					Color(piece_col * 1.3, 1.0) if is_active else Color(piece_col, 0.55),
					false, 2.5 if is_active else 1.5)
		if cells.size() > 0:
			var min_r := 999; var min_c := 999; var max_r := 0; var max_c := 0
			for cell: Vector2i in cells:
				var gr: int = int(placement["row"]) + cell.x
				var gc: int = int(placement["col"]) + cell.y
				if gr < min_r: min_r = gr
				if gc < min_c: min_c = gc
				if gr > max_r: max_r = gr
				if gc > max_c: max_c = gc
			draw_string(ThemeDB.fallback_font,
				Vector2((min_c + (max_c - min_c) * 0.5 + 0.5) * CELL_PX,
						(min_r + (max_r - min_r) * 0.5 + 0.6) * CELL_PX),
				card.short_label.substr(0, 4),
				HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(TEXT_PRIMARY, 0.65))

	if _hover_cell.x >= 0 and _hover_data.has("discovery_id"):
		var card := DiscoveryRegistry.get_card(_hover_data["discovery_id"])
		if card != null and not card.shape.is_empty():
			var shape: Array = HypothesisManager.apply_transform(
				card.shape, _hover_data.get("rotation", 0), _hover_data.get("flipped", false))
			var cells: Array = HypothesisManager.get_cells(shape)
			var valid: bool = HypothesisManager.can_place(
				patient, intent_id, _hover_data["discovery_id"],
				_hover_cell.x, _hover_cell.y,
				_hover_data.get("rotation", 0), _hover_data.get("flipped", false),
				_hover_data["discovery_id"])
			# Subtle cell highlight only — no ghost/shadow piece.
			var hi_fill:   Color = Color(0.0, 1.0, 0.0, 0.10) if valid else Color(1.0, 0.0, 0.0, 0.10)
			var hi_border: Color = Color(0.0, 1.0, 0.0, 0.80) if valid else Color(1.0, 0.15, 0.15, 0.80)
			for cell: Vector2i in cells:
				var gr: int = _hover_cell.x + cell.x
				var gc: int = _hover_cell.y + cell.y
				if gr >= 0 and gr < 5 and gc >= 0 and gc < 5:
					var rect := Rect2(gc * CELL_PX, gr * CELL_PX, CELL_PX, CELL_PX)
					draw_rect(rect, hi_fill)
					draw_rect(rect, hi_border, false, 2.0)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or not data.has("discovery_id"):
		_hover_cell = Vector2i(-1, -1); _hover_data = {}; queue_redraw()
		return false
	var cell: Vector2i = _pos_to_cell(at_position)
	_hover_cell = cell; _hover_data = data; queue_redraw()
	return HypothesisManager.can_place(patient, intent_id, data["discovery_id"],
		cell.x, cell.y, data.get("rotation", 0), data.get("flipped", false),
		data["discovery_id"])


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var cell: Vector2i = _pos_to_cell(at_position)
	HypothesisManager.place_discovery(patient, intent_id, data["discovery_id"],
		cell.x, cell.y, data.get("rotation", 0), data.get("flipped", false))
	_hover_cell = Vector2i(-1, -1); _hover_data = {}; queue_redraw()
	if board_ref:
		board_ref._drag_data = {}
		board_ref._refresh_all()


func _get_drag_data(at_position: Vector2) -> Variant:
	var cell: Vector2i = _pos_to_cell(at_position)
	var disc_id: String = _get_disc_at(cell)
	if disc_id.is_empty() or HypothesisManager.is_locked(patient):
		return null
	var placement: Dictionary = {}
	for p in HypothesisManager.get_placements(patient, intent_id):
		if p["id"] == disc_id:
			placement = p; break
	if placement.is_empty():
		return null
	var col: Color = board_ref._get_disc_color(disc_id)
	var piece := PhysicalPiece.new()
	piece.setup(disc_id, placement["rotation"], placement["flipped"], col, CELL_PX)
	piece.set_hovered(true)

	# Anchor the preview to the exact cell that was clicked.
	var piece_top_left := Vector2(int(placement["col"]) * CELL_PX, int(placement["row"]) * CELL_PX)
	var grab_offset: Vector2 = (at_position - piece_top_left).clamp(
		Vector2.ZERO, piece.custom_minimum_size - Vector2.ONE)

	var wrapper := Control.new()
	wrapper.custom_minimum_size = piece.custom_minimum_size
	piece.position = -grab_offset
	wrapper.add_child(piece)
	set_drag_preview(wrapper)

	var data := {"discovery_id": disc_id, "rotation": placement["rotation"],
				 "flipped": placement["flipped"], "grab_offset": grab_offset}
	if board_ref: board_ref._drag_data = data.duplicate()
	return data


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var disc_id: String = _get_disc_at(_pos_to_cell(event.position))
		if disc_id != _hovered_disc_id:
			_hovered_disc_id = disc_id
			if board_ref: board_ref._active_disc_id = disc_id
			mouse_default_cursor_shape = Control.CURSOR_DRAG if not disc_id.is_empty() else Control.CURSOR_ARROW
			queue_redraw()
		return
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var cell: Vector2i = _pos_to_cell(event.position)
	var disc_id: String = _get_disc_at(cell)
	if disc_id.is_empty():
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if board_ref: board_ref._active_disc_id = disc_id
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_RIGHT:
			if not HypothesisManager.is_locked(patient):
				HypothesisManager.remove_discovery(patient, intent_id, disc_id)
				_hovered_disc_id = ""
				mouse_default_cursor_shape = Control.CURSOR_ARROW
				if board_ref:
					if board_ref._active_disc_id == disc_id:
						board_ref._active_disc_id = ""
					board_ref._refresh_all()
				queue_redraw()
				get_viewport().set_input_as_handled()


func _get_disc_at(cell: Vector2i) -> String:
	for placement in HypothesisManager.get_placements(patient, intent_id):
		var card := DiscoveryRegistry.get_card(placement["id"])
		if card == null: continue
		var shape: Array = HypothesisManager.apply_transform(card.shape, placement["rotation"], placement["flipped"])
		for c: Vector2i in HypothesisManager.get_cells(shape):
			if int(placement["row"]) + c.x == cell.x and int(placement["col"]) + c.y == cell.y:
				return placement["id"]
	return ""


func _pos_to_cell(local_pos: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(local_pos.y / CELL_PX), 0, 4),
		clampi(int(local_pos.x / CELL_PX), 0, 4))
