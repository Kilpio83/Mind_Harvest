extends CanvasLayer
## Patient file view — three-column layout matching the GDD mockup.
## Left: portrait + meters + intent stub + buttons
## Center: case notes + discoveries
## Right: timeline stub
##
## Opened by GameState.open_patient_files().

@onready var _tabs:        TabContainer = $Panel/VBox/Tabs
@onready var _close_btn:   Button       = $Panel/VBox/CloseButton
@onready var _photo_popup: Control      = $PhotoPopup
@onready var _popup_photo: TextureRect  = $PhotoPopup/PopupPhoto
@onready var _popup_close: Button       = $PhotoPopup/PopupClose

const PATIENTS := {
	"anna": {
		"display":    "Anna Volkov",
		"age":        29,
		"occupation": "Senior Accountant",
		"portrait":   "res://assets/portraits/anna/file_header_photo.png",
	},
	"marisol": {
		"display":    "Marisol Reyes",
		"age":        34,
		"occupation": "Romance Novelist",
		"portrait":   "res://assets/portraits/marisol/file_header_photo.png",
	},
}

const LEFT_W  := 360.0
const RIGHT_W := 300.0

# [label, from_inclusive, to_exclusive_for_non_last, color]
const _THERAPY_SEGS: Array = [
	["DISENGAGED",    0,  20, Color(0.55, 0.22, 0.22)],
	["GUARDED",      20,  40, Color(0.60, 0.42, 0.18)],
	["OPENING UP",   40,  60, Color(0.68, 0.60, 0.20)],
	["TRUST",        60,  80, Color(0.30, 0.62, 0.28)],
	["BREAKTHROUGH", 80, 100, Color(0.22, 0.70, 0.35)],
]
# [label, max_inclusive, visual_width, color]
const _BOND_SEGS: Array = [
	["HOSTILE", -21, 30, Color(0.65, 0.18, 0.18)],
	["DISTANT",  -6, 15, Color(0.60, 0.38, 0.18)],
	["NEUTRAL",   5, 11, Color(0.45, 0.45, 0.45)],
	["WARMING",  20, 15, Color(0.38, 0.60, 0.25)],
	["DEVOTED",  50, 30, Color(0.20, 0.68, 0.32)],
]

var _tooltip:      PanelContainer = null
var _tooltip_vbox: VBoxContainer  = null


func _ready() -> void:
	layer = 15

	# Resize panel to ~92 % × 88 % of viewport.
	var vp := get_viewport().get_visible_rect().size
	var panel := $Panel as PanelContainer
	panel.offset_left   = -vp.x * 0.47
	panel.offset_right  =  vp.x * 0.47
	panel.offset_top    = -vp.y * 0.46
	panel.offset_bottom =  vp.y * 0.46

	_close_btn.pressed.connect(queue_free)
	_popup_close.pressed.connect(_on_popup_close)
	_photo_popup.visible = false
	_build_tooltip_overlay()

	for patient_id: String in PATIENTS:
		_build_patient_tab(patient_id, PATIENTS[patient_id])


# ─── tab root ────────────────────────────────────────────────────────────────

func _build_patient_tab(pid: String, d: Dictionary) -> void:
	var root := VBoxContainer.new()
	root.name = d["display"]
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 0)
	_tabs.add_child(root)

	_build_header(root, pid, d)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_build_left_col(body, pid, d)
	body.add_child(_vsep())
	_build_center_col(body, pid)
	body.add_child(_vsep())
	_build_right_col(body, pid)


# ─── header bar ──────────────────────────────────────────────────────────────

func _build_header(parent: Control, pid: String, d: Dictionary) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color            = Color(0.06, 0.05, 0.04, 1.0)
	bg.content_margin_left   = 20.0
	bg.content_margin_right  = 20.0
	bg.content_margin_top    = 11.0
	bg.content_margin_bottom = 11.0

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", bg)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)

	row.add_child(_lbl("%s — Case File" % d["display"], MHTokens.TEXT_PRIMARY, 14, true))
	row.add_child(_dot())
	row.add_child(_lbl("%s, %d" % [d["occupation"], d["age"]],
		Color(MHTokens.TEXT_PRIMARY, 0.65), MHTokens.FONT_BODY))
	row.add_child(_dot())

	var progress := int(Dialogic.VAR.get_variable("patients.%s.progress" % pid, 0))
	row.add_child(_lbl("%d session%s completed" % [progress, "s" if progress != 1 else ""],
		Color(MHTokens.TEXT_PRIMARY, 0.65), MHTokens.FONT_BODY))

	var ending := str(Dialogic.VAR.get_variable("patients.%s.ending" % pid, ""))
	if ending.is_empty():
		var next_day := int(Dialogic.VAR.get_variable("patients.%s.next_day" % pid, 0))
		if next_day > 0:
			row.add_child(_dot())
			row.add_child(_lbl("Next appointment: Day %d" % next_day,
				Color(MHTokens.TEXT_PRIMARY, 0.65), MHTokens.FONT_BODY))


# ─── left column ─────────────────────────────────────────────────────────────

func _build_left_col(parent: Control, pid: String, d: Dictionary) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = LEFT_W
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size.x = LEFT_W
	vbox.add_theme_constant_override("separation", MHTokens.FONT_LABEL)
	var pad := StyleBoxEmpty.new()
	for side: String in ["content_margin_left", "content_margin_right",
						  "content_margin_top",  "content_margin_bottom"]:
		pass  # padding applied via margins below
	scroll.add_child(vbox)

	# Portrait
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(LEFT_W, LEFT_W)
	portrait.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(d["portrait"]):
		portrait.texture = load(d["portrait"])
	vbox.add_child(portrait)

	vbox.add_child(_hsep())

	# Therapy Progress
	var therapy := int(Dialogic.VAR.get_variable("patients.%s.therapy_progress" % pid, 30))
	_build_meter(vbox, "THERAPY PROGRESS", therapy, 0, 100,
		MHTokens.ACCENT_SUCCESS, _therapy_caption(therapy))

	# Personal Bond
	var bond := int(Dialogic.VAR.get_variable("patients.%s.personal_bond" % pid, 0))
	_build_bond_meter(vbox, bond)

	vbox.add_child(_hsep())

	# Committed Intent — reads from HypothesisManager (current strongest) or Dialogic (last locked)
	vbox.add_child(_section_label("COMMITTED INTENT", MHTokens.TEXT_ACCENT))
	var current_intent := HypothesisManager.get_committed_intent(pid)
	var intent_text := current_intent.capitalize() if not current_intent.is_empty() else "None committed"
	vbox.add_child(_lbl(intent_text, MHTokens.TEXT_PRIMARY, MHTokens.FONT_BODY))

	vbox.add_child(_hsep())

	# Buttons
	var hypo_btn := _mk_btn("Hypothesis Board")
	hypo_btn.pressed.connect(func() -> void:
		var cl := CanvasLayer.new()
		cl.layer = 20
		get_tree().root.add_child(cl)
		var board: Node = load("res://scenes/ui/hypothesis_board.tscn").instantiate()
		board.set("patient", pid)
		cl.add_child(board)
		board.tree_exited.connect(cl.queue_free))
	vbox.add_child(hypo_btn)


func _build_meter(parent: Control, label_text: String, value: int,
		min_val: int, max_val: int,
		bar_color: Color, caption: String) -> void:

	# Resolve current segment color for bar fill and caption tint
	var seg_color := bar_color
	for i: int in range(_THERAPY_SEGS.size()):
		var seg: Array = _THERAPY_SEGS[i]
		if value >= seg[1] and (i == _THERAPY_SEGS.size() - 1 or value < seg[2]):
			seg_color = seg[3]
			break

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 0)
	parent.add_child(header_row)
	header_row.add_child(_section_label(label_text, bar_color))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)
	header_row.add_child(_lbl(caption, Color(seg_color, 0.85), MHTokens.FONT_SMALL))
	header_row.add_child(_lbl("  ", Color(MHTokens.TEXT_PRIMARY, 0.0), MHTokens.FONT_LABEL))
	header_row.add_child(_lbl("%d / %d" % [value, max_val],
		Color(MHTokens.TEXT_PRIMARY, 0.7), MHTokens.FONT_SMALL))

	var bar := ProgressBar.new()
	bar.min_value           = min_val
	bar.max_value           = max_val
	bar.value               = value
	bar.show_percentage     = false
	bar.custom_minimum_size = Vector2(0, 14)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = seg_color
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.mouse_entered.connect(func() -> void:
		_show_tooltip(func(vb: VBoxContainer) -> void: _fill_therapy_tooltip(vb, value), bar))
	bar.mouse_exited.connect(_hide_tooltip)
	parent.add_child(bar)


func _build_bond_meter(parent: Control, bond: int) -> void:
	var sign_str := "+" if bond >= 0 else ""

	# Resolve current segment color and caption
	var seg_color := MHTokens.DISC_OBSERVATION
	for i: int in range(_BOND_SEGS.size()):
		var seg: Array = _BOND_SEGS[i]
		if bond <= seg[1] and (i == 0 or bond > _BOND_SEGS[i - 1][1]):
			seg_color = seg[3]
			break

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 0)
	parent.add_child(header_row)
	header_row.add_child(_section_label("PERSONAL BOND", MHTokens.DISC_OBSERVATION))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(sp)
	header_row.add_child(_lbl(_bond_caption(bond), Color(seg_color, 0.85), MHTokens.FONT_SMALL))
	header_row.add_child(_lbl("  ", Color(MHTokens.TEXT_PRIMARY, 0.0), MHTokens.FONT_LABEL))
	header_row.add_child(_lbl("%s%d / 50" % [sign_str, bond],
		Color(MHTokens.TEXT_PRIMARY, 0.7), MHTokens.FONT_SMALL))

	# Two-halved bar growing outward from centre
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 2)
	bar_row.custom_minimum_size = Vector2(0, 14)
	bar_row.mouse_entered.connect(func() -> void:
		_show_tooltip(func(vb: VBoxContainer) -> void: _fill_bond_tooltip(vb, bond), bar_row))
	bar_row.mouse_exited.connect(_hide_tooltip)
	parent.add_child(bar_row)

	var neg_fill := StyleBoxFlat.new()
	neg_fill.bg_color = seg_color if bond < 0 else Color(MHTokens.TEXT_PRIMARY, 0.15)
	var neg_bar := ProgressBar.new()
	neg_bar.max_value             = 50
	neg_bar.value                 = max(0, -bond)
	neg_bar.show_percentage       = false
	neg_bar.fill_mode             = ProgressBar.FILL_END_TO_BEGIN
	neg_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	neg_bar.custom_minimum_size   = Vector2(0, 14)
	neg_bar.mouse_filter          = Control.MOUSE_FILTER_PASS
	neg_bar.add_theme_stylebox_override("fill", neg_fill)
	bar_row.add_child(neg_bar)

	var center := VSeparator.new()
	center.custom_minimum_size = Vector2(3, 0)
	bar_row.add_child(center)

	var pos_fill := StyleBoxFlat.new()
	pos_fill.bg_color = seg_color if bond >= 0 else Color(MHTokens.TEXT_PRIMARY, 0.15)
	var pos_bar := ProgressBar.new()
	pos_bar.max_value             = 50
	pos_bar.value                 = max(0, bond)
	pos_bar.show_percentage       = false
	pos_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pos_bar.custom_minimum_size   = Vector2(0, 14)
	pos_bar.mouse_filter          = Control.MOUSE_FILTER_PASS
	pos_bar.add_theme_stylebox_override("fill", pos_fill)
	bar_row.add_child(pos_bar)


# ─── center column ───────────────────────────────────────────────────────────

func _build_center_col(parent: Control, pid: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", MHTokens.FONT_LABEL)
	scroll.add_child(vbox)

	# ── Case Notes ────────────────────────────────────────────────────────────
	vbox.add_child(_section_label("CASE NOTES", MHTokens.TEXT_ACCENT))

	var notes: Array = PatientManager.notes_by_patient.get(pid, [])
	if notes.is_empty():
		vbox.add_child(_lbl("Nothing recorded yet.", Color(MHTokens.TEXT_PRIMARY, 0.4), MHTokens.FONT_BODY))
	else:
		for note: String in notes:
			var note_lbl := _lbl("• " + note, Color(MHTokens.TEXT_PRIMARY, 0.8), MHTokens.FONT_BODY)
			note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(note_lbl)

	vbox.add_child(_hsep())

	# ── Discoveries ───────────────────────────────────────────────────────────
	vbox.add_child(_section_label("DISCOVERIES", MHTokens.TEXT_ACCENT))

	var discoveries: Array = PatientManager.get_discoveries(pid)
	if discoveries.is_empty():
		vbox.add_child(_lbl("No discoveries recorded.", Color(MHTokens.TEXT_PRIMARY, 0.4), MHTokens.FONT_BODY))
	else:
		for card: DiscoveryCard in discoveries:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			vbox.add_child(row)

			var dot := _lbl("●", _disc_color(card.category), MHTokens.FONT_SMALL)
			dot.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			row.add_child(dot)

			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_theme_constant_override("separation", 2)
			row.add_child(col)

			var card_lbl := _lbl(card.short_label, MHTokens.TEXT_PRIMARY, MHTokens.FONT_BODY)
			card_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(card_lbl)

			var desc_lbl := _lbl(card.description, Color(MHTokens.TEXT_PRIMARY, 0.80), MHTokens.FONT_SMALL)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(desc_lbl)

	# ── Photos ────────────────────────────────────────────────────────────────
	vbox.add_child(_hsep())
	vbox.add_child(_section_label("PHOTOS", MHTokens.TEXT_ACCENT))

	var photos: Array = PatientManager.photos_by_patient.get(pid, [])
	if photos.is_empty():
		vbox.add_child(_lbl("No photos collected yet.", Color(MHTokens.TEXT_PRIMARY, 0.4), MHTokens.FONT_BODY))
	else:
		var grid := HFlowContainer.new()
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(grid)
		for photo: PhotoData in photos:
			_add_photo_thumb(grid, photo)


# ─── right column ─────────────────────────────────────────────────────────────

func _build_right_col(parent: Control, pid: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x  = RIGHT_W
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size.x = RIGHT_W
	vbox.add_theme_constant_override("separation", MHTokens.FONT_BODY)
	scroll.add_child(vbox)

	vbox.add_child(_section_label("TIMELINE", MHTokens.TEXT_ACCENT))

	var progress := int(Dialogic.VAR.get_variable("patients.%s.progress" % pid, 0))
	for i: int in range(progress):
		_add_timeline_entry(vbox,
			"Session %d" % (i + 1),
			"", true)

	var ending := str(Dialogic.VAR.get_variable("patients.%s.ending" % pid, ""))
	if ending.is_empty():
		_add_timeline_entry(vbox, "Next session — scheduled", "", false)
	else:
		_add_timeline_entry(vbox, "Arc concluded: %s" % ending, "", true)


func _add_timeline_entry(parent: Control, title: String, subtitle: String, past: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var dot := _lbl("●" if past else "○",
		MHTokens.TEXT_ACCENT if past else Color(MHTokens.TEXT_PRIMARY, 0.4), MHTokens.FONT_BODY)
	row.add_child(dot)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)

	var title_lbl := _lbl(title,
		MHTokens.TEXT_PRIMARY if past else Color(MHTokens.TEXT_PRIMARY, 0.5), MHTokens.FONT_BODY)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title_lbl)

	if not subtitle.is_empty():
		col.add_child(_lbl(subtitle, Color(MHTokens.TEXT_PRIMARY, 0.5), MHTokens.FONT_LABEL))


# ─── photo popup ─────────────────────────────────────────────────────────────

func _add_photo_thumb(parent: Control, photo: PhotoData) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(130, 150)
	btn.flat = true
	parent.add_child(btn)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(col)

	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(120, 110)
	thumb.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	if photo.portrait_path != "" and ResourceLoader.exists(photo.portrait_path):
		thumb.texture = load(photo.portrait_path)
	col.add_child(thumb)

	var title_lbl := _lbl(photo.title, MHTokens.TEXT_PRIMARY, MHTokens.FONT_SMALL)
	title_lbl.autowrap_mode          = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter           = Control.MOUSE_FILTER_IGNORE
	col.add_child(title_lbl)

	btn.pressed.connect(_show_photo_popup.bind(photo))


func _show_photo_popup(photo: PhotoData) -> void:
	_popup_photo.texture = null
	if photo.portrait_path != "" and ResourceLoader.exists(photo.portrait_path):
		_popup_photo.texture = load(photo.portrait_path)
	_photo_popup.visible = true


func _on_popup_close() -> void:
	_photo_popup.visible  = false
	_popup_photo.texture  = null


# ─── bar tooltip overlay ─────────────────────────────────────────────────────

func _build_tooltip_overlay() -> void:
	_tooltip = PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color              = Color(0.07, 0.06, 0.05, 0.97)
	bg.border_color          = Color(MHTokens.TEXT_ACCENT, 0.35)
	bg.set_border_width_all(1)
	bg.content_margin_left   = 14.0
	bg.content_margin_right  = 14.0
	bg.content_margin_top    = 12.0
	bg.content_margin_bottom = 12.0
	_tooltip.add_theme_stylebox_override("panel", bg)
	_tooltip.custom_minimum_size = Vector2(290, 0)
	_tooltip.visible             = false
	_tooltip.z_index             = 200
	_tooltip.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip)
	_tooltip_vbox = VBoxContainer.new()
	_tooltip_vbox.add_theme_constant_override("separation", 5)
	_tooltip_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(_tooltip_vbox)


func _show_tooltip(filler: Callable, anchor: Control) -> void:
	for c: Node in _tooltip_vbox.get_children():
		c.free()
	filler.call(_tooltip_vbox)
	var vp   := get_viewport().get_visible_rect().size
	var apos := anchor.global_position
	_tooltip.position = Vector2(
		clampf(apos.x, 4.0, vp.x - 298.0),
		apos.y + anchor.size.y + 6.0)
	_tooltip.visible = true


func _hide_tooltip() -> void:
	if _tooltip:
		_tooltip.visible = false


func _seg_panel(parent: HBoxContainer, label: String, color: Color,
		active: bool, past: bool, stretch: float) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = stretch
	panel.mouse_filter             = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	if active:
		style.bg_color = color
	elif past:
		style.bg_color = Color(color, 0.4)
	else:
		style.bg_color = Color(0.13, 0.11, 0.10, 1.0)
	panel.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text                  = label
	lbl.clip_text             = true
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color",
		Color(1.0, 1.0, 1.0, 0.95 if active else 0.45 if past else 0.20))
	panel.add_child(lbl)
	parent.add_child(panel)


func _fill_therapy_tooltip(vbox: VBoxContainer, value: int) -> void:
	# Header
	var hdr := HBoxContainer.new()
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hdr)
	hdr.add_child(_lbl("THERAPY PROGRESS", MHTokens.TEXT_ACCENT, MHTokens.FONT_LABEL))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(hsp)
	hdr.add_child(_lbl("%d / 100" % value, Color(MHTokens.TEXT_PRIMARY, 0.6), MHTokens.FONT_LABEL))

	# Segmented bar (equal widths)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 2)
	bar_row.custom_minimum_size.y = 28
	bar_row.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bar_row)
	for i: int in range(_THERAPY_SEGS.size()):
		var seg: Array   = _THERAPY_SEGS[i]
		var in_seg: bool = value >= seg[1] and (i == _THERAPY_SEGS.size() - 1 or value < seg[2])
		_seg_panel(bar_row, seg[0], seg[3], in_seg, not in_seg and value >= seg[2], 1.0)

	vbox.add_child(_hsep())

	# Threshold legend — all five rows with current highlighted
	for i: int in range(_THERAPY_SEGS.size()):
		var seg: Array   = _THERAPY_SEGS[i]
		var in_seg: bool = value >= seg[1] and (i == _THERAPY_SEGS.size() - 1 or value < seg[2])
		var is_past: bool = not in_seg and value >= seg[2]
		var alpha: float  = 0.9 if in_seg else 0.35 if is_past else 0.55
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(row)
		row.add_child(_lbl("▶ " if in_seg else "   ",
			seg[3] if in_seg else Color(MHTokens.TEXT_PRIMARY, alpha), MHTokens.FONT_SMALL))
		row.add_child(_lbl(seg[0],
			seg[3] if in_seg else Color(MHTokens.TEXT_PRIMARY, alpha), MHTokens.FONT_SMALL))
		var rsp := Control.new()
		rsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rsp.mouse_filter          = Control.MOUSE_FILTER_IGNORE
		row.add_child(rsp)
		row.add_child(_lbl("%d – %d" % [seg[1], seg[2]],
			Color(MHTokens.TEXT_PRIMARY, alpha * 0.65), MHTokens.FONT_LABEL))

	# Next threshold hint
	for i: int in range(_THERAPY_SEGS.size()):
		var seg: Array   = _THERAPY_SEGS[i]
		var in_seg: bool = value >= seg[1] and (i == _THERAPY_SEGS.size() - 1 or value < seg[2])
		if in_seg and i + 1 < _THERAPY_SEGS.size():
			vbox.add_child(_lbl(
				"Next: %s at %d" % [_THERAPY_SEGS[i + 1][0], seg[2]],
				Color(MHTokens.TEXT_PRIMARY, 0.45), MHTokens.FONT_LABEL))
			break


func _fill_bond_tooltip(vbox: VBoxContainer, bond: int) -> void:
	var sign_str := "+" if bond >= 0 else ""

	# Header
	var hdr := HBoxContainer.new()
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hdr)
	hdr.add_child(_lbl("PERSONAL BOND", MHTokens.DISC_OBSERVATION, MHTokens.FONT_LABEL))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsp.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(hsp)
	hdr.add_child(_lbl("%s%d / 50" % [sign_str, bond], Color(MHTokens.TEXT_PRIMARY, 0.6), MHTokens.FONT_LABEL))

	# Segmented bar (proportional widths)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 2)
	bar_row.custom_minimum_size.y = 28
	bar_row.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bar_row)
	for i: int in range(_BOND_SEGS.size()):
		var seg: Array   = _BOND_SEGS[i]
		var in_seg: bool = bond <= seg[1] and (i == 0 or bond > _BOND_SEGS[i - 1][1])
		_seg_panel(bar_row, seg[0], seg[3], in_seg, not in_seg and bond > seg[1], float(seg[2]))

	vbox.add_child(_hsep())

	# Threshold legend with range strings
	const BOND_RANGES := ["≤ −21", "−20 to −6", "−5 to +5", "+6 to +20", "≥ +21"]
	for i: int in range(_BOND_SEGS.size()):
		var seg: Array   = _BOND_SEGS[i]
		var in_seg: bool = bond <= seg[1] and (i == 0 or bond > _BOND_SEGS[i - 1][1])
		var is_past: bool = not in_seg and bond > seg[1]
		var alpha: float  = 0.9 if in_seg else 0.35 if is_past else 0.55
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(row)
		row.add_child(_lbl("▶ " if in_seg else "   ",
			seg[3] if in_seg else Color(MHTokens.TEXT_PRIMARY, alpha), MHTokens.FONT_SMALL))
		row.add_child(_lbl(seg[0],
			seg[3] if in_seg else Color(MHTokens.TEXT_PRIMARY, alpha), MHTokens.FONT_SMALL))
		var rsp := Control.new()
		rsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rsp.mouse_filter          = Control.MOUSE_FILTER_IGNORE
		row.add_child(rsp)
		row.add_child(_lbl(BOND_RANGES[i],
			Color(MHTokens.TEXT_PRIMARY, alpha * 0.65), MHTokens.FONT_LABEL))

	# Next threshold hint
	for i: int in range(_BOND_SEGS.size()):
		var seg: Array   = _BOND_SEGS[i]
		var in_seg: bool = bond <= seg[1] and (i == 0 or bond > _BOND_SEGS[i - 1][1])
		if in_seg and i + 1 < _BOND_SEGS.size():
			var next_start: int = seg[1] + 1
			var ns := "+" if next_start >= 0 else ""
			vbox.add_child(_lbl(
				"Next: %s at %s%d" % [_BOND_SEGS[i + 1][0], ns, next_start],
				Color(MHTokens.TEXT_PRIMARY, 0.45), MHTokens.FONT_LABEL))
			break


# ─── caption helpers ─────────────────────────────────────────────────────────

func _therapy_caption(v: int) -> String:
	if   v <= 20: return "Disengaged"
	elif v <= 40: return "Guarded"
	elif v <= 60: return "Opening up"
	elif v <= 80: return "Trust established"
	else:         return "Breakthrough near"


func _bond_caption(v: int) -> String:
	if   v <= -21: return "Hostile"
	elif v <= -6:  return "Distant"
	elif v <=  5:  return "Neutral"
	elif v <= 20:  return "Warming"
	else:          return "Devoted"


func _disc_color(category: String) -> Color:
	match category:
		"observation":   return MHTokens.DISC_OBSERVATION
		"confession":    return MHTokens.DISC_CONFESSION
		"contradiction": return MHTokens.DISC_CONTRADICTION
		"vulnerability": return MHTokens.DISC_VULNERABILITY
	return MHTokens.TEXT_PRIMARY


# ─── widget helpers ──────────────────────────────────────────────────────────

func _lbl(txt: String, col: Color, size: int, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", size)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _section_label(txt: String, col: Color) -> Label:
	var l := _lbl(txt, col, MHTokens.FONT_LABEL, true)
	l.add_theme_constant_override("margin_top", 4)
	return l


func _mk_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", MHTokens.FONT_BODY)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _dot() -> Label:
	return _lbl("  ·  ", Color(MHTokens.TEXT_PRIMARY, 0.35), MHTokens.FONT_LABEL)


func _vsep() -> VSeparator:
	var s := VSeparator.new()
	s.add_theme_color_override("color", Color(MHTokens.TEXT_PRIMARY, 0.1))
	return s


func _hsep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(MHTokens.TEXT_PRIMARY, 0.12))
	return s
