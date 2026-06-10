extends Control
## Hypothesis Board overlay — Ubongo-style polyomino puzzle.
## Pieces in the dock look and feel like physical tiles on a tray.
## Drag to place; Q/E rotate, R flips.  No on-card buttons.

var patient: String = ""

# ─── UI refs ──────────────────────────────────────────────────────────────────
var _dock_stack:        VBoxContainer
var _footer_label:      Label
var _canvas_nodes:      Dictionary = {}   # intent_id → GridControl
var _strength_bars:     Dictionary = {}   # intent_id → ProgressBar
var _strength_labels:   Dictionary = {}   # intent_id → Label
var _filled_labels:     Dictionary = {}   # intent_id → Label
var _locked_badges:     Dictionary = {}   # intent_id → Label
var _card_orientations: Dictionary = {}   # disc_id   → {rotation:int, flipped:bool}

# ─── Active piece (Q/E/R target) ─────────────────────────────────────────────
var _active_disc_id: String = ""

# ─── Per-discovery colours ────────────────────────────────────────────────────
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
var _disc_colors: Dictionary = {}

# ─── Design constants ─────────────────────────────────────────────────────────
const INTENT_ORDER: Array = ["heal", "befriend", "seduce", "exploit"]
const INTENT_DISPLAY: Dictionary = {
	"heal":     {"name": "Heal",     "desc": "Guide toward genuine breakthrough"},
	"befriend": {"name": "Befriend", "desc": "Drop the professional mask"},
	"seduce":   {"name": "Seduce",   "desc": "Pursue genuine romance"},
	"exploit":  {"name": "Exploit",  "desc": "Use her vulnerability for self-gain"},
}
const INTENT_COLORS: Dictionary = {
	"heal":     Color(0.592, 0.769, 0.349, 1.0),
	"befriend": Color(0.353, 0.624, 0.831, 1.0),
	"seduce":   Color(0.847, 0.659, 0.659, 1.0),
	"exploit":  Color(0.937, 0.690, 0.286, 1.0),
}
const PANEL_BG:     Color = Color(0.090, 0.076, 0.063, 0.97)
const CELL_BG:      Color = Color(0.110, 0.094, 0.078, 1.0)
const CUTOUT_BG:    Color = Color(0.040, 0.034, 0.028, 1.0)
const GRID_LINE:    Color = Color(0.280, 0.240, 0.190, 0.5)
const TEXT_PRIMARY: Color = Color(0.961, 0.925, 0.859, 1.0)
const TEXT_MUTED:   Color = Color(0.961, 0.925, 0.859, 0.5)
const FONT_BODY:  int = 16
const FONT_SMALL: int = 13
const FONT_MICRO: int = 11
const CELL_PX:    int = 52   # pixels per grid cell on canvas
const TRAY_CELL:  int = 44   # pixels per cell in the tray (slightly smaller than board)


# ─── Colour helpers ───────────────────────────────────────────────────────────

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
		if card:
			ids.append(card.id)
	ids.sort()
	for disc_id in ids:
		_get_disc_color(disc_id)


# ─── Inner class: PhysicalPiece ───────────────────────────────────────────────
## Draws a polyomino shape. Used in the tray, on drag previews, and inside GridControl.
## cell_size determines rendering scale; hovered = brightened pick-up state.
class PhysicalPiece extends Control:
	var _cells:     Array = []
	var _rows:      int   = 0
	var _cols:      int   = 0
	var _color:     Color = Color.WHITE
	var _cell_size: int   = 44
	var _hovered:   bool  = false

	func setup(disc_id: String, rotation: int, flipped: bool,
			color: Color, cell_size: int) -> void:
		_color     = color
		_cell_size = cell_size
		_hovered   = false
		var card := DiscoveryRegistry.get_card(disc_id)
		if card == null or card.shape.is_empty():
			_cells = []
			_rows  = 1
			_cols  = 1
		else:
			var shape: Array = HypothesisManager.apply_transform(card.shape, rotation, flipped)
			_cells = HypothesisManager.get_cells(shape)
			_rows  = shape.size()
			_cols  = shape[0].size() if _rows > 0 else 1
		custom_minimum_size = Vector2(_cols * _cell_size + 2, _rows * _cell_size + 2)
		size = custom_minimum_size

	func set_hovered(h: bool) -> void:
		if _hovered == h:
			return
		_hovered = h
		queue_redraw()

	func _draw() -> void:
		for cell in _cells:
			var rx: float = cell.y * _cell_size + 1.0
			var ry: float = cell.x * _cell_size + 1.0
			var rw: float = _cell_size - 2.0
			var rh: float = _cell_size - 2.0
			var rect := Rect2(rx, ry, rw, rh)
			# Fill: fully opaque when hovered (ready to lift), slightly dimmed otherwise.
			draw_rect(rect, Color(_color, 1.0 if _hovered else 0.80))
			# Border: bright when hovered to suggest lift-off, subtle otherwise.
			draw_rect(rect, Color(_color * 1.3, 1.0) if _hovered else Color(_color, 0.55),
				false, 2.5 if _hovered else 1.5)


# ─── Inner class: GridControl ─────────────────────────────────────────────────
class GridControl extends Control:
	var board_ref:        Node       = null
	var patient:          String     = ""
	var intent_id:        String     = ""
	var _hover_cell:      Vector2i   = Vector2i(-1, -1)
	var _hover_data:      Dictionary = {}
	var _hovered_disc_id: String     = ""

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

	func _draw() -> void:
		var canvas: Array = HypothesisManager.CANVASES.get(intent_id, [])
		if canvas.is_empty():
			return

		# ── grid background ──
		for r in range(5):
			for c in range(5):
				var rect := Rect2(c * CELL_PX, r * CELL_PX, CELL_PX, CELL_PX)
				if canvas[r][c] == 0:
					draw_rect(rect, board_ref.CUTOUT_BG)
				else:
					draw_rect(rect, board_ref.CELL_BG)
					draw_rect(rect, board_ref.GRID_LINE, false, 1.0)

		# ── placed pieces ──
		for placement in HypothesisManager.get_placements(patient, intent_id):
			var card := DiscoveryRegistry.get_card(placement["id"])
			if card == null:
				continue
			var shape: Array = HypothesisManager.apply_transform(
				card.shape, placement["rotation"], placement["flipped"])
			var piece_col: Color = board_ref._get_disc_color(placement["id"])
			var is_active: bool  = (placement["id"] == board_ref._active_disc_id)
			var cells: Array = HypothesisManager.get_cells(shape)
			for cell in cells:
				var gr: int = placement["row"] + cell.x
				var gc: int = placement["col"] + cell.y
				if gr >= 0 and gr < 5 and gc >= 0 and gc < 5:
					var rect := Rect2(
						gc * CELL_PX + 2, gr * CELL_PX + 2,
						CELL_PX - 4, CELL_PX - 4)
					draw_rect(rect, Color(piece_col, 1.0 if is_active else 0.85))
					draw_rect(rect,
						Color(piece_col * 1.3, 1.0) if is_active else Color(piece_col, 0.55),
						false, 2.5 if is_active else 1.5)
			# Piece name — small, centered on bounding box.
			if cells.size() > 0:
				var min_r := 999; var min_c := 999
				var max_r := 0;   var max_c := 0
				for cell in cells:
					var gr: int = placement["row"] + cell.x
					var gc: int = placement["col"] + cell.y
					if gr < min_r: min_r = gr
					if gc < min_c: min_c = gc
					if gr > max_r: max_r = gr
					if gc > max_c: max_c = gc
				draw_string(ThemeDB.fallback_font,
					Vector2((min_c + (max_c - min_c) * 0.5 + 0.5) * CELL_PX,
							(min_r + (max_r - min_r) * 0.5 + 0.6) * CELL_PX),
					card.short_label.substr(0, 4),
					HORIZONTAL_ALIGNMENT_CENTER, -1, 9,
					Color(board_ref.TEXT_PRIMARY, 0.65))

		# ── drag-hover ghost ──
		if _hover_cell.x >= 0 and _hover_data.has("discovery_id"):
			var card := DiscoveryRegistry.get_card(_hover_data["discovery_id"])
			if card != null and not card.shape.is_empty():
				var shape: Array = HypothesisManager.apply_transform(
					card.shape,
					_hover_data.get("rotation", 0),
					_hover_data.get("flipped", false))
				var cells: Array = HypothesisManager.get_cells(shape)
				var valid: bool = HypothesisManager.can_place(
					patient, intent_id, _hover_data["discovery_id"],
					_hover_cell.x, _hover_cell.y,
					_hover_data.get("rotation", 0),
					_hover_data.get("flipped", false),
					_hover_data["discovery_id"])
				var piece_col: Color = board_ref._get_disc_color(_hover_data["discovery_id"])
				var ghost_fill: Color = Color(0.0, 1.0, 0.0, 0.28) if valid \
					else Color(1.0, 0.0, 0.0, 0.28)
				for cell in cells:
					var gr: int = _hover_cell.x + cell.x
					var gc: int = _hover_cell.y + cell.y
					if gr >= 0 and gr < 5 and gc >= 0 and gc < 5:
						var rect := Rect2(gc * CELL_PX + 2, gr * CELL_PX + 2,
							CELL_PX - 4, CELL_PX - 4)
						draw_rect(rect, ghost_fill)
						draw_rect(rect, Color(piece_col, 0.70), false, 2.0)

	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		if not (data is Dictionary) or not data.has("discovery_id"):
			_hover_cell = Vector2i(-1, -1)
			_hover_data = {}
			queue_redraw()
			return false
		var cell: Vector2i = _pos_to_cell(at_position)
		_hover_cell = cell
		_hover_data = data
		queue_redraw()
		return HypothesisManager.can_place(
			patient, intent_id, data["discovery_id"],
			cell.x, cell.y,
			data.get("rotation", 0), data.get("flipped", false),
			data["discovery_id"])

	func _drop_data(at_position: Vector2, data: Variant) -> void:
		var cell: Vector2i = _pos_to_cell(at_position)
		HypothesisManager.place_discovery(
			patient, intent_id, data["discovery_id"],
			cell.x, cell.y,
			data.get("rotation", 0), data.get("flipped", false))
		_hover_cell = Vector2i(-1, -1)
		_hover_data = {}
		queue_redraw()
		if board_ref:
			board_ref._refresh_all()

	## Lift a placed piece off the canvas by dragging it.
	func _get_drag_data(at_position: Vector2) -> Variant:
		var cell: Vector2i = _pos_to_cell(at_position)
		var disc_id: String = _get_disc_at(cell)
		if disc_id.is_empty() or HypothesisManager.is_locked(patient):
			return null
		var placement: Dictionary = {}
		for p in HypothesisManager.get_placements(patient, intent_id):
			if p["id"] == disc_id:
				placement = p
				break
		if placement.is_empty():
			return null
		set_drag_preview(_make_drag_preview(disc_id, placement["rotation"], placement["flipped"]))
		return {"discovery_id": disc_id, "rotation": placement["rotation"],
				"flipped": placement["flipped"]}

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var disc_id: String = _get_disc_at(_pos_to_cell(event.position))
			if disc_id != _hovered_disc_id:
				_hovered_disc_id = disc_id
				if board_ref:
					board_ref._active_disc_id = disc_id
				mouse_default_cursor_shape = Control.CURSOR_DRAG \
					if not disc_id.is_empty() else Control.CURSOR_ARROW
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
				if board_ref:
					board_ref._active_disc_id = disc_id
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
			if card == null:
				continue
			var shape: Array = HypothesisManager.apply_transform(
				card.shape, placement["rotation"], placement["flipped"])
			for c in HypothesisManager.get_cells(shape):
				if placement["row"] + c.x == cell.x and placement["col"] + c.y == cell.y:
					return placement["id"]
		return ""

	func _pos_to_cell(local_pos: Vector2) -> Vector2i:
		return Vector2i(
			clampi(int(local_pos.y / CELL_PX), 0, 4),
			clampi(int(local_pos.x / CELL_PX), 0, 4))

	func _make_drag_preview(disc_id: String, rotation: int, flipped: bool) -> Control:
		var col: Color = board_ref._get_disc_color(disc_id)
		var piece := PhysicalPiece.new()
		piece.setup(disc_id, rotation, flipped, col, CELL_PX)  # full board size
		piece.set_hovered(true)   # looks lifted
		return piece


# ─── Inner class: TrayTile ────────────────────────────────────────────────────
## A piece resting in the discovery tray.  No buttons, no card chrome —
## just the shape with a tiny name label below it.
class TrayTile extends Control:
	var board_ref:    Node   = null
	var discovery_id: String = ""
	var _rotation:    int    = 0
	var _flipped:     bool   = false
	var _piece_node:  PhysicalPiece = null
	var _hovered:     bool   = false

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
		_build()

	func _build() -> void:
		for child in get_children():
			child.queue_free()

		var col: Color = board_ref._get_disc_color(discovery_id)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		add_child(vbox)

		_piece_node = PhysicalPiece.new()
		_piece_node.setup(discovery_id, _rotation, _flipped, col, TRAY_CELL)
		_piece_node.set_hovered(_hovered)
		vbox.add_child(_piece_node)

		# Compact label row: name + placement badge (if placed).
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var card := DiscoveryRegistry.get_card(discovery_id)
		if card:
			var name_lbl := Label.new()
			name_lbl.text = card.short_label
			name_lbl.add_theme_font_size_override("font_size", board_ref.FONT_MICRO)
			name_lbl.add_theme_color_override("font_color", Color(board_ref.TEXT_PRIMARY, 0.55))
			name_lbl.clip_text = true
			row.add_child(name_lbl)

			var on_canvas: String = HypothesisManager.find_placement_canvas(
				board_ref.patient, discovery_id)
			if not on_canvas.is_empty():
				var badge := Label.new()
				badge.text = "→ " + on_canvas.capitalize()
				badge.add_theme_font_size_override("font_size", board_ref.FONT_MICRO)
				badge.add_theme_color_override("font_color",
					Color(board_ref.INTENT_COLORS.get(on_canvas, Color.WHITE), 0.75))
				row.add_child(badge)

		# Fit the container tightly around the vbox.
		vbox.size = vbox.get_combined_minimum_size()
		custom_minimum_size = vbox.custom_minimum_size

	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_MOUSE_ENTER:
				_hovered = true
				if board_ref:
					board_ref._active_disc_id = discovery_id
				if _piece_node:
					_piece_node.set_hovered(true)
			NOTIFICATION_MOUSE_EXIT:
				_hovered = false
				if board_ref and board_ref._active_disc_id == discovery_id:
					board_ref._active_disc_id = ""
				if _piece_node:
					_piece_node.set_hovered(false)

	func _get_drag_data(_at_pos: Vector2) -> Variant:
		# Drag preview = same piece at full board cell size, looks lifted.
		var col: Color = board_ref._get_disc_color(discovery_id)
		var piece := PhysicalPiece.new()
		piece.setup(discovery_id, _rotation, _flipped, col, CELL_PX)
		piece.set_hovered(true)
		set_drag_preview(piece)
		return {"discovery_id": discovery_id, "rotation": _rotation, "flipped": _flipped}

	func _gui_input(event: InputEvent) -> void:
		# Right-click: return piece to tray (remove from any canvas).
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_RIGHT:
			if not HypothesisManager.is_locked(board_ref.patient):
				HypothesisManager._remove_from_all(board_ref.patient, discovery_id)
				if board_ref:
					board_ref._refresh_all()
				get_viewport().set_input_as_handled()

	## Called by board when Q/E/R keys update this piece's orientation.
	func update_orientation(new_rot: int, new_flip: bool) -> void:
		_rotation = new_rot
		_flipped  = new_flip
		_build()


# ─── Board construction ───────────────────────────────────────────────────────

func _ready() -> void:
	_ensure_disc_colors()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(8)
	sb.border_color = Color(TEXT_PRIMARY, 0.15)
	sb.set_border_width_all(1)
	sb.content_margin_left   = 16
	sb.content_margin_right  = 16
	sb.content_margin_top    = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	_build_header(vbox)
	vbox.add_child(_hsep())
	_build_content(vbox)
	vbox.add_child(_hsep())
	_build_footer(vbox)

	await get_tree().process_frame
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	panel.custom_minimum_size = Vector2(minf(vp_size.x * 0.97, 1660), 0)
	panel.offset_left   = -panel.custom_minimum_size.x * 0.5
	panel.offset_right  =  panel.custom_minimum_size.x * 0.5
	panel.offset_top    = -vp_size.y * 0.47
	panel.offset_bottom =  vp_size.y * 0.47


func _build_header(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	var title := Label.new()
	title.text = "Hypothesis Board — %s" % patient.capitalize()
	title.add_theme_font_size_override("font_size", FONT_BODY)
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕  Close"
	close_btn.add_theme_font_size_override("font_size", FONT_SMALL)
	close_btn.pressed.connect(queue_free)
	hbox.add_child(close_btn)


func _build_content(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(hbox)

	_build_tray(hbox)

	var vsep := VSeparator.new()
	hbox.add_child(vsep)

	_build_canvases(hbox)


func _build_tray(parent: Control) -> void:
	# Outer column: label + scrollable tray.
	var dock := VBoxContainer.new()
	dock.custom_minimum_size.x = 290
	dock.add_theme_constant_override("separation", 8)
	parent.add_child(dock)

	var title := Label.new()
	title.text = "PIECES"
	title.add_theme_font_size_override("font_size", FONT_MICRO)
	title.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.40))
	dock.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dock.add_child(scroll)

	_dock_stack = VBoxContainer.new()
	_dock_stack.add_theme_constant_override("separation", 16)   # generous spacing — feel like objects
	_dock_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_dock_stack)

	_refresh_dock()


func _build_canvases(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	parent.add_child(hbox)

	for intent_id in INTENT_ORDER:
		_build_intent_column(hbox, intent_id)


func _build_intent_column(parent: Control, intent_id: String) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	parent.add_child(col)

	var header_sb := StyleBoxFlat.new()
	var icolor: Color = INTENT_COLORS[intent_id]
	header_sb.bg_color = Color(icolor, 0.22)
	header_sb.set_corner_radius_all(4)
	header_sb.content_margin_left   = 8
	header_sb.content_margin_right  = 8
	header_sb.content_margin_top    = 6
	header_sb.content_margin_bottom = 6
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", header_sb)
	col.add_child(header_panel)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	header_panel.add_child(header_row)

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.color = icolor
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_row.add_child(dot)

	var name_lbl := Label.new()
	name_lbl.text = INTENT_DISPLAY[intent_id]["name"]
	name_lbl.add_theme_font_size_override("font_size", FONT_BODY)
	name_lbl.add_theme_color_override("font_color", icolor)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_lbl)

	var locked_badge := Label.new()
	locked_badge.text = "LOCKED"
	locked_badge.add_theme_font_size_override("font_size", FONT_MICRO)
	locked_badge.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	locked_badge.visible = HypothesisManager.is_intent_locked_out(patient, intent_id)
	header_row.add_child(locked_badge)
	_locked_badges[intent_id] = locked_badge

	var desc := Label.new()
	desc.text = INTENT_DISPLAY[intent_id]["desc"]
	desc.add_theme_font_size_override("font_size", FONT_MICRO)
	desc.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.5))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc)

	var grid := GridControl.new()
	grid.board_ref = self
	grid.patient   = patient
	grid.intent_id = intent_id
	col.add_child(grid)
	_canvas_nodes[intent_id] = grid

	var str_row := HBoxContainer.new()
	str_row.add_theme_constant_override("separation", 6)
	col.add_child(str_row)

	var str_lbl := Label.new()
	str_lbl.text = "Strength"
	str_lbl.add_theme_font_size_override("font_size", FONT_MICRO)
	str_lbl.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.55))
	str_row.add_child(str_lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 14.0
	bar.value     = 0
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_color_override("font_color", icolor)
	str_row.add_child(bar)
	_strength_bars[intent_id] = bar

	var val_lbl := Label.new()
	val_lbl.text = "0.0"
	val_lbl.add_theme_font_size_override("font_size", FONT_MICRO)
	val_lbl.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.7))
	val_lbl.custom_minimum_size.x = 28
	str_row.add_child(val_lbl)
	_strength_labels[intent_id] = val_lbl

	var filled_lbl := Label.new()
	filled_lbl.text = "★ FILLED"
	filled_lbl.add_theme_font_size_override("font_size", FONT_MICRO)
	filled_lbl.add_theme_color_override("font_color", Color(0.937, 0.690, 0.286, 1.0))
	filled_lbl.visible = false
	col.add_child(filled_lbl)
	_filled_labels[intent_id] = filled_lbl

	_refresh_canvas_ui(intent_id)


func _build_footer(parent: Control) -> void:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	parent.add_child(outer)

	_footer_label = Label.new()
	_footer_label.add_theme_font_size_override("font_size", FONT_SMALL)
	_footer_label.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.8))
	outer.add_child(_footer_label)

	# Legend — right-aligned, keyboard chip style.
	var legend_sb := StyleBoxFlat.new()
	legend_sb.bg_color = Color(TEXT_PRIMARY, 0.05)
	legend_sb.set_border_width_all(1)
	legend_sb.border_color = Color(TEXT_PRIMARY, 0.09)
	legend_sb.set_corner_radius_all(4)
	legend_sb.content_margin_left   = 10
	legend_sb.content_margin_right  = 10
	legend_sb.content_margin_top    = 5
	legend_sb.content_margin_bottom = 5
	var legend_panel := PanelContainer.new()
	legend_panel.add_theme_stylebox_override("panel", legend_sb)
	outer.add_child(legend_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	legend_panel.add_child(row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	for entry: Array in [
		["Q", "Rotate ←"],
		["E", "Rotate →"],
		["R", "Flip"],
		["RMB", "Return to tray"],
		["Esc", "Close"],
	]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 5)
		row.add_child(item)

		var key_sb := StyleBoxFlat.new()
		key_sb.bg_color = Color(TEXT_PRIMARY, 0.16)
		key_sb.set_corner_radius_all(3)
		key_sb.content_margin_left   = 5
		key_sb.content_margin_right  = 5
		key_sb.content_margin_top    = 1
		key_sb.content_margin_bottom = 1
		var key_panel := PanelContainer.new()
		key_panel.add_theme_stylebox_override("panel", key_sb)
		item.add_child(key_panel)

		var key_lbl := Label.new()
		key_lbl.text = entry[0]
		key_lbl.add_theme_font_size_override("font_size", FONT_MICRO)
		key_lbl.add_theme_color_override("font_color", TEXT_PRIMARY)
		key_panel.add_child(key_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = entry[1]
		desc_lbl.add_theme_font_size_override("font_size", FONT_MICRO)
		desc_lbl.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.50))
		item.add_child(desc_lbl)

	_refresh_footer()


# ─── Refresh ──────────────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_refresh_dock()
	for intent_id in INTENT_ORDER:
		_refresh_canvas_ui(intent_id)
	_refresh_footer()


func _refresh_dock() -> void:
	for child in _dock_stack.get_children():
		child.queue_free()

	var discoveries: Array = PatientManager.get_discoveries(patient)
	if discoveries.is_empty():
		var lbl := Label.new()
		lbl.text = "No pieces yet."
		lbl.add_theme_font_size_override("font_size", FONT_SMALL)
		lbl.add_theme_color_override("font_color", TEXT_MUTED)
		_dock_stack.add_child(lbl)
		return

	var locked_board: bool = HypothesisManager.is_locked(patient)
	for card_res in discoveries:
		var card := card_res as DiscoveryCard
		if card == null:
			continue
		var tile := TrayTile.new()
		tile.setup(card.id, self)
		if locked_board:
			tile.modulate = Color(1, 1, 1, 0.45)
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dock_stack.add_child(tile)


func _refresh_canvas_ui(intent_id: String) -> void:
	if intent_id in _canvas_nodes:
		_canvas_nodes[intent_id].queue_redraw()

	var strength:   float = HypothesisManager.get_intent_strength(patient, intent_id)
	var full:       bool  = HypothesisManager.is_canvas_full(patient, intent_id)
	var locked_out: bool  = HypothesisManager.is_intent_locked_out(patient, intent_id)

	if intent_id in _strength_bars:
		_strength_bars[intent_id].value = strength
	if intent_id in _strength_labels:
		_strength_labels[intent_id].text = "%.1f" % strength
	if intent_id in _filled_labels:
		_filled_labels[intent_id].visible = full
	if intent_id in _locked_badges:
		_locked_badges[intent_id].visible = locked_out


func _refresh_footer() -> void:
	if not _footer_label:
		return
	var committed: String = HypothesisManager.get_committed_intent(patient)
	if committed.is_empty():
		_footer_label.text = "Committed intent: None"
		_footer_label.add_theme_color_override("font_color", Color(TEXT_PRIMARY, 0.55))
	else:
		var s: float = HypothesisManager.get_intent_strength(patient, committed)
		_footer_label.text = "Committed: %s  (%.1f)" % [committed.capitalize(), s]
		_footer_label.add_theme_color_override(
			"font_color", INTENT_COLORS.get(committed, TEXT_PRIMARY))


# ─── Orientation helpers ──────────────────────────────────────────────────────

func _get_orientation(disc_id: String) -> Dictionary:
	if not disc_id in _card_orientations:
		_card_orientations[disc_id] = {"rotation": 0, "flipped": false}
	return _card_orientations[disc_id]


func _set_orientation(disc_id: String, rotation: int, flipped: bool) -> void:
	_card_orientations[disc_id] = {"rotation": rotation, "flipped": flipped}


# ─── Key bindings ─────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	match event.keycode:
		KEY_ESCAPE:
			queue_free()
			get_viewport().set_input_as_handled()
		KEY_Q:
			if not _active_disc_id.is_empty():
				_apply_rotation(_active_disc_id, -1)
				get_viewport().set_input_as_handled()
		KEY_E:
			if not _active_disc_id.is_empty():
				_apply_rotation(_active_disc_id, 1)
				get_viewport().set_input_as_handled()
		KEY_R:
			if not _active_disc_id.is_empty():
				_apply_flip(_active_disc_id)
				get_viewport().set_input_as_handled()


func _apply_rotation(disc_id: String, delta: int) -> void:
	var orient := _get_orientation(disc_id)
	var new_rot: int = (orient["rotation"] + delta + 4) % 4
	_set_orientation(disc_id, new_rot, orient["flipped"])
	_try_transform_in_place(disc_id, new_rot, orient["flipped"])
	# Live-update the tray tile so the shape visually rotates in hand.
	_update_tray_tile(disc_id, new_rot, orient["flipped"])
	for intent_id in INTENT_ORDER:
		_refresh_canvas_ui(intent_id)
	_refresh_footer()


func _apply_flip(disc_id: String) -> void:
	var orient := _get_orientation(disc_id)
	var new_flip: bool = not orient["flipped"]
	_set_orientation(disc_id, orient["rotation"], new_flip)
	_try_transform_in_place(disc_id, orient["rotation"], new_flip)
	_update_tray_tile(disc_id, orient["rotation"], new_flip)
	for intent_id in INTENT_ORDER:
		_refresh_canvas_ui(intent_id)
	_refresh_footer()


## Update the tray tile shape preview live (without rebuilding the whole dock).
func _update_tray_tile(disc_id: String, new_rot: int, new_flip: bool) -> void:
	for child in _dock_stack.get_children():
		if child is TrayTile and child.discovery_id == disc_id:
			child.update_orientation(new_rot, new_flip)
			return


## Attempt to rotate/flip an already-placed piece in its current canvas position.
## If the new orientation doesn't fit at that anchor, the stored transform is still
## saved so it applies on the next drag.
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


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _hsep() -> HSeparator:
	return HSeparator.new()
