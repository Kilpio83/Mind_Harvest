class_name PatientTabPage
extends VBoxContainer
## One patient tab inside patient_file_view.tscn.
## All structural nodes are in patient_tab_page.tscn — this script is logic only.
## Call populate(show_tooltip_fn, hide_tooltip_fn, photo_popup) in _ready() of the parent.

@export var patient_id: String = ""

@onready var _name_lbl:        Label        = $HeaderPanel/HeaderRow/NameLabel
@onready var _occupation_lbl:  Label        = $HeaderPanel/HeaderRow/OccupationLabel
@onready var _sessions_lbl:    Label        = $HeaderPanel/HeaderRow/SessionsLabel
@onready var _appointment_sep: Label        = $HeaderPanel/HeaderRow/AppointmentSep
@onready var _appointment_lbl: Label        = $HeaderPanel/HeaderRow/AppointmentLabel
@onready var _portrait:        TextureRect  = $Body/LeftScroll/LeftVBox/PortraitZone/Portrait
@onready var _therapy_caption: Label        = $Body/LeftScroll/LeftVBox/TherapyHeader/TherapyCaption
@onready var _therapy_value:   Label        = $Body/LeftScroll/LeftVBox/TherapyHeader/TherapyValue
@onready var _therapy_bar:     ProgressBar  = $Body/LeftScroll/LeftVBox/TherapyBar
@onready var _bond_caption:    Label        = $Body/LeftScroll/LeftVBox/BondHeader/BondCaption
@onready var _bond_value:      Label        = $Body/LeftScroll/LeftVBox/BondHeader/BondValue
@onready var _bond_bar_row:    HBoxContainer = $Body/LeftScroll/LeftVBox/BondBarRow
@onready var _neg_bar:         ProgressBar  = $Body/LeftScroll/LeftVBox/BondBarRow/NegBar
@onready var _bond_center:     VSeparator   = $Body/LeftScroll/LeftVBox/BondBarRow/BondCenter
@onready var _pos_bar:         ProgressBar  = $Body/LeftScroll/LeftVBox/BondBarRow/PosBar
@onready var _intent_value:    Label        = $Body/LeftScroll/LeftVBox/IntentValue
@onready var _hypo_btn:        Button       = $Body/LeftScroll/LeftVBox/HypoBoardBtn
@onready var _notes_container:       VBoxContainer  = $Body/CenterScroll/CenterVBox/NotesContainer
@onready var _discoveries_container: VBoxContainer  = $Body/CenterScroll/CenterVBox/DiscoveriesContainer
@onready var _photos_container:      HFlowContainer = $Body/CenterScroll/CenterVBox/PhotosContainer
@onready var _timeline_container:    VBoxContainer  = $Body/RightScroll/RightVBox/TimelineContainer

const PATIENTS := {
	"anna":    {"display": "Anna Volkov",    "age": 29, "occupation": "Senior Accountant",
				"portrait": "res://assets/portraits/anna/file_header_photo.png"},
	"marisol": {"display": "Marisol Reyes",  "age": 34, "occupation": "Romance Novelist",
				"portrait": "res://assets/portraits/marisol/file_header_photo.png"},
	"kamila":  {"display": "Kamila Vance",   "age": 32, "occupation": "Yoga Instructor",
				"portrait": "res://assets/portraits/kamila/neutral.png"},
}

const _THERAPY_SEGS: Array = [
	["DISENGAGED",    0,  20, Color(0.55, 0.22, 0.22)],
	["GUARDED",      20,  40, Color(0.60, 0.42, 0.18)],
	["OPENING UP",   40,  60, Color(0.68, 0.60, 0.20)],
	["TRUST",        60,  80, Color(0.30, 0.62, 0.28)],
	["BREAKTHROUGH", 80, 100, Color(0.22, 0.70, 0.35)],
]
const _BOND_SEGS: Array = [
	["HOSTILE", -21, 30, Color(0.65, 0.18, 0.18)],
	["DISTANT",  -6, 15, Color(0.60, 0.38, 0.18)],
	["NEUTRAL",   5, 11, Color(0.45, 0.45, 0.45)],
	["WARMING",  20, 15, Color(0.38, 0.60, 0.25)],
	["DEVOTED",  50, 30, Color(0.20, 0.68, 0.32)],
]

var _photo_popup: Control = null


func populate(show_tooltip_fn: Callable, hide_tooltip_fn: Callable,
		photo_popup_ref: Control) -> void:
	_photo_popup = photo_popup_ref
	if patient_id.is_empty():
		return
	var d: Dictionary = PATIENTS.get(patient_id, {})
	if d.is_empty():
		return

	# ── header ──────────────────────────────────────────────────────────────────
	_name_lbl.text       = "%s — Case File" % d["display"]
	_occupation_lbl.text = "%s, %d" % [d["occupation"], d["age"]]
	var progress := int(Dialogic.VAR.get_variable("patients.%s.progress" % patient_id, 0))
	_sessions_lbl.text   = "%d session%s completed" % [progress, "s" if progress != 1 else ""]
	var ending := str(Dialogic.VAR.get_variable("patients.%s.ending" % patient_id, ""))
	if ending.is_empty():
		var next_day := int(Dialogic.VAR.get_variable("patients.%s.next_day" % patient_id, 0))
		if next_day > 0:
			_appointment_sep.visible = true
			_appointment_lbl.visible = true
			_appointment_lbl.text    = "Next appointment: Day %d" % next_day

	# ── portrait ─────────────────────────────────────────────────────────────────
	if ResourceLoader.exists(d["portrait"]):
		_portrait.texture = load(d["portrait"])

	# ── therapy bar ──────────────────────────────────────────────────────────────
	var therapy := int(Dialogic.VAR.get_variable("patients.%s.therapy_progress" % patient_id, 30))
	var therapy_col: Color = MHTokens.ACCENT_SUCCESS
	for i: int in range(_THERAPY_SEGS.size()):
		var seg: Array = _THERAPY_SEGS[i]
		if therapy >= seg[1] and (i == _THERAPY_SEGS.size() - 1 or therapy < seg[2]):
			therapy_col = seg[3]; break
	_therapy_bar.value = therapy
	_therapy_caption.text = _therapy_caption_str(therapy)
	_therapy_caption.add_theme_color_override("font_color", Color(therapy_col, 0.85))
	_therapy_value.text   = "%d / 100" % therapy
	var therapy_fill := StyleBoxFlat.new()
	therapy_fill.bg_color = therapy_col
	_therapy_bar.add_theme_stylebox_override("fill", therapy_fill)
	_therapy_bar.mouse_entered.connect(
		func() -> void: show_tooltip_fn.call(
			func(vb: VBoxContainer) -> void: _fill_therapy_tooltip(vb, therapy),
			_therapy_bar))
	_therapy_bar.mouse_exited.connect(hide_tooltip_fn)

	# ── bond bar ──────────────────────────────────────────────────────────────────
	var bond := int(Dialogic.VAR.get_variable("patients.%s.personal_bond" % patient_id, 0))
	var bond_col: Color = MHTokens.DISC_OBSERVATION
	for i: int in range(_BOND_SEGS.size()):
		var seg: Array = _BOND_SEGS[i]
		if bond <= seg[1] and (i == 0 or bond > _BOND_SEGS[i - 1][1]):
			bond_col = seg[3]; break
	var sign_str := "+" if bond >= 0 else ""
	_bond_caption.text = _bond_caption_str(bond)
	_bond_caption.add_theme_color_override("font_color", Color(bond_col, 0.85))
	_bond_value.text   = "%s%d / 50" % [sign_str, bond]
	_bond_center.add_theme_color_override("color", bond_col)
	var neg_fill := StyleBoxFlat.new()
	neg_fill.bg_color = bond_col if bond < 0 else Color(MHTokens.TEXT_PRIMARY, 0.15)
	_neg_bar.value = max(0, -bond)
	_neg_bar.add_theme_stylebox_override("fill", neg_fill)
	_neg_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	var pos_fill := StyleBoxFlat.new()
	pos_fill.bg_color = bond_col if bond >= 0 else Color(MHTokens.TEXT_PRIMARY, 0.15)
	_pos_bar.value = max(0, bond)
	_pos_bar.add_theme_stylebox_override("fill", pos_fill)
	_pos_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_bond_bar_row.mouse_entered.connect(
		func() -> void: show_tooltip_fn.call(
			func(vb: VBoxContainer) -> void: _fill_bond_tooltip(vb, bond),
			_bond_bar_row))
	_bond_bar_row.mouse_exited.connect(hide_tooltip_fn)

	# ── committed intent ─────────────────────────────────────────────────────────
	var committed := HypothesisManager.get_committed_intent(patient_id)
	_intent_value.text = committed.capitalize() if not committed.is_empty() else "None committed"

	# ── hypothesis board button ───────────────────────────────────────────────────
	_style_primary_btn(_hypo_btn)
	_hypo_btn.pressed.connect(func() -> void:
		var cl := CanvasLayer.new()
		cl.layer = 20
		get_tree().root.add_child(cl)
		var board: Node = load("res://scenes/ui/hypothesis_board.tscn").instantiate()
		board.set("patient", patient_id)
		cl.add_child(board)
		board.tree_exited.connect(cl.queue_free))

	# ── case notes ───────────────────────────────────────────────────────────────
	var notes: Array = PatientManager.notes_by_patient.get(patient_id, [])
	if notes.is_empty():
		_notes_container.add_child(
			_lbl("Nothing recorded yet.", Color(MHTokens.TEXT_PRIMARY, 0.4), MHTokens.FONT_BODY))
	else:
		for note: String in notes:
			var lbl := _lbl("• " + note, Color(MHTokens.TEXT_PRIMARY, 0.8), MHTokens.FONT_BODY)
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_notes_container.add_child(lbl)

	# ── discoveries ──────────────────────────────────────────────────────────────
	var discoveries: Array = PatientManager.get_discoveries(patient_id)
	if discoveries.is_empty():
		_discoveries_container.add_child(
			_lbl("No discoveries recorded.", Color(MHTokens.TEXT_PRIMARY, 0.4), MHTokens.FONT_BODY))
	else:
		for card: DiscoveryCard in discoveries:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			_discoveries_container.add_child(row)
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

	# ── photos ───────────────────────────────────────────────────────────────────
	var photos: Array = PatientManager.photos_by_patient.get(patient_id, [])
	if photos.is_empty():
		_photos_container.add_child(
			_lbl("No photos collected yet.", Color(MHTokens.TEXT_PRIMARY, 0.4), MHTokens.FONT_BODY))
	else:
		for photo: PhotoData in photos:
			_add_photo_thumb(photo)

	# ── timeline ─────────────────────────────────────────────────────────────────
	for i: int in range(progress):
		_add_timeline_entry("Session %d" % (i + 1), "", true)
	if ending.is_empty():
		_add_timeline_entry("Next session — scheduled", "", false)
	else:
		_add_timeline_entry("Arc concluded: %s" % ending, "", true)


# ─── photo popup ─────────────────────────────────────────────────────────────

func _add_photo_thumb(photo: PhotoData) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(130, 150)
	btn.flat = true
	_photos_container.add_child(btn)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(col)
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(120, 110)
	thumb.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if photo.portrait_path != "" and ResourceLoader.exists(photo.portrait_path):
		thumb.texture = load(photo.portrait_path)
	col.add_child(thumb)
	var title_lbl := _lbl(photo.title, MHTokens.TEXT_PRIMARY, MHTokens.FONT_SMALL)
	title_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	col.add_child(title_lbl)
	btn.pressed.connect(func() -> void:
		if _photo_popup == null:
			return
		var popup_photo: TextureRect = _photo_popup.get_node("PopupPhoto")
		popup_photo.texture = null
		if photo.portrait_path != "" and ResourceLoader.exists(photo.portrait_path):
			popup_photo.texture = load(photo.portrait_path)
		_photo_popup.visible = true)


# ─── timeline ────────────────────────────────────────────────────────────────

func _add_timeline_entry(title: String, subtitle: String, past: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_timeline_container.add_child(row)
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


# ─── tooltip fillers ─────────────────────────────────────────────────────────

func _fill_therapy_tooltip(vbox: VBoxContainer, value: int) -> void:
	var hdr := HBoxContainer.new()
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hdr)
	hdr.add_child(_lbl("THERAPY PROGRESS", MHTokens.TEXT_ACCENT, MHTokens.FONT_LABEL))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(hsp)
	hdr.add_child(_lbl("%d / 100" % value, Color(MHTokens.TEXT_PRIMARY, 0.6), MHTokens.FONT_LABEL))
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 2)
	bar_row.custom_minimum_size.y = 28
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bar_row)
	for i: int in range(_THERAPY_SEGS.size()):
		var seg: Array = _THERAPY_SEGS[i]
		var in_seg: bool = value >= seg[1] and (i == _THERAPY_SEGS.size() - 1 or value < seg[2])
		_seg_panel(bar_row, seg[0], seg[3], in_seg, not in_seg and value >= seg[2], 1.0)
	vbox.add_child(_hsep())
	for i: int in range(_THERAPY_SEGS.size()):
		var seg: Array = _THERAPY_SEGS[i]
		var in_seg: bool = value >= seg[1] and (i == _THERAPY_SEGS.size() - 1 or value < seg[2])
		var is_past: bool = not in_seg and value >= seg[2]
		var alpha: float = 0.9 if in_seg else 0.35 if is_past else 0.55
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(row)
		row.add_child(_lbl("▶ " if in_seg else "   ",
			seg[3] if in_seg else Color(MHTokens.TEXT_PRIMARY, alpha), MHTokens.FONT_SMALL))
		row.add_child(_lbl(seg[0],
			seg[3] if in_seg else Color(MHTokens.TEXT_PRIMARY, alpha), MHTokens.FONT_SMALL))
		var rsp := Control.new()
		rsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(rsp)
		row.add_child(_lbl("%d – %d" % [seg[1], seg[2]],
			Color(MHTokens.TEXT_PRIMARY, alpha * 0.65), MHTokens.FONT_LABEL))
	for i: int in range(_THERAPY_SEGS.size()):
		var seg: Array = _THERAPY_SEGS[i]
		var in_seg: bool = value >= seg[1] and (i == _THERAPY_SEGS.size() - 1 or value < seg[2])
		if in_seg and i + 1 < _THERAPY_SEGS.size():
			vbox.add_child(_lbl(
				"Next: %s at %d" % [_THERAPY_SEGS[i + 1][0], seg[2]],
				Color(MHTokens.TEXT_PRIMARY, 0.45), MHTokens.FONT_LABEL))
			break


func _fill_bond_tooltip(vbox: VBoxContainer, bond: int) -> void:
	const BOND_RANGES := ["≤ −21", "−20 to −6", "−5 to +5", "+6 to +20", "≥ +21"]
	var sign_str := "+" if bond >= 0 else ""
	var hdr := HBoxContainer.new()
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hdr)
	hdr.add_child(_lbl("PERSONAL BOND", MHTokens.DISC_OBSERVATION, MHTokens.FONT_LABEL))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(hsp)
	hdr.add_child(_lbl("%s%d / 50" % [sign_str, bond],
		Color(MHTokens.TEXT_PRIMARY, 0.6), MHTokens.FONT_LABEL))
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 2)
	bar_row.custom_minimum_size.y = 28
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bar_row)
	for i: int in range(_BOND_SEGS.size()):
		var seg: Array = _BOND_SEGS[i]
		var in_seg: bool = bond <= seg[1] and (i == 0 or bond > _BOND_SEGS[i - 1][1])
		_seg_panel(bar_row, seg[0], seg[3], in_seg, not in_seg and bond > seg[1], float(seg[2]))
	vbox.add_child(_hsep())
	for i: int in range(_BOND_SEGS.size()):
		var seg: Array = _BOND_SEGS[i]
		var in_seg: bool = bond <= seg[1] and (i == 0 or bond > _BOND_SEGS[i - 1][1])
		var is_past: bool = not in_seg and bond > seg[1]
		var alpha: float = 0.9 if in_seg else 0.35 if is_past else 0.55
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(row)
		row.add_child(_lbl("▶ " if in_seg else "   ",
			seg[3] if in_seg else Color(MHTokens.TEXT_PRIMARY, alpha), MHTokens.FONT_SMALL))
		row.add_child(_lbl(seg[0],
			seg[3] if in_seg else Color(MHTokens.TEXT_PRIMARY, alpha), MHTokens.FONT_SMALL))
		var rsp := Control.new()
		rsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(rsp)
		row.add_child(_lbl(BOND_RANGES[i],
			Color(MHTokens.TEXT_PRIMARY, alpha * 0.65), MHTokens.FONT_LABEL))
	for i: int in range(_BOND_SEGS.size()):
		var seg: Array = _BOND_SEGS[i]
		var in_seg: bool = bond <= seg[1] and (i == 0 or bond > _BOND_SEGS[i - 1][1])
		if in_seg and i + 1 < _BOND_SEGS.size():
			var next_start: int = seg[1] + 1
			var ns := "+" if next_start >= 0 else ""
			vbox.add_child(_lbl(
				"Next: %s at %s%d" % [_BOND_SEGS[i + 1][0], ns, next_start],
				Color(MHTokens.TEXT_PRIMARY, 0.45), MHTokens.FONT_LABEL))
			break


# ─── shared seg-panel helper ─────────────────────────────────────────────────

func _seg_panel(parent: HBoxContainer, label: String, color: Color,
		active: bool, past: bool, stretch: float) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = stretch
	panel.mouse_filter             = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color if active else (Color(color, 0.4) if past else Color(0.110, 0.098, 0.082, 1.0))
	panel.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text                 = label
	lbl.clip_text            = true
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color",
		Color(1, 1, 1, 0.95 if active else 0.45 if past else 0.20))
	panel.add_child(lbl)
	parent.add_child(panel)


# ─── caption helpers ─────────────────────────────────────────────────────────

func _therapy_caption_str(v: int) -> String:
	if   v <= 20: return "Disengaged"
	elif v <= 40: return "Guarded"
	elif v <= 60: return "Opening up"
	elif v <= 80: return "Trust established"
	else:         return "Breakthrough near"


func _bond_caption_str(v: int) -> String:
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

func _style_primary_btn(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 13)
	var s_norm := StyleBoxFlat.new()
	s_norm.bg_color = Color(0.25, 0.23, 0.20, 1.0)
	s_norm.corner_radius_top_left = 6
	s_norm.corner_radius_top_right = 6
	s_norm.corner_radius_bottom_right = 6
	s_norm.corner_radius_bottom_left = 6
	s_norm.content_margin_left = 14.0
	s_norm.content_margin_right = 14.0
	s_norm.content_margin_top = 7.0
	s_norm.content_margin_bottom = 7.0
	var s_hov := s_norm.duplicate() as StyleBoxFlat
	s_hov.bg_color = Color(0.886, 0.639, 0.243, 1.0)
	b.add_theme_stylebox_override("normal",   s_norm)
	b.add_theme_stylebox_override("hover",    s_hov)
	b.add_theme_stylebox_override("pressed",  s_hov)
	b.add_theme_stylebox_override("focus",    s_norm)
	b.add_theme_color_override("font_color",          Color(0.953, 0.933, 0.890, 1.0))
	b.add_theme_color_override("font_hover_color",    Color(0.188, 0.173, 0.153, 1.0))
	b.add_theme_color_override("font_pressed_color",  Color(0.188, 0.173, 0.153, 1.0))
	b.add_theme_color_override("font_focus_color",    Color(0.953, 0.933, 0.890, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.953, 0.933, 0.890, 0.30))


func _lbl(txt: String, col: Color, size: int, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", size)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _hsep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(MHTokens.TEXT_PRIMARY, 0.12))
	return s
