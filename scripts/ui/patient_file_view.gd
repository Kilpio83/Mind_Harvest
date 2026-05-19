extends CanvasLayer

@onready var tabs: TabContainer = $Panel/VBox/Tabs
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var photo_popup: Control = $PhotoPopup
@onready var popup_photo: TextureRect = $PhotoPopup/PopupPhoto
@onready var popup_close: Button = $PhotoPopup/PopupClose

const PATIENTS := {
	"anna":    {"display": "Anna Volkov",   "occupation": "Senior Accountant"},
	"marisol": {"display": "Marisol Reyes", "occupation": "Romance Novelist"},
}


func _ready() -> void:
	close_button.pressed.connect(queue_free)
	popup_close.pressed.connect(_on_popup_close)
	photo_popup.visible = false
	for patient_id in PATIENTS:
		var d: Dictionary = PATIENTS[patient_id]
		_build_tab(patient_id, d["display"], d["occupation"])


func _build_tab(patient_id: String, display_name: String, occupation: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = display_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Header: info block
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	info.add_child(name_lbl)

	var occ_lbl := Label.new()
	occ_lbl.text = occupation
	info.add_child(occ_lbl)

	var trust: int = int(Dialogic.VAR.get_variable("patients." + patient_id + ".trust", 30))
	var trust_lbl := Label.new()
	trust_lbl.text = "Trust: %d / 100" % trust
	info.add_child(trust_lbl)

	var trust_bar := ProgressBar.new()
	trust_bar.max_value = 100
	trust_bar.value = trust
	trust_bar.show_percentage = false
	trust_bar.custom_minimum_size = Vector2(0, 20)
	info.add_child(trust_bar)

	var progress: int = int(Dialogic.VAR.get_variable("patients." + patient_id + ".progress", 0))
	var sessions_lbl := Label.new()
	sessions_lbl.text = "Sessions completed: %d / 3" % progress
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
		for fact_id: String in notes:
			var note_lbl := Label.new()
			note_lbl.text = "• " + fact_id.replace("_", " ").capitalize()
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
