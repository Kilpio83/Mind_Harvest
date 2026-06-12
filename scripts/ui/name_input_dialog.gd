extends CanvasLayer

signal name_confirmed(player_name: String)

@onready var _line_edit: LineEdit = $Overlay/Panel/VBox/NameInput
@onready var _confirm_btn: Button = $Overlay/Panel/VBox/ConfirmButton


func _ready() -> void:
	_line_edit.grab_focus()
	_confirm_btn.pressed.connect(_submit)
	_line_edit.text_submitted.connect(_on_text_submitted)


func _on_text_submitted(_text: String) -> void:
	_submit()


func _submit() -> void:
	var entered := _line_edit.text.strip_edges()
	if entered.is_empty():
		entered = "Adrian"
	name_confirmed.emit(entered)
	queue_free()
