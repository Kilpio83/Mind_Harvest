class_name PhysicalPiece
extends Control
## Draws a single polyomino piece as colored cells.
## Used in the tray (TRAY_CELL size), drag previews (CELL_PX size), and on canvases.

const CELL_PX:  int = 52
const TRAY_CELL: int = 44

var _cells:     Array = []
var _rows:      int   = 0
var _cols:      int   = 0
var _color:     Color = Color.WHITE
var _cell_size: int   = 44
var _hovered:   bool  = false


func setup(disc_id: String, rotation: int, flipped: bool,
		color: Color, cell_size: int = 44) -> void:
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
	queue_redraw()


func set_hovered(h: bool) -> void:
	if _hovered == h:
		return
	_hovered = h
	queue_redraw()


func _draw() -> void:
	for cell in _cells:
		var rect := Rect2(
			cell.y * _cell_size + 1.0,
			cell.x * _cell_size + 1.0,
			_cell_size - 2.0,
			_cell_size - 2.0)
		draw_rect(rect, Color(_color, 1.0 if _hovered else 0.80))
		draw_rect(rect,
			Color(_color * 1.3, 1.0) if _hovered else Color(_color, 0.55),
			false, 2.5 if _hovered else 1.5)
