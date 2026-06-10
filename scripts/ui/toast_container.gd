## ToastLayer — slide-in notification stack, top-right corner.
## API:  ToastLayer.show_toast(title, subtitle, category)
## Categories: "success" | "warning" | "photo" | "stat"
## All static structure defined in toast_container.tscn.
extends CanvasLayer

@onready var _stack: VBoxContainer = $ToastRoot/Stack


func show_toast(
		title    : String,
		subtitle : String = "",
		category : String = "success") -> void:

	var accent := _accent_for(category)

	var wrapper := Control.new()
	wrapper.clip_contents         = false
	wrapper.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h: float = 20.0 + 22.0
	if not subtitle.is_empty():
		h += 2.0 + 19.0
	wrapper.custom_minimum_size = Vector2(MHTokens.TOAST_WIDTH, h)

	var row := _build_toast(title, subtitle, accent)
	row.position.x = float(MHTokens.TOAST_WIDTH + 24)
	wrapper.add_child(row)

	_stack.add_child(wrapper)
	_stack.move_child(wrapper, 0)
	_animate(wrapper, row)


func _build_toast(title: String, subtitle: String, accent: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(MHTokens.TOAST_WIDTH, 0)
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bar := ColorRect.new()
	bar.color = accent
	bar.custom_minimum_size = Vector2(3, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(bar)

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

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_color_override("font_color", MHTokens.TEXT_PRIMARY)
	title_lbl.add_theme_font_size_override("font_size", MHTokens.FONT_BODY)
	col.add_child(title_lbl)

	if not subtitle.is_empty():
		var sub_lbl := Label.new()
		sub_lbl.text = subtitle
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_color_override("font_color", Color(MHTokens.TEXT_PRIMARY, 0.75))
		sub_lbl.add_theme_font_size_override("font_size", MHTokens.FONT_SMALL)
		col.add_child(sub_lbl)

	return row


func _animate(wrapper: Control, panel: Control) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "position:x", 0.0, MHTokens.TOAST_SLIDE_SEC)
	await tween.finished
	if not is_instance_valid(wrapper):
		return
	await get_tree().create_timer(MHTokens.TOAST_HOLD_SEC).timeout
	if not is_instance_valid(wrapper):
		return
	tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, MHTokens.TOAST_FADE_SEC)
	await tween.finished
	if is_instance_valid(wrapper):
		wrapper.queue_free()


func _accent_for(category: String) -> Color:
	match category:
		"success": return MHTokens.ACCENT_SUCCESS
		"warning":  return MHTokens.ACCENT_WARNING
		"photo":    return MHTokens.ACCENT_PHOTO
		"stat":     return MHTokens.ACCENT_STAT
		_:          return MHTokens.ACCENT_SUCCESS
