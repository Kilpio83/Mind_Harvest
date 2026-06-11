extends CanvasLayer
## Debug stat editor — toggle with F12. Only active in debug builds.

const STATS := ["composure", "intellect", "knowledge", "nerve", "perception"]

var _panel: PanelContainer
var _labels: Dictionary = {}


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 100
	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			_panel.visible = not _panel.visible
			if _panel.visible:
				_refresh()
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(8, 8)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "— DEBUG (F12) —"
	title.add_theme_color_override("font_color", Color(0.886, 0.639, 0.243, 1))
	vbox.add_child(title)

	for stat in STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var minus := Button.new()
		minus.text = "-"
		minus.custom_minimum_size = Vector2(28, 0)
		minus.pressed.connect(_on_stat_change.bind(stat, -1))
		row.add_child(minus)

		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(lbl)
		_labels[stat] = lbl

		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(28, 0)
		plus.pressed.connect(_on_stat_change.bind(stat, 1))
		row.add_child(plus)

	# Day row
	var sep := HSeparator.new()
	vbox.add_child(sep)
	var day_row := HBoxContainer.new()
	day_row.add_theme_constant_override("separation", 6)
	vbox.add_child(day_row)

	var day_minus := Button.new()
	day_minus.text = "-"
	day_minus.custom_minimum_size = Vector2(28, 0)
	day_minus.pressed.connect(_on_day_change.bind(-1))
	day_row.add_child(day_minus)

	var day_lbl := Label.new()
	day_lbl.custom_minimum_size = Vector2(160, 0)
	day_row.add_child(day_lbl)
	_labels["day"] = day_lbl

	var day_plus := Button.new()
	day_plus.text = "+"
	day_plus.custom_minimum_size = Vector2(28, 0)
	day_plus.pressed.connect(_on_day_change.bind(1))
	day_row.add_child(day_plus)


func _refresh() -> void:
	for stat in STATS:
		var val := int(Dialogic.VAR.get_variable("stats." + stat, 1))
		_labels[stat].text = "%s: %d" % [stat.capitalize(), val]
	var day := int(Dialogic.VAR.get_variable("game.day", 1))
	_labels["day"].text = "Day: %d" % day


func _on_stat_change(stat: String, delta: int) -> void:
	var key := "stats." + stat
	var current := int(Dialogic.VAR.get_variable(key, 1))
	Dialogic.VAR.set_variable(key, clampi(current + delta, 1, 10))
	_refresh()


func _on_day_change(delta: int) -> void:
	var current := int(Dialogic.VAR.get_variable("game.day", 1))
	Dialogic.VAR.set_variable("game.day", maxi(1, current + delta))
	_refresh()
