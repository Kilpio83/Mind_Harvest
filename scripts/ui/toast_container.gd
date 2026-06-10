## ToastLayer — slide-in notification stack, top-right corner.
##
## API:
##   ToastLayer.show_toast(title, subtitle, category)
##
## Categories:  "success" | "warning" | "photo" | "stat"
##   success → green  #97c459   (stat check passed, trust gained)
##   warning → amber  #efb049   (stat check failed, trust lost)
##   photo   → gold   #d4a84a   (photo captured)
##   stat    → blue   #5a9fd4   (XP / level-up)
##
## Autoloaded as "ToastLayer" (CanvasLayer, layer = 20) in project.godot.
## Custom Dialogic events call this singleton directly.
extends CanvasLayer

var _stack: VBoxContainer

const _MARGIN_RIGHT := 16
const _MARGIN_TOP   := 60   ## clears the HUD bar


func _ready() -> void:
	layer = 20
	_build()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = false
	add_child(root)

	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 8)
	_stack.set_anchor(SIDE_LEFT,   1.0)
	_stack.set_anchor(SIDE_TOP,    0.0)
	_stack.set_anchor(SIDE_RIGHT,  1.0)
	_stack.set_anchor(SIDE_BOTTOM, 0.0)
	_stack.offset_left   = -(MHTokens.TOAST_WIDTH + _MARGIN_RIGHT)
	_stack.offset_right  = -_MARGIN_RIGHT
	_stack.offset_top    = _MARGIN_TOP
	_stack.offset_bottom = _MARGIN_TOP + 800  # tall enough for many simultaneous toasts
	_stack.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stack)


# ─── public API ──────────────────────────────────────────────────────────────

func show_toast(
		title    : String,
		subtitle : String = "",
		category : String = "success") -> void:

	var accent  := _accent_for(category)

	# Wrapper — VBoxContainer measures this for vertical layout.
	# It's a plain Control so it doesn't interfere with the row's position.
	var wrapper := Control.new()
	wrapper.clip_contents        = false
	wrapper.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Height is deterministic: panel content margins (10 + 10 = 20 px)
	# + title line at FONT_BODY/16 px (≈ 22 px) + optional subtitle line at
	# FONT_SMALL/14 px (≈ 19 px) + 2 px separation.
	# We must NOT call get_minimum_size() here — with autowrap labels and no
	# allocated width yet, the text server would wrap every word onto its own
	# line and report a height of several hundred pixels, pushing subsequent
	# toasts far off-screen.
	var h: float = 20.0 + 22.0                          # 42 — one line
	if not subtitle.is_empty():
		h += 2.0 + 19.0                                  # 63 — two lines
	wrapper.custom_minimum_size = Vector2(MHTokens.TOAST_WIDTH, h)

	var row := _build_toast(title, subtitle, accent)
	# Start off-screen to the right (relative to wrapper, not managed by VBox).
	row.position.x = float(MHTokens.TOAST_WIDTH + 24)
	wrapper.add_child(row)

	_stack.add_child(wrapper)
	_stack.move_child(wrapper, 0)   # newest toast at top

	_animate(wrapper, row)          # fire-and-forget coroutine


# ─── toast builder ───────────────────────────────────────────────────────────

## Builds the visible row (HBox: accent bar + dark panel + text).
## Returns the row directly; the wrapper is created in show_toast().
func _build_toast(title: String, subtitle: String, accent: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(MHTokens.TOAST_WIDTH, 0)
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Left accent bar (3 px, full height, category colour)
	var bar := ColorRect.new()
	bar.color = accent
	bar.custom_minimum_size = Vector2(3, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(bar)

	# Dark content area with rounded right corners
	var bg := PanelContainer.new()
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb := StyleBoxFlat.new()
	sb.bg_color                   = MHTokens.PANEL_BG_STRONG
	sb.corner_radius_top_left     = 0
	sb.corner_radius_top_right    = MHTokens.TOAST_RADIUS
	sb.corner_radius_bottom_right = MHTokens.TOAST_RADIUS
	sb.corner_radius_bottom_left  = 0
	sb.content_margin_top         = 10.0
	sb.content_margin_bottom      = 10.0
	sb.content_margin_left        = 12.0
	sb.content_margin_right       = 12.0
	bg.add_theme_stylebox_override("panel", sb)
	row.add_child(bg)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	bg.add_child(col)

	# Title line
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_color_override("font_color", MHTokens.TEXT_PRIMARY)
	title_lbl.add_theme_font_size_override("font_size", MHTokens.FONT_BODY)
	col.add_child(title_lbl)

	# Subtitle line (optional)
	if not subtitle.is_empty():
		var sub_lbl := Label.new()
		sub_lbl.text = subtitle
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_color_override("font_color",
				Color(MHTokens.TEXT_PRIMARY, 0.75))
		sub_lbl.add_theme_font_size_override("font_size", MHTokens.FONT_SMALL)
		col.add_child(sub_lbl)

	return row


# ─── animation coroutine (fire-and-forget) ───────────────────────────────────

func _animate(wrapper: Control, panel: Control) -> void:
	# Slide in from right
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "position:x", 0.0, MHTokens.TOAST_SLIDE_SEC)
	await tween.finished

	if not is_instance_valid(wrapper):
		return

	# Hold
	await get_tree().create_timer(MHTokens.TOAST_HOLD_SEC).timeout

	if not is_instance_valid(wrapper):
		return

	# Fade out
	tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, MHTokens.TOAST_FADE_SEC)
	await tween.finished

	if is_instance_valid(wrapper):
		wrapper.queue_free()


# ─── helpers ─────────────────────────────────────────────────────────────────

func _accent_for(category: String) -> Color:
	match category:
		"success": return MHTokens.ACCENT_SUCCESS
		"warning":  return MHTokens.ACCENT_WARNING
		"photo":    return MHTokens.ACCENT_PHOTO
		"stat":     return MHTokens.ACCENT_STAT
		_:          return MHTokens.ACCENT_SUCCESS
