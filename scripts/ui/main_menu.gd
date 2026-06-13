extends CanvasLayer

@onready var _vbox:      VBoxContainer = $Panel/VBox
@onready var _slots_ctr: VBoxContainer = $Panel/VBox/SlotsContainer
@onready var _title_lbl: Label         = $Panel/VBox/TitleLabel
@onready var _sub_lbl:   Label         = $Panel/VBox/SubtitleLabel

var _font: Font = null
var _pending_new_game_slot: String = ""
var _confirm_overlay: ColorRect = null
var _confirm_detail:  Label = null

const _GOLD      := Color(0.886, 0.639, 0.243, 1.0)
const _WHITE     := Color(0.953, 0.933, 0.890, 0.85)
const _WHITE_DIM := Color(0.953, 0.933, 0.890, 0.38)
const _WHITE_OFF := Color(0.953, 0.933, 0.890, 0.18)
const _HDR_CLR   := Color(0.953, 0.933, 0.890, 0.28)

# Table column widths (px)
const _COL_DAY := 46.0
const _COL_TS  := 138.0
const _COL_ACT := 186.0
const _COL_GAP := 10.0


func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/Mulish-SemiBold.ttf"):
		_font = load("res://assets/fonts/Mulish-SemiBold.ttf")
	_apply_title_font()
	_build_slots()
	_build_footer()
	_build_confirm_dialog()


func _apply_title_font() -> void:
	if not _font:
		return
	_title_lbl.add_theme_font_override("font", _font)
	_sub_lbl.add_theme_font_override("font", _font)


# ── table ─────────────────────────────────────────────────────────────────────

func _build_slots() -> void:
	for c in _slots_ctr.get_children():
		c.queue_free()

	_add_header()

	var auto_info := SaveManager.get_slot_info(SaveManager.AUTOSAVE_SLOT)
	if not auto_info.is_empty():
		_slots_ctr.add_child(_make_auto_row(auto_info))
		_slots_ctr.add_child(_thin_sep())

	for i in range(1, SaveManager.MAX_MANUAL_SLOTS + 1):
		var slot := "slot_%d" % i
		_slots_ctr.add_child(_make_slot_row(slot, i, SaveManager.get_slot_info(slot)))
		if i < SaveManager.MAX_MANUAL_SLOTS:
			_slots_ctr.add_child(_thin_sep())


func _add_header() -> void:
	var row := _row()
	_slots_ctr.add_child(row)

	var n := _hlbl("Name")
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(n)
	row.add_child(_gap(_COL_GAP))

	var d := _hlbl("Day")
	d.custom_minimum_size.x = _COL_DAY
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(d)
	row.add_child(_gap(_COL_GAP))

	var t := _hlbl("Saved")
	t.custom_minimum_size.x = _COL_TS
	row.add_child(t)
	row.add_child(_gap(_COL_GAP))

	var ph := Control.new()  # placeholder keeps actions column aligned in header
	ph.custom_minimum_size.x = _COL_ACT
	row.add_child(ph)

	_slots_ctr.add_child(_divider())


func _make_auto_row(info: Dictionary) -> HBoxContainer:
	var row := _row(8)

	var name_box := HBoxContainer.new()
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.add_theme_constant_override("separation", 4)
	var nl := _dlbl("Autosave")
	nl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	name_box.add_child(nl)
	var tag := _dlbl("auto")
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", _WHITE_DIM)
	name_box.add_child(tag)
	row.add_child(name_box)

	row.add_child(_gap(_COL_GAP))
	row.add_child(_day_lbl(str(info["day"]), _WHITE_DIM))
	row.add_child(_gap(_COL_GAP))
	row.add_child(_ts_lbl(_fmt_date(info.get("date", "")), _WHITE_DIM))
	row.add_child(_gap(_COL_GAP))

	var acts := _acts()
	var ac := _btn("Continue", _on_load.bind(SaveManager.AUTOSAVE_SLOT), true)
	ac.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acts.add_child(ac)
	row.add_child(acts)

	return row


func _make_slot_row(slot: String, idx: int, info: Dictionary) -> HBoxContainer:
	var row := _row(8)

	if not info.is_empty():
		var display: String = info.get("name", "")
		if display.is_empty():
			display = "Slot %d" % idx
		var nl := _dlbl(display)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(nl)
		row.add_child(_gap(_COL_GAP))
		row.add_child(_day_lbl(str(info["day"]), _WHITE_DIM))
		row.add_child(_gap(_COL_GAP))
		row.add_child(_ts_lbl(_fmt_date(info.get("date", "")), _WHITE_DIM))
		row.add_child(_gap(_COL_GAP))
		var acts := _acts()
		var ng := _btn("New Game", func() -> void: _request_new_game(slot, info), true)
		ng.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		acts.add_child(ng)
		var cn := _btn("Continue", _on_load.bind(slot), true)
		cn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		acts.add_child(cn)
		row.add_child(acts)
	else:
		var el := _dlbl("Slot %d  —  empty" % idx)
		el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		el.add_theme_color_override("font_color", _WHITE_OFF)
		row.add_child(el)
		row.add_child(_gap(_COL_GAP))
		row.add_child(_day_lbl("—", _WHITE_OFF))
		row.add_child(_gap(_COL_GAP))
		row.add_child(_ts_lbl("", _WHITE_OFF))
		row.add_child(_gap(_COL_GAP))
		var acts := _acts()
		var ng := _btn("New Game", _on_new_game.bind(slot), true)
		ng.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		acts.add_child(ng)
		row.add_child(acts)  # single btn fills full column — no Continue yet

	return row


# ── footer ────────────────────────────────────────────────────────────────────

func _build_footer() -> void:
	_vbox.add_child(_sep(20))
	_vbox.add_child(_display_section())


func _display_section() -> VBoxContainer:
	var sec := VBoxContainer.new()
	sec.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = "DISPLAY MODE"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font: lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", _HDR_CLR)
	sec.add_child(lbl)
	sec.add_child(_mode_toggle())
	return sec


func _mode_toggle() -> Control:
	var current := SettingsManager.get_window_mode()
	var count   := SettingsManager.WINDOW_LABELS.size()

	var seg := HBoxContainer.new()
	seg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	seg.add_theme_constant_override("separation", 6)

	var btns:  Array[Button]       = []
	var norms: Array[StyleBoxFlat] = []
	var acts:  Array[StyleBoxFlat] = []

	for i in range(count):
		var s_norm := _sbox_solid(Color(0.25, 0.23, 0.20, 1.0))
		var s_act  := _sbox_solid(Color(0.886, 0.639, 0.243, 1.0))
		norms.append(s_norm)
		acts.append(s_act)

		var b := Button.new()
		b.text = SettingsManager.WINDOW_LABELS[i]
		if _font: b.add_theme_font_override("font", _font)
		b.add_theme_font_size_override("font_size", 12)
		var active := i == current
		b.add_theme_stylebox_override("normal",   s_act if active else s_norm)
		b.add_theme_stylebox_override("hover",    s_act)
		b.add_theme_stylebox_override("pressed",  s_act)
		b.add_theme_stylebox_override("focus",    s_act if active else s_norm)
		b.add_theme_color_override("font_color",         Color(0.188, 0.173, 0.153, 1.0) if active else Color(0.953, 0.933, 0.890, 1.0))
		b.add_theme_color_override("font_hover_color",   Color(0.188, 0.173, 0.153, 1.0))
		b.add_theme_color_override("font_pressed_color", Color(0.188, 0.173, 0.153, 1.0))
		b.add_theme_color_override("font_focus_color",   Color(0.188, 0.173, 0.153, 1.0) if active else Color(0.953, 0.933, 0.890, 1.0))
		b.add_theme_color_override("font_disabled_color", Color(0.953, 0.933, 0.890, 0.30))
		seg.add_child(b)
		btns.append(b)

	for i in range(btns.size()):
		var idx := i
		btns[i].pressed.connect(func() -> void:
			SettingsManager.set_window_mode(idx)
			for j in range(btns.size()):
				var a := j == idx
				btns[j].add_theme_stylebox_override("normal", acts[j] if a else norms[j])
				btns[j].add_theme_stylebox_override("focus",  acts[j] if a else norms[j])
				btns[j].add_theme_color_override("font_color",
					Color(0.188, 0.173, 0.153, 1.0) if a else Color(0.953, 0.933, 0.890, 1.0)))

	return seg


# ── widget helpers ─────────────────────────────────────────────────────────────

func _row(v_margin: int = 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	if v_margin > 0:
		h.add_theme_constant_override("margin_top",    v_margin)
		h.add_theme_constant_override("margin_bottom", v_margin)
	return h


func _acts() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.custom_minimum_size.x = _COL_ACT
	h.add_theme_constant_override("separation", 6)
	return h


func _gap(w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.x = w
	return c


func _hlbl(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	if _font: l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", _HDR_CLR)
	return l


func _dlbl(text: String) -> Label:
	var l := Label.new()
	l.text = text
	if _font: l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", _WHITE)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _day_lbl(text: String, color: Color) -> Label:
	var l := _dlbl(text)
	l.custom_minimum_size.x = _COL_DAY
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	return l


func _ts_lbl(text: String, color: Color) -> Label:
	var l := _dlbl(text)
	l.custom_minimum_size.x = _COL_TS
	l.add_theme_color_override("font_color", color)
	return l


func _sep(v_pad: int = 12) -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(0.953, 0.933, 0.890, 0.08))
	s.add_theme_constant_override("separation", v_pad)
	return s


func _thin_sep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(0.953, 0.933, 0.890, 0.06))
	s.add_theme_constant_override("separation", 4)
	return s


func _divider() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(0.953, 0.933, 0.890, 0.10))
	s.add_theme_constant_override("separation", 8)
	return s


func _btn(text: String, callback: Callable, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	if _font: b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_disabled_color", Color(0.953, 0.933, 0.890, 0.30))
	if primary:
		var s_norm := _sbox_solid(Color(0.25, 0.23, 0.20, 1.0))
		var s_hov  := _sbox_solid(Color(0.886, 0.639, 0.243, 1.0))
		var s_dis  := _sbox_solid(Color(0.18, 0.16, 0.14, 1.0))
		b.add_theme_stylebox_override("normal",   s_norm)
		b.add_theme_stylebox_override("hover",    s_hov)
		b.add_theme_stylebox_override("pressed",  s_hov)
		b.add_theme_stylebox_override("focus",    s_norm)
		b.add_theme_stylebox_override("disabled", s_dis)
		b.add_theme_color_override("font_color",         Color(0.953, 0.933, 0.890, 1.0))
		b.add_theme_color_override("font_hover_color",   Color(0.188, 0.173, 0.153, 1.0))
		b.add_theme_color_override("font_pressed_color", Color(0.188, 0.173, 0.153, 1.0))
		b.add_theme_color_override("font_focus_color",   Color(0.953, 0.933, 0.890, 1.0))
	else:
		b.add_theme_stylebox_override("normal",   _sbox(Color(0.953, 0.933, 0.890, 0.04), Color(0.953, 0.933, 0.890, 0.12)))
		b.add_theme_stylebox_override("hover",    _sbox(Color(0.886, 0.639, 0.243, 0.10), Color(0.886, 0.639, 0.243, 0.45)))
		b.add_theme_stylebox_override("pressed",  _sbox(Color(0.886, 0.639, 0.243, 0.18), Color(0.886, 0.639, 0.243, 0.85)))
		b.add_theme_stylebox_override("focus",    _sbox(Color(0.953, 0.933, 0.890, 0.04), Color(0.953, 0.933, 0.890, 0.12)))
		b.add_theme_stylebox_override("disabled", _sbox(Color(0.0, 0.0, 0.0, 0.0),        Color(0.953, 0.933, 0.890, 0.05)))
		b.add_theme_color_override("font_color",         Color(0.953, 0.933, 0.890, 0.72))
		b.add_theme_color_override("font_hover_color",   _GOLD)
		b.add_theme_color_override("font_pressed_color", _GOLD)
		b.add_theme_color_override("font_focus_color",   Color(0.953, 0.933, 0.890, 0.72))
	b.pressed.connect(callback)
	return b


func _sbox_solid(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_right = 6
	s.corner_radius_bottom_left = 6
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 7.0
	s.content_margin_bottom = 7.0
	return s


func _sbox(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = border
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left = 8
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 7.0
	s.content_margin_bottom = 7.0
	return s


func _fmt_date(iso: String) -> String:
	if iso.is_empty(): return ""
	var parts := iso.split("T")
	if parts.size() < 2: return iso
	var tp := parts[1].split(":")
	if tp.size() < 2: return iso
	return "%s %s:%s" % [parts[0], tp[0], tp[1]]


# ── new-game confirmation ─────────────────────────────────────────────────────

func _build_confirm_dialog() -> void:
	_confirm_overlay = ColorRect.new()
	_confirm_overlay.anchors_preset = 15
	_confirm_overlay.anchor_right = 1.0
	_confirm_overlay.anchor_bottom = 1.0
	_confirm_overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	_confirm_overlay.visible = false
	add_child(_confirm_overlay)

	var panel := PanelContainer.new()
	panel.anchors_preset = 8
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = 2
	panel.grow_vertical = 2
	panel.offset_left = -200.0
	panel.offset_right = 200.0
	panel.offset_top = -85.0
	panel.offset_bottom = 85.0
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.110, 0.098, 0.082, 0.99)
	psb.border_width_left = 1
	psb.border_width_top = 1
	psb.border_width_right = 1
	psb.border_width_bottom = 1
	psb.border_color = Color(0.886, 0.639, 0.243, 0.35)
	psb.corner_radius_top_left = 12
	psb.corner_radius_top_right = 12
	psb.corner_radius_bottom_right = 12
	psb.corner_radius_bottom_left = 12
	psb.content_margin_left = 24.0
	psb.content_margin_right = 24.0
	psb.content_margin_top = 20.0
	psb.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", psb)
	_confirm_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Overwrite save and start new game?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font: title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", _WHITE)
	vbox.add_child(title)

	_confirm_detail = Label.new()
	_confirm_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font: _confirm_detail.add_theme_font_override("font", _font)
	_confirm_detail.add_theme_font_size_override("font_size", 12)
	_confirm_detail.add_theme_color_override("font_color", _WHITE_DIM)
	vbox.add_child(_confirm_detail)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var cancel := _btn("Cancel", func() -> void: _confirm_overlay.visible = false, true)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(cancel)

	var ok := _btn("New Game", _do_new_game, true)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(ok)


func _request_new_game(slot_name: String, info: Dictionary) -> void:
	_pending_new_game_slot = slot_name
	var name_str: String = info.get("name", "")
	if name_str.is_empty(): name_str = slot_name
	var parts := [name_str]
	if info.has("day"): parts.append("Day %d" % info["day"])
	var ts := _fmt_date(info.get("date", ""))
	if not ts.is_empty(): parts.append(ts)
	_confirm_detail.text = "  ·  ".join(parts)
	_confirm_overlay.visible = true


func _do_new_game() -> void:
	_confirm_overlay.visible = false
	_on_new_game(_pending_new_game_slot)


# ── callbacks ─────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _confirm_overlay != null and _confirm_overlay.visible:
			get_viewport().set_input_as_handled()
			_confirm_overlay.visible = false


func _on_new_game(slot_name: String) -> void:
	SaveManager.current_save_slot = slot_name
	GameState.reset_game()
	queue_free()
	Dialogic.start("intro")


func _on_load(slot_name: String) -> void:
	SaveManager.current_save_slot = slot_name
	queue_free()
	SaveManager.load_from_slot(slot_name)
