## HudBar — persistent top-of-screen game-state overlay.
##
## Left cluster:   Day N  ·  Phase  ·  Patient Name
## Right cluster:  INT 2  PAT 3  KNO 1  PER 2
##
## Reads Dialogic variables every 0.25 s.
## Autoloaded as "HudBar" (CanvasLayer, layer = 10) in project.godot.
extends CanvasLayer

# ─── node refs populated in _build() ────────────────────────────────────────
var _day_lbl    : Label
var _phase_lbl  : Label
var _patient_sep: Label
var _patient_lbl: Label
var _stat_val   : Dictionary = {}  # stat key → Label  (value text)

var _t := 0.0
const _INTERVAL := 0.25  # seconds between variable reads


func _ready() -> void:
	layer = 10
	_build()


func _build() -> void:
	# ── root panel ──────────────────────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.custom_minimum_size.y = MHTokens.HUD_HEIGHT

	var sb := StyleBoxFlat.new()
	sb.bg_color              = MHTokens.PANEL_BG_SOFT
	sb.content_margin_top    = 10.0
	sb.content_margin_bottom = 10.0
	sb.content_margin_left   = 20.0
	sb.content_margin_right  = 20.0
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var row := HBoxContainer.new()
	panel.add_child(row)

	# ── left cluster ────────────────────────────────────────────────────────
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", 0)
	row.add_child(left)

	_day_lbl = _lbl("Day 1", MHTokens.TEXT_PRIMARY, MHTokens.FONT_BODY, true)
	left.add_child(_day_lbl)
	left.add_child(_dot())

	_phase_lbl = _lbl("Morning", Color(MHTokens.TEXT_PRIMARY, 0.85), MHTokens.FONT_BODY)
	left.add_child(_phase_lbl)

	_patient_sep         = _dot()
	_patient_sep.visible = false
	left.add_child(_patient_sep)

	_patient_lbl         = _lbl("", Color(MHTokens.TEXT_PRIMARY, 0.85), MHTokens.FONT_BODY)
	_patient_lbl.visible = false
	left.add_child(_patient_lbl)

	# ── spacer ───────────────────────────────────────────────────────────────
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	# ── right cluster ────────────────────────────────────────────────────────
	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 16)
	row.add_child(right)

	for info: Array in [
		["PER", "perception", MHTokens.PER_COLOR],
		["INT", "intellect",  MHTokens.INT_COLOR],
		["KNO", "knowledge",  MHTokens.KNO_COLOR],
		["COM", "composure",  MHTokens.COMP_COLOR],
		["NRV", "nerve",      MHTokens.NRV_COLOR],
	]:
		var grp := HBoxContainer.new()
		grp.add_theme_constant_override("separation", 5)
		right.add_child(grp)
		grp.add_child(_lbl(info[0] as String, info[2] as Color, MHTokens.FONT_LABEL, true))
		var v := _lbl("1", MHTokens.TEXT_PRIMARY, MHTokens.FONT_BODY, true)
		_stat_val[info[1] as String] = v
		grp.add_child(v)


func _process(delta: float) -> void:
	_t += delta
	if _t < _INTERVAL:
		return
	_t = 0.0
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	# Guard: VAR subsystem may not be ready before a timeline starts.
	if not Dialogic.VAR:
		return

	var day   := int(Dialogic.VAR.get_variable("game.day",             1))
	var phase := str(Dialogic.VAR.get_variable("game.phase",           "morning"))
	var pat   := str(Dialogic.VAR.get_variable("game.current_patient", ""))

	_day_lbl.text   = "Day %d" % day
	_phase_lbl.text = phase.capitalize()

	var has_patient := not pat.is_empty()
	_patient_sep.visible = has_patient
	_patient_lbl.visible = has_patient
	if has_patient:
		_patient_lbl.text = _display_name(pat)

	for k: String in _stat_val:
		(_stat_val[k] as Label).text = \
			str(int(Dialogic.VAR.get_variable("stats." + k, 1)))


func _display_name(key: String) -> String:
	match key:
		"anna":    return "Anna Volkov"
		"marisol": return "Marisol Reyes"
		_:         return key.capitalize()


# ─── helpers ─────────────────────────────────────────────────────────────────

func _lbl(txt: String, col: Color, size: int, _bold: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", size)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _dot() -> Label:
	return _lbl("  ·  ", Color(MHTokens.TEXT_PRIMARY, 0.5), MHTokens.FONT_BODY)
