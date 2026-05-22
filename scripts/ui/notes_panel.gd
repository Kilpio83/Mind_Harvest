extends CanvasLayer
## In-session notes panel. Displayed on the right side of the screen during
## OfferNotes events. Pauses the timeline until the player picks or skips.
##
## Emits chosen(discovery_id) — empty string means "Skip".

signal chosen(discovery_id: String)

var _title_text: String    = "What do you note?"
var _ids:        Array[String] = []
var _allow_skip: bool      = true

const PANEL_W := 284.0


func _init() -> void:
	layer = 25  # above Dialogic canvas


func setup(title: String, ids: Array[String], allow_skip: bool) -> void:
	_title_text = title
	_ids        = ids
	_allow_skip = allow_skip


func _ready() -> void:
	_build()


func _build() -> void:
	var container := PanelContainer.new()
	# Anchor to bottom-right, sit just above the dialogue box area.
	container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	container.offset_right  = -20.0
	container.offset_bottom = -160.0
	container.offset_left   = -PANEL_W - 20.0
	container.offset_top    = -160.0   # grows upward via GROW_DIRECTION_BEGIN
	container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	container.custom_minimum_size.x = PANEL_W

	var sb := StyleBoxFlat.new()
	sb.bg_color                  = MHTokens.PANEL_BG_STRONG
	sb.corner_radius_top_left    = MHTokens.TOAST_RADIUS
	sb.corner_radius_top_right   = MHTokens.TOAST_RADIUS
	sb.corner_radius_bottom_left = MHTokens.TOAST_RADIUS
	sb.corner_radius_bottom_right = MHTokens.TOAST_RADIUS
	sb.content_margin_left   = 16.0
	sb.content_margin_right  = 16.0
	sb.content_margin_top    = 14.0
	sb.content_margin_bottom = 14.0
	container.add_theme_stylebox_override("panel", sb)
	add_child(container)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# ── title ────────────────────────────────────────────────────────────────
	var title_lbl := Label.new()
	title_lbl.text = _title_text
	title_lbl.add_theme_color_override("font_color", MHTokens.TEXT_ACCENT)
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.custom_minimum_size.x = PANEL_W - 32.0
	vbox.add_child(title_lbl)

	vbox.add_child(_hsep())

	# ── option buttons ───────────────────────────────────────────────────────
	for id: String in _ids:
		var card := DiscoveryRegistry.get_card(id)
		if card == null:
			continue

		var req_met := _check_requirement(card.stat_requirement)
		var cat_col := _category_color(card.category)

		var btn := Button.new()
		if req_met:
			btn.text = card.short_label
		else:
			btn.text     = card.short_label
			btn.disabled = true
			btn.tooltip_text = "Requires %s" % card.stat_requirement

		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(PANEL_W - 32.0, 36.0)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 12)

		# Normal / hover / pressed / disabled styleboxes
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			var bsb := StyleBoxFlat.new()
			match state:
				"normal":   bsb.bg_color = Color(0.14, 0.12, 0.10, 0.0)
				"hover":    bsb.bg_color = Color(0.20, 0.17, 0.13, 0.6)
				"pressed":  bsb.bg_color = Color(0.25, 0.21, 0.16, 0.8)
				"focus":    bsb.bg_color = Color(0.20, 0.17, 0.13, 0.4)
				"disabled": bsb.bg_color = Color(0.14, 0.12, 0.10, 0.0)
			bsb.border_width_left = 3
			bsb.border_color      = cat_col if state != "disabled" \
				else Color(cat_col, 0.3)
			bsb.content_margin_left   = 10.0
			bsb.content_margin_right  = 6.0
			bsb.content_margin_top    = 6.0
			bsb.content_margin_bottom = 6.0
			btn.add_theme_stylebox_override(state, bsb)

		var fc := MHTokens.TEXT_PRIMARY if req_met \
			else Color(MHTokens.TEXT_PRIMARY, 0.35)
		btn.add_theme_color_override("font_color",          fc)
		btn.add_theme_color_override("font_hover_color",    MHTokens.TEXT_PRIMARY)
		btn.add_theme_color_override("font_pressed_color",  MHTokens.TEXT_PRIMARY)
		btn.add_theme_color_override("font_disabled_color", Color(MHTokens.TEXT_PRIMARY, 0.35))

		var captured_id := id
		btn.pressed.connect(func() -> void: chosen.emit(captured_id))
		vbox.add_child(btn)

		# Requirement label beneath disabled options
		if not req_met:
			var req_lbl := Label.new()
			req_lbl.text = "  Requires %s" % card.stat_requirement
			req_lbl.add_theme_color_override("font_color", Color(MHTokens.TEXT_PRIMARY, 0.35))
			req_lbl.add_theme_font_size_override("font_size", 10)
			vbox.add_child(req_lbl)

	# ── skip ─────────────────────────────────────────────────────────────────
	if _allow_skip:
		vbox.add_child(_hsep())
		var skip_btn := Button.new()
		skip_btn.text = "Skip"
		skip_btn.add_theme_font_size_override("font_size", 11)
		skip_btn.add_theme_color_override("font_color", Color(MHTokens.TEXT_PRIMARY, 0.5))

		var skip_sb := StyleBoxFlat.new()
		skip_sb.bg_color = Color(0, 0, 0, 0)
		skip_btn.add_theme_stylebox_override("normal", skip_sb)
		skip_btn.add_theme_stylebox_override("hover",  skip_sb)

		skip_btn.pressed.connect(func() -> void: chosen.emit(""))
		vbox.add_child(skip_btn)


# ─── helpers ─────────────────────────────────────────────────────────────────

func _check_requirement(req: String) -> bool:
	if req.is_empty() or not Dialogic.VAR:
		return true
	var parts := req.split(" ", false)
	if parts.size() != 3:
		return true
	var val := int(Dialogic.VAR.get_variable("stats." + parts[0], 0))
	var thr := int(parts[2])
	match parts[1]:
		">=": return val >= thr
		">":  return val >  thr
		"<=": return val <= thr
		"<":  return val <  thr
		"==": return val == thr
	return true


func _category_color(category: String) -> Color:
	match category:
		"observation":   return MHTokens.DISC_OBSERVATION
		"confession":    return MHTokens.DISC_CONFESSION
		"contradiction": return MHTokens.DISC_CONTRADICTION
		"vulnerability": return MHTokens.DISC_VULNERABILITY
	return MHTokens.TEXT_PRIMARY


func _hsep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(MHTokens.TEXT_PRIMARY, 0.12))
	return s
