extends CanvasLayer
## Patient file view — tab per patient, each tab is a PatientTabPage sub-scene.
## All structure is in patient_file_view.tscn + patient_tab_page.tscn.
## This script is orchestration + tooltip positioning + photo popup only.

@onready var _close_btn:   Button          = $Panel/VBox/Header/CloseButton
@onready var _photo_popup: Control         = $PhotoPopup
@onready var _popup_photo: TextureRect     = $PhotoPopup/PopupPhoto
@onready var _popup_close: Button          = $PhotoPopup/PopupClose
@onready var _tooltip:      PanelContainer = $TooltipOverlay
@onready var _tooltip_vbox: VBoxContainer  = $TooltipOverlay/TooltipVBox
@onready var _anna_tab:    PatientTabPage  = $"Panel/VBox/Tabs/Anna Volkov"
@onready var _marisol_tab: PatientTabPage  = $"Panel/VBox/Tabs/Marisol Reyes"
@onready var _kamila_tab:  PatientTabPage  = $"Panel/VBox/Tabs/Kamila Vance"


func _ready() -> void:
	layer = 15

	var vp := get_viewport().get_visible_rect().size
	var panel := $Panel as PanelContainer
	panel.offset_left   = -vp.x * 0.47
	panel.offset_right  =  vp.x * 0.47
	panel.offset_top    = -vp.y * 0.46
	panel.offset_bottom =  vp.y * 0.46

	_style_primary_btn(_close_btn)
	_style_primary_btn(_popup_close)

	_close_btn.pressed.connect(queue_free)
	_popup_close.pressed.connect(_on_popup_close)
	_photo_popup.visible = false

	_anna_tab.populate(_show_tooltip, _hide_tooltip, _photo_popup)
	_marisol_tab.populate(_show_tooltip, _hide_tooltip, _photo_popup)
	_kamila_tab.populate(_show_tooltip, _hide_tooltip, _photo_popup)

	_anna_tab.visible    = bool(Dialogic.VAR.get_variable("flags.met_anna",    false))
	_marisol_tab.visible = bool(Dialogic.VAR.get_variable("flags.met_marisol", false))
	_kamila_tab.visible  = bool(Dialogic.VAR.get_variable("flags.met_kamila",  false))


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


func _style_primary_btn(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 13)
	var s_norm := StyleBoxFlat.new()
	s_norm.bg_color = Color(0.25, 0.23, 0.20, 1.0)
	s_norm.corner_radius_top_left = 6
	s_norm.corner_radius_top_right = 6
	s_norm.corner_radius_bottom_right = 6
	s_norm.corner_radius_bottom_left = 6
	s_norm.content_margin_left = 14.0
	s_norm.content_margin_right = 14.0
	s_norm.content_margin_top = 7.0
	s_norm.content_margin_bottom = 7.0
	var s_hov := s_norm.duplicate() as StyleBoxFlat
	s_hov.bg_color = Color(0.886, 0.639, 0.243, 1.0)
	b.add_theme_stylebox_override("normal",   s_norm)
	b.add_theme_stylebox_override("hover",    s_hov)
	b.add_theme_stylebox_override("pressed",  s_hov)
	b.add_theme_stylebox_override("focus",    s_norm)
	b.add_theme_color_override("font_color",          Color(0.953, 0.933, 0.890, 1.0))
	b.add_theme_color_override("font_hover_color",    Color(0.188, 0.173, 0.153, 1.0))
	b.add_theme_color_override("font_pressed_color",  Color(0.188, 0.173, 0.153, 1.0))
	b.add_theme_color_override("font_focus_color",    Color(0.953, 0.933, 0.890, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.953, 0.933, 0.890, 0.30))


func _hide_tooltip() -> void:
	if _tooltip:
		_tooltip.visible = false


# ─── photo popup ─────────────────────────────────────────────────────────────

func _on_popup_close() -> void:
	_photo_popup.visible = false
	_popup_photo.texture = null
