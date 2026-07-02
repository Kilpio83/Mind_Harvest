extends CanvasLayer
## Overlays a lock/unlock icon next to Dialogic choice buttons.
## Locked choices (disabled) show a closed padlock with a hover hint.
## Choices with a met condition show an open padlock as a reward indicator.
## Dialogic's own button nodes are not modified at all.

const _LOCK_ICON   := preload("res://assets/ui/lock_icon.svg")
const _UNLOCK_ICON := preload("res://assets/ui/unlock_icon.svg")

const _ICON_SIZE := 48.0
const _PADDING   := 6.0

var _tooltip: PanelContainer
var _hint_label: Label


func _ready() -> void:
	layer = 100
	_build_tooltip()
	call_deferred("_connect_signals")


func _build_tooltip() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.094, 0.078, 0.97)
	style.set_border_width_all(1)
	style.border_color = Color(0.886, 0.639, 0.243, 0.4)
	style.set_corner_radius_all(4)
	style.content_margin_left   = 10
	style.content_margin_right  = 10
	style.content_margin_top    = 7
	style.content_margin_bottom = 7

	_tooltip = PanelContainer.new()
	_tooltip.add_theme_stylebox_override("panel", style)
	_tooltip.visible = false
	add_child(_tooltip)

	var margin := MarginContainer.new()
	_tooltip.add_child(margin)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.753, 0.659, 0.471, 1.0))
	_hint_label.custom_minimum_size = Vector2(100, 0)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	margin.add_child(_hint_label)


func _connect_signals() -> void:
	Dialogic.Choices.question_shown.connect(_on_question_shown)
	Dialogic.Choices.choice_selected.connect(_clear_all)
	Dialogic.timeline_ended.connect(_clear_all)


func _on_question_shown(question_info: Dictionary) -> void:
	_clear_all()
	await get_tree().process_frame
	for choice in question_info.choices:
		if not choice.get("visible", true):
			continue
		var btn = Dialogic.Choices.get_choice_button(choice.button_index)
		if not is_instance_valid(btn):
			continue
		var hint := _get_hint(choice)
		if hint.is_empty():
			continue
		var disabled: bool = choice.get("disabled", false)
		_place_icon(btn.get_global_rect(), _LOCK_ICON if disabled else _UNLOCK_ICON, hint)


func _place_icon(btn_rect: Rect2, texture: Texture2D, hint: String) -> void:
	var box_size := _ICON_SIZE + _PADDING * 2

	# Dark rounded background for contrast against any scene backdrop
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.094, 0.078, 0.90)
	style.set_border_width_all(1)
	style.border_color = Color(0.886, 0.639, 0.243, 0.25)
	style.set_corner_radius_all(6)

	var box := Panel.new()
	box.add_theme_stylebox_override("panel", style)
	box.size = Vector2(box_size, box_size)
	box.position = Vector2(
		btn_rect.end.x + 10.0,
		btn_rect.position.y + (btn_rect.size.y - box_size) * 0.5)

	var icon := TextureRect.new()
	icon.texture = texture
	icon.size = Vector2(_ICON_SIZE, _ICON_SIZE)
	icon.position = Vector2(_PADDING, _PADDING)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_PASS

	box.mouse_entered.connect(func(): _show_tooltip(box, hint))
	box.mouse_exited.connect(func(): _tooltip.visible = false)
	box.add_child(icon)
	add_child(box)


func _show_tooltip(anchor: Control, hint: String) -> void:
	_hint_label.text = hint
	await get_tree().process_frame
	var vp  := get_viewport().get_visible_rect().size
	var r   := anchor.get_global_rect()
	var tsz := _tooltip.get_minimum_size()
	_tooltip.global_position = Vector2(
		clampf(r.end.x - tsz.x, 4.0, vp.x - tsz.x - 4.0),
		r.position.y - tsz.y - 6.0)
	_tooltip.visible = true


func _clear_all(_info: Variant = null) -> void:
	for child in get_children():
		if child != _tooltip:
			child.queue_free()
	_tooltip.visible = false


func _get_hint(choice_info: Dictionary) -> String:
	var idx: int = choice_info.get("event_index", -1)
	if idx < 0:
		return ""
	var events = Dialogic.current_timeline_events
	if events == null or idx >= events.size():
		return ""
	var event = events[idx]
	if not "condition" in event:
		return ""
	return _parse_condition(event.condition)


static func _parse_condition(condition: String) -> String:
	var re := RegEx.new()
	re.compile(r'\{([^}]+)\}\s*(>=|<=|>|<|==)\s*(\S+)')
	var m := re.search(condition)
	if not m:
		return ""
	var path  : String = m.get_string(1)
	var op    : String = m.get_string(2).replace(">=", "≥").replace("<=", "≤")
	var value : String = m.get_string(3)
	var parts := path.split(".")
	match parts[0]:
		"stats":
			return "%s %s %s" % [parts[1].capitalize(), op, value]
		"patients":
			if parts.size() >= 3:
				return "%s %s %s" % [parts[2].replace("_", " ").capitalize(), op, value]
	return "%s %s %s" % [parts[-1].replace("_", " ").capitalize(), op, value]
