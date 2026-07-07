extends DialogicNode_ChoiceButton

const _DICE_ICON        := preload("res://assets/ui/dice_icon.svg")
const _COLOR_RISKY      := Color("#D4A843")
const _COLOR_GUARANTEED := Color("#43D4B8")
const _COLOR_CHANCE_GREEN  := Color("#5DBF6E")
const _COLOR_CHANCE_YELLOW := Color("#D4A843")
const _COLOR_CHANCE_RED    := Color("#C94E4E")

@onready var _dice_box     : Panel          = $DiceBox
@onready var _dice_icon    : TextureRect    = $DiceBox/VBoxContainer/DiceIcon
@onready var _chance_label : Label          = $DiceBox/VBoxContainer/ChanceLabel
@onready var _tooltip      : PanelContainer = $DiceTooltip
@onready var _tooltip_label: Label          = $DiceTooltip/MarginContainer/TooltipLabel

var _choice_info : Dictionary = {}
var _stat_name   : String     = ""
var _difficulty  : int        = 0
var _chance      : int        = 0
var _win_label   : String     = ""
var _lose_label  : String     = ""


func _ready() -> void:
	super()
	_dice_box.mouse_entered.connect(_show_tooltip)
	_dice_box.mouse_exited.connect(func() -> void: _tooltip.visible = false)


func _process(_delta: float) -> void:
	if _dice_box == null:
		return
	if not _dice_box.visible:
		return
	if not is_visible_in_tree():
		_dice_box.visible = false
		_tooltip.visible = false
	else:
		_position_dice_box()


func _load_info(info: Dictionary) -> void:
	super(info)
	_choice_info = info

	var tag: String = info.get("dice", "")
	if tag.is_empty():
		_stat_name  = ""
		_win_label  = ""
		_lose_label = ""
		_dice_box.visible = false
		return

	var parts := tag.split(":")
	_stat_name  = parts[0]
	_difficulty = _difficulty_from_name(parts[1] if parts.size() > 1 else "medium")
	_win_label  = info.get("win", "")
	_lose_label = info.get("lose", "")
	_chance = _compute_chance(_stat_name, _difficulty)

	_dice_icon.texture  = _DICE_ICON
	_dice_icon.modulate = _COLOR_GUARANTEED if _chance >= 100 else _COLOR_RISKY
	_chance_label.text = "✓" if _chance >= 100 else "%d%%" % _chance
	var chance_color := _COLOR_CHANCE_GREEN if _chance >= 75 else (_COLOR_CHANCE_YELLOW if _chance >= 50 else _COLOR_CHANCE_RED)
	_chance_label.add_theme_color_override("font_color", chance_color)

	var diff_name := (parts[1].capitalize() if parts.size() > 1 else "Medium")
	var stat_val  := int(Dialogic.VAR.get_variable("stats." + _stat_name))
	_tooltip_label.text = "%s · %d\nDifficulty: %s\nSuccess: %d%%" % [
		_stat_name.capitalize(), stat_val, diff_name, _chance]

	_dice_box.visible = true
	_position_dice_box()


func _pressed() -> void:
	if _stat_name.is_empty():
		super()
		return
	if Dialogic.paused or not Dialogic.Choices._choice_blocker.is_stopped():
		return

	disabled = true

	var stat_value : int = int(Dialogic.VAR.get_variable("stats." + _stat_name))
	var roll_value := randi() % 100 + 1
	var bonus      := (stat_value - 1) * 10
	var passed     := (roll_value + bonus) >= _difficulty
	var quality    := "crit" if (passed and roll_value >= 90) else ("pass" if passed else "fail")

	DiceRoll.play_roll(_stat_name, _chance, roll_value, passed, quality)
	await DiceRoll.roll_finished

	if not is_instance_valid(self):
		return

	_dice_box.visible = false
	_tooltip.visible  = false

	var target_label := _win_label if passed else _lose_label

	var choice_text: String = _choice_info.get("text", "")
	if not choice_text.is_empty():
		Dialogic.History.store_simple_history_entry(choice_text, "Choice", {"all_choices": [choice_text]})

	Dialogic.Choices._choice_blocker.stop()
	Dialogic.Choices.choice_selected.emit(_choice_info)
	Dialogic.Choices.hide_all_choices()
	Dialogic.current_state = Dialogic.States.IDLE
	Dialogic.Jump.jump_to_label(target_label)
	Dialogic.handle_event(Dialogic.current_event_idx + 1)


func _position_dice_box() -> void:
	var r := get_global_rect()
	_dice_box.size = Vector2(58.0, r.size.y)
	_dice_box.global_position = Vector2(r.end.x + 4.0, r.position.y)


func _show_tooltip() -> void:
	await get_tree().process_frame
	if not is_instance_valid(self) or not _tooltip_label.text:
		return
	var vp  := get_viewport().get_visible_rect().size
	var r   := _dice_box.get_global_rect()
	var tsz := _tooltip.get_minimum_size()
	_tooltip.global_position = Vector2(
		clampf(r.end.x - tsz.x, 4.0, vp.x - tsz.x - 4.0),
		r.position.y - tsz.y - 6.0)
	_tooltip.visible = true


static func _difficulty_from_name(diff: String) -> int:
	match diff:
		"easy":   return 30
		"medium": return 50
		"hard":   return 70
		"deadly": return 90
		_:        return 50


static func _compute_chance(stat_name: String, difficulty: int) -> int:
	var stat_value := int(Dialogic.VAR.get_variable("stats." + stat_name))
	return clamp(100 - difficulty + (stat_value - 1) * 10, 5, 100)
