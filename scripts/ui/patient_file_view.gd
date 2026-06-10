extends CanvasLayer
## Patient file view — tab per patient, each tab is a PatientTabPage sub-scene.
## All structure is in patient_file_view.tscn + patient_tab_page.tscn.
## This script is orchestration + tooltip positioning + photo popup only.

@onready var _close_btn:   Button          = $Panel/VBox/CloseButton
@onready var _photo_popup: Control         = $PhotoPopup
@onready var _popup_photo: TextureRect     = $PhotoPopup/PopupPhoto
@onready var _popup_close: Button          = $PhotoPopup/PopupClose
@onready var _tooltip:      PanelContainer = $TooltipOverlay
@onready var _tooltip_vbox: VBoxContainer  = $TooltipOverlay/TooltipVBox
@onready var _anna_tab:    PatientTabPage  = $"Panel/VBox/Tabs/Anna Volkov"
@onready var _marisol_tab: PatientTabPage  = $"Panel/VBox/Tabs/Marisol Reyes"


func _ready() -> void:
	layer = 15

	var vp := get_viewport().get_visible_rect().size
	var panel := $Panel as PanelContainer
	panel.offset_left   = -vp.x * 0.47
	panel.offset_right  =  vp.x * 0.47
	panel.offset_top    = -vp.y * 0.46
	panel.offset_bottom =  vp.y * 0.46

	_close_btn.pressed.connect(queue_free)
	_popup_close.pressed.connect(_on_popup_close)
	_photo_popup.visible = false

	_anna_tab.populate(_show_tooltip, _hide_tooltip, _photo_popup)
	_marisol_tab.populate(_show_tooltip, _hide_tooltip, _photo_popup)


# ─── tooltip overlay ─────────────────────────────────────────────────────────

func _show_tooltip(filler: Callable, anchor: Control) -> void:
	for c: Node in _tooltip_vbox.get_children():
		c.free()
	filler.call(_tooltip_vbox)
	var vp   := get_viewport().get_visible_rect().size
	var apos := anchor.global_position
	_tooltip.position = Vector2(
		clampf(apos.x, 4.0, vp.x - 298.0),
		apos.y + anchor.size.y + 6.0)
	_tooltip.visible = true


func _hide_tooltip() -> void:
	if _tooltip:
		_tooltip.visible = false


# ─── photo popup ─────────────────────────────────────────────────────────────

func _on_popup_close() -> void:
	_photo_popup.visible = false
	_popup_photo.texture = null
