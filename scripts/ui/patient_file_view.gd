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

const LEFT_W  := 240.0
const RIGHT_W := 200.0


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
	bg.content_margin_left = bg.content_margin_right  = 20.0
	bg.content_margin_top  = bg.content_margin_bottom = 11.0

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
		Color(MHTokens.TEXT_PRIMARY, 0.65), 12))
	row.add_child(_dot())

	var progress := int(Dialogic.VAR.get_variable("patients.%s.progress" % pid, 0))
	row.add_child(_lbl("%d session%s completed" % [progress, "s" if progress != 1 else ""],
		Color(MHTokens.TEXT_PRIMARY, 0.65), 12))

	var ending := str(Dialogic.VAR.get_variable("patients.%s.ending" % pid, ""))
	if ending.is_empty():
		var next_day := int(Dialogic.VAR.get_variable("patients.%s.next_day" % pid, 0))
		if next_day > 0:
			row.add_child(_dot())
			row.add_child(_lbl("Next appointment: Day %d" % next_day,
				Color(MHTokens.TEXT_PRIMARY, 0.65), 12))


# ─── left column ─────────────────────────────────────────────────────────────

func _build_left_col(parent: Control, pid: String, d: Dictionary) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = LEFT_W
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size.x = LEFT_W
	vbox.add_theme_constant_override("separation", 10)
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

	# Name / age / occupation
	var name_lbl := _lbl(d["display"], MHTokens.TEXT_PRIMARY, 14, true)
	name_lbl.add_theme_constant_override("margin_left", 12)
	vbox.add_child(name_lbl)

	vbox.add_child(_lbl("%d · %s" % [d["age"], d["occupation"]],
		Color(MHTokens.TEXT_PRIMARY, 0.6), 11))

	vbox.add_child(_hsep())

	# Therapy Progress
	var therapy := int(Dialogic.VAR.get_variable("patients.%s.therapy_progress" % pid, 30))
	_build_meter(vbox,
		"THERAPY PROGRESS", therapy, 0, 100,
		"STRANGER · 0", "BREAKTHROUGH · 100",
		MHTokens.ACCENT_SUCCESS, _therapy_caption(therapy),
		false)

	# Personal Bond
	var bond := int(Dialogic.VAR.get_variable("patients.%s.personal_bond" % pid, 0))
	_build_bond_meter(vbox, bond)

	vbox.add_child(_hsep())

	# Committed Intent (stub until M13)
	vbox.add_child(_section_label("COMMITTED INTENT", MHTokens.TEXT_ACCENT))
	var intent := str(Dialogic.VAR.get_variable("patients.%s.committed_intent" % pid, ""))
	var intent_lbl := _lbl(intent.capitalize() if not intent.is_empty() else "None committed",
		MHTokens.TEXT_PRIMARY, 13)
	vbox.add_child(intent_lbl)
	vbox.add_child(_lbl("Hypothesis board unlocked", Color(MHTokens.TEXT_PRIMARY, 0.45), 11))

	vbox.add_child(_hsep())

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var hypo_btn := _mk_btn("Hypothesis")
	hypo_btn.pressed.connect(func() -> void: pass)  # M12
	btn_row.add_child(hypo_btn)

	var photos: Array = PatientManager.photos_by_patient.get(pid, [])
	var photo_btn := _mk_btn("Photos · %d" % photos.size())
	btn_row.add_child(photo_btn)


func _build_meter(parent: Control, label_text: String, value: int,
		min_val: int, max_val: int,
		left_cap: String, right_cap: String,
		bar_color: Color, caption: String, _signed: bool) -> void:

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 0)
	parent.add_child(header_row)
	header_row.add_child(_section_label(label_text, bar_color))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)
	header_row.add_child(_lbl("%d / %d" % [value, max_val],
		Color(MHTokens.TEXT_PRIMARY, 0.7), 11))

	var bar := ProgressBar.new()
	bar.min_value           = min_val
	bar.max_value           = max_val
	bar.value               = value
	bar.show_percentage     = false
	bar.custom_minimum_size = Vector2(0, 14)
	parent.add_child(bar)

	var cap_row := HBoxContainer.new()
	cap_row.add_theme_constant_override("separation", 0)
	parent.add_child(cap_row)
	cap_row.add_child(_lbl(left_cap,  Color(MHTokens.TEXT_PRIMARY, 0.4), 9))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap_row.add_child(sp)
	cap_row.add_child(_lbl(right_cap, Color(MHTokens.TEXT_PRIMARY, 0.4), 9))

	var cap_lbl := _lbl(caption, Color(MHTokens.TEXT_PRIMARY, 0.6), 11)
	cap_lbl.add_theme_constant_override("margin_top", 2)
	parent.add_child(cap_lbl)


func _build_bond_meter(parent: Control, bond: int) -> void:
	var sign_str := "+" if bond >= 0 else ""

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 0)
	parent.add_child(header_row)
	header_row.add_child(_section_label("PERSONAL BOND", MHTokens.DISC_OBSERVATION))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(sp)
	header_row.add_child(_lbl("%s%d / 50" % [sign_str, bond],
		Color(MHTokens.TEXT_PRIMARY, 0.7), 11))

	# Two-halved bar growing outward from centre
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 2)
	bar_row.custom_minimum_size = Vector2(0, 14)
	parent.add_child(bar_row)

	var neg_bar := ProgressBar.new()
	neg_bar.max_value           = 50
	neg_bar.value               = max(0, -bond)
	neg_bar.show_percentage     = false
	neg_bar.fill_mode           = ProgressBar.FILL_END_TO_BEGIN
	neg_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(neg_bar)

	var center := VSeparator.new()
	center.custom_minimum_size = Vector2(3, 0)
	bar_row.add_child(center)

	var pos_bar := ProgressBar.new()
	pos_bar.max_value           = 50
	pos_bar.value               = max(0, bond)
	pos_bar.show_percentage     = false
	pos_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(pos_bar)

	var cap_row := HBoxContainer.new()
	cap_row.add_theme_constant_override("separation", 0)
	parent.add_child(cap_row)
	cap_row.add_child(_lbl("−50 · HOSTILE", Color(MHTokens.TEXT_PRIMARY, 0.4), 9))
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap_row.add_child(sp2)
	cap_row.add_child(_lbl("DEVOTED · +50", Color(MHTokens.TEXT_PRIMARY, 0.4), 9))

	parent.add_child(_lbl(_bond_caption(bond), Color(MHTokens.TEXT_PRIMARY, 0.6), 11))


# ─── center column ───────────────────────────────────────────────────────────

func _build_center_col(parent: Control, pid: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# ── Case Notes ────────────────────────────────────────────────────────────
	vbox.add_child(_section_label("CASE NOTES", MHTokens.TEXT_ACCENT))

	var notes: Array = PatientManager.notes_by_patient.get(pid, [])
	if notes.is_empty():
		vbox.add_child(_lbl("Nothing recorded yet.", Color(MHTokens.TEXT_PRIMARY, 0.4), 12))
	else:
		for note: String in notes:
			var note_lbl := _lbl("• " + note, Color(MHTokens.TEXT_PRIMARY, 0.8), 12)
			note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(note_lbl)

	vbox.add_child(_hsep())

	# ── Discoveries ───────────────────────────────────────────────────────────
	vbox.add_child(_section_label("DISCOVERIES", MHTokens.TEXT_ACCENT))

	var discoveries: Array = PatientManager.get_discoveries(pid)
	if discoveries.is_empty():
		vbox.add_child(_lbl("No discoveries recorded.", Color(MHTokens.TEXT_PRIMARY, 0.4), 12))
	else:
		for card: DiscoveryCard in discoveries:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			vbox.add_child(row)

			var dot := _lbl("●", _disc_color(card.category), 11)
			row.add_child(dot)

			var card_lbl := _lbl(card.short_label, MHTokens.TEXT_PRIMARY, 12)
			card_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(card_lbl)

	# ── Photos ────────────────────────────────────────────────────────────────
	vbox.add_child(_hsep())
	vbox.add_child(_section_label("PHOTOS", MHTokens.TEXT_ACCENT))

	var photos: Array = PatientManager.photos_by_patient.get(pid, [])
	if photos.is_empty():
		vbox.add_child(_lbl("No photos collected yet.", Color(MHTokens.TEXT_PRIMARY, 0.4), 12))
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
	vbox.add_theme_constant_override("separation", 12)
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
		MHTokens.TEXT_ACCENT if past else Color(MHTokens.TEXT_PRIMARY, 0.4), 12)
	row.add_child(dot)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)

	var title_lbl := _lbl(title,
		MHTokens.TEXT_PRIMARY if past else Color(MHTokens.TEXT_PRIMARY, 0.5), 12)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title_lbl)

	if not subtitle.is_empty():
		col.add_child(_lbl(subtitle, Color(MHTokens.TEXT_PRIMARY, 0.5), 10))


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

	var title_lbl := _lbl(photo.title, MHTokens.TEXT_PRIMARY, 11)
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
	var l := _lbl(txt, col, 10, true)
	l.add_theme_constant_override("margin_top", 4)
	return l


func _mk_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 12)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _dot() -> Label:
	return _lbl("  ·  ", Color(MHTokens.TEXT_PRIMARY, 0.35), 12)


func _vsep() -> VSeparator:
	var s := VSeparator.new()
	s.add_theme_color_override("color", Color(MHTokens.TEXT_PRIMARY, 0.1))
	return s


func _hsep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(MHTokens.TEXT_PRIMARY, 0.12))
	return s
