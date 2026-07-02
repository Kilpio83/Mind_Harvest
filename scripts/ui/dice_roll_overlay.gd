extends CanvasLayer

signal beat_finished
signal roll_finished

@onready var _beat_overlay: ColorRect  = $BeatOverlay
@onready var _roll_widget:  PanelContainer = $RollWidget
@onready var _stat_name:    Label      = $RollWidget/Margin/VBox/StatRow/StatName
@onready var _chance_label: Label      = $RollWidget/Margin/VBox/StatRow/ChanceLabel
@onready var _bar_stack:    Control    = $RollWidget/Margin/VBox/BarStack
@onready var _roll_bar:     ProgressBar = $RollWidget/Margin/VBox/BarStack/RollBar
@onready var _threshold_mark: ColorRect = $RollWidget/Margin/VBox/BarStack/ThresholdMark
@onready var _roll_label:   Label      = $RollWidget/Margin/VBox/InfoRow/RollLabel
@onready var _need_label:   Label      = $RollWidget/Margin/VBox/InfoRow/NeedLabel
@onready var _result_label: Label      = $RollWidget/Margin/VBox/ResultLabel

# Normal resting offsets (widget 148px tall, 20px from top, centered at 340px wide)
const _OFFSET_TOP_REST    := 20.0
const _OFFSET_BOTTOM_REST := 168.0


func play_beat() -> void:
	var tw := create_tween()
	tw.tween_property(_beat_overlay, "color:a", 0.16, 0.10).set_ease(Tween.EASE_OUT)
	tw.tween_property(_beat_overlay, "color:a", 0.0,  0.10).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.04)
	tw.tween_property(_beat_overlay, "color:a", 0.09, 0.10).set_ease(Tween.EASE_OUT)
	tw.tween_property(_beat_overlay, "color:a", 0.0,  0.14).set_ease(Tween.EASE_IN)
	await tw.finished
	beat_finished.emit()


func play_roll(stat: String, chance: int, roll_value: int, _passed: bool, quality: String) -> void:
	var result_color: Color = _quality_color(quality)

	# ── configure labels & bar ────────────────────────────────────────────────
	_stat_name.text    = (stat.to_upper() if not stat.is_empty() else "CHANCE") + " CHECK"
	_chance_label.text = "%d%%" % chance
	_need_label.text   = "need ≥ %d" % (100 - chance)
	_roll_label.text   = "d100 : 00"
	_result_label.text = ""
	_result_label.modulate.a = 0.0
	_roll_bar.value = 0.0

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = result_color
	_roll_bar.add_theme_stylebox_override("fill", fill_style)

	# ── slide widget in from above ────────────────────────────────────────────
	_roll_widget.offset_top    = _OFFSET_TOP_REST    - 40.0
	_roll_widget.offset_bottom = _OFFSET_BOTTOM_REST - 40.0
	_roll_widget.modulate.a = 0.0
	_roll_widget.visible = true

	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(_roll_widget, "modulate:a", 1.0, 0.16)
	tw_in.tween_property(_roll_widget, "offset_top",    _OFFSET_TOP_REST,    0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_in.tween_property(_roll_widget, "offset_bottom", _OFFSET_BOTTOM_REST, 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tw_in.finished

	# ── place threshold mark (needs one frame for bar layout) ─────────────────
	await get_tree().process_frame
	var bar_w := _bar_stack.size.x
	var bar_h := _bar_stack.size.y
	_threshold_mark.position = Vector2(bar_w * (100 - chance) / 100.0 - 1.0, 0.0)
	_threshold_mark.size     = Vector2(2.0, bar_h)

	# ── animate bar + live counter ────────────────────────────────────────────
	_roll_bar.value_changed.connect(_update_roll_label)
	var tw_bar := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw_bar.tween_property(_roll_bar, "value", float(roll_value), 0.75)
	await tw_bar.finished
	_roll_bar.value_changed.disconnect(_update_roll_label)
	_roll_label.text = "d100 : %02d" % roll_value

	# ── reveal result ─────────────────────────────────────────────────────────
	_result_label.text = _quality_string(quality)
	_result_label.add_theme_color_override("font_color", result_color)
	var tw_res := create_tween()
	tw_res.tween_property(_result_label, "modulate:a", 1.0, 0.22)
	await tw_res.finished

	await get_tree().create_timer(1.0).timeout

	# ── slide widget out ──────────────────────────────────────────────────────
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(_roll_widget, "modulate:a", 0.0, 0.20)
	tw_out.tween_property(_roll_widget, "offset_top",    _OFFSET_TOP_REST    - 20.0, 0.20)
	tw_out.tween_property(_roll_widget, "offset_bottom", _OFFSET_BOTTOM_REST - 20.0, 0.20)
	await tw_out.finished

	_roll_widget.visible = false
	_roll_widget.offset_top    = _OFFSET_TOP_REST
	_roll_widget.offset_bottom = _OFFSET_BOTTOM_REST
	roll_finished.emit()


func _update_roll_label(val: float) -> void:
	_roll_label.text = "d100 : %02d" % int(val)


func _quality_color(quality: String) -> Color:
	match quality:
		"crit": return Color(0.886, 0.639, 0.243, 1.0)  # gold
		"pass": return Color(0.31,  0.78,  0.36,  1.0)  # green
		_:      return Color(0.85,  0.28,  0.22,  1.0)  # red


func _quality_string(quality: String) -> String:
	match quality:
		"crit": return "CRITICAL"
		"pass": return "PASS"
		_:      return "FAIL"
