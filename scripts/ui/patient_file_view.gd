extends CanvasLayer

@onready var tabs: TabContainer = $Panel/VBox/Tabs
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var photo_popup: Control = $PhotoPopup
@onready var popup_photo: TextureRect = $PhotoPopup/PopupPhoto
@onready var popup_close: Button = $PhotoPopup/PopupClose

const PATIENTS := {
	"anna":    {"display": "Anna Volkov",   "occupation": "Senior Accountant", "portrait": "res://assets/portraits/anna/file_header_photo.png"},
	"marisol": {"display": "Marisol Reyes", "occupation": "Romance Novelist",  "portrait": "res://assets/portraits/marisol/file_header_photo.png"},
}


func _ready() -> void:
	close_button.pressed.connect(queue_free)
	popup_close.pressed.connect(_on_popup_close)
	photo_popup.visible = false
	for patient_id in PATIENTS:
		var d: Dictionary = PATIENTS[patient_id]
		_build_tab(patient_id, d["display"], d["occupation"], d["portrait"])


func _build_tab(patient_id: String, display_name: String, occupation: String, portrait_path: String = "") -> void:
	var scroll := ScrollContainer.new()
	scroll.name = display_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Header: portrait left, info right
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)

	var portrait_rect := TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(120, 160)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
	header.add_child(portrait_rect)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	info.add_child(name_lbl)

	var occ_lbl := Label.new()
	occ_lbl.text = occupation
	info.add_child(occ_lbl)

	var therapy: int = int(Dialogic.VAR.get_variable("patients." + patient_id + ".therapy_progress", 30))
	var bond:    int = int(Dialogic.VAR.get_variable("patients." + patient_id + ".personal_bond",    0))

	# ── Therapy Progress ──────────────────────────────────────────────────────
	var therapy_header := HBoxContainer.new()
	therapy_header.add_theme_constant_override("separation", 6)
	info.add_child(therapy_header)
	var th_left := Label.new()
	th_left.text = "STRANGER · 0"
	th_left.add_theme_font_size_override("font_size", 10)
	th_left.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	therapy_header.add_child(th_left)
	var th_spacer := Control.new()
	th_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	therapy_header.add_child(th_spacer)
	var th_right := Label.new()
	th_right.text = "BREAKTHROUGH · 100"
	th_right.add_theme_font_size_override("font_size", 10)
	th_right.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	therapy_header.add_child(th_right)

	var therapy_bar := ProgressBar.new()
	therapy_bar.max_value = 100
	therapy_bar.value = therapy
	therapy_bar.show_percentage = false
	therapy_bar.custom_minimum_size = Vector2(0, 16)
	info.add_child(therapy_bar)

	var therapy_caption := Label.new()
	therapy_caption.text = "Therapy: %d  —  %s" % [therapy, _therapy_caption(therapy)]
	therapy_caption.add_theme_font_size_override("font_size", 11)
	info.add_child(therapy_caption)

	# ── Personal Bond ─────────────────────────────────────────────────────────
	var bond_header := HBoxContainer.new()
	bond_header.add_theme_constant_override("separation", 6)
	info.add_child(bond_header)
	var bh_left := Label.new()
	bh_left.text = "HOSTILE · −50"
	bh_left.add_theme_font_size_override("font_size", 10)
	bh_left.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	bond_header.add_child(bh_left)
	var bh_spacer := Control.new()
	bh_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_header.add_child(bh_spacer)
	var bh_right := Label.new()
	bh_right.text = "DEVOTED · +50"
	bh_right.add_theme_font_size_override("font_size", 10)
	bh_right.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	bond_header.add_child(bh_right)

	# Bond bar: two halves growing outward from center.
	var bond_row := HBoxContainer.new()
	bond_row.add_theme_constant_override("separation", 2)
	bond_row.custom_minimum_size = Vector2(0, 16)
	info.add_child(bond_row)

	var neg_bar := ProgressBar.new()
	neg_bar.max_value = 50
	neg_bar.value = max(0, -bond)
	neg_bar.show_percentage = false
	neg_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	neg_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	bond_row.add_child(neg_bar)

	var center_sep := VSeparator.new()
	center_sep.custom_minimum_size = Vector2(3, 0)
	bond_row.add_child(center_sep)

	var pos_bar := ProgressBar.new()
	pos_bar.max_value = 50
	pos_bar.value = max(0, bond)
	pos_bar.show_percentage = false
	pos_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_row.add_child(pos_bar)

	var bond_caption := Label.new()
	var bond_sign := "+" if bond >= 0 else ""
	bond_caption.text = "Bond: %s%d  —  %s" % [bond_sign, bond, _bond_caption(bond)]
	bond_caption.add_theme_font_size_override("font_size", 11)
	info.add_child(bond_caption)

	var progress: int = int(Dialogic.VAR.get_variable("patients." + patient_id + ".progress", 0))
	var sessions_lbl := Label.new()
	sessions_lbl.text = "Sessions completed: %d" % progress
	info.add_child(sessions_lbl)

	# Notes
	vbox.add_child(HSeparator.new())
	var notes_title := Label.new()
	notes_title.text = "Notes"
	vbox.add_child(notes_title)

	var notes: Array = PatientManager.notes_by_patient.get(patient_id, [])
	if notes.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "Nothing recorded yet."
		vbox.add_child(none_lbl)
	else:
		for note: String in notes:
			var note_lbl := Label.new()
			note_lbl.text = "• " + note
			note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(note_lbl)

	# Photos
	vbox.add_child(HSeparator.new())
	var photos_title := Label.new()
	photos_title.text = "Photos"
	vbox.add_child(photos_title)

	var photos: Array = PatientManager.photos_by_patient.get(patient_id, [])
	if photos.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "No photos collected yet."
		vbox.add_child(none_lbl)
	else:
		var grid := HFlowContainer.new()
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(grid)
		for photo: PhotoData in photos:
			_add_photo_thumb(grid, photo)


func _add_photo_thumb(parent: Control, photo: PhotoData) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(130, 150)
	btn.flat = true
	parent.add_child(btn)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(col)

	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(120, 110)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if photo.portrait_path != "" and ResourceLoader.exists(photo.portrait_path):
		thumb.texture = load(photo.portrait_path)
	col.add_child(thumb)

	var title_lbl := Label.new()
	title_lbl.text = photo.title
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title_lbl)

	btn.pressed.connect(_show_photo_popup.bind(photo))


func _show_photo_popup(photo: PhotoData) -> void:
	popup_photo.texture = null
	if photo.portrait_path != "" and ResourceLoader.exists(photo.portrait_path):
		popup_photo.texture = load(photo.portrait_path)
	photo_popup.visible = true


func _on_popup_close() -> void:
	photo_popup.visible = false
	popup_photo.texture = null


# ─── meter captions ───────────────────────────────────────────────────────────

func _therapy_caption(v: int) -> String:
	if v <= 20:  return "Disengaged"
	elif v <= 40: return "Guarded"
	elif v <= 60: return "Opening up"
	elif v <= 80: return "Trust established"
	else:         return "Breakthrough near"


func _bond_caption(v: int) -> String:
	if v <= -21:  return "Hostile"
	elif v <= -6: return "Distant"
	elif v <= 5:  return "Neutral"
	elif v <= 20: return "Warm"
	else:         return "Devoted"
