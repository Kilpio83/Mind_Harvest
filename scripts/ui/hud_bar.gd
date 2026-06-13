## HudBar — persistent top-of-screen game-state overlay.
## Left: Day N  ·  Phase  ·  Patient Name
## Right: PER · INT · KNO · COM · NRV
extends CanvasLayer

@onready var _day_lbl:     Label = $Panel/Row/Left/DayLabel
@onready var _phase_lbl:   Label = $Panel/Row/Left/PhaseLabel
@onready var _patient_sep: Label = $Panel/Row/Left/PatientSep
@onready var _patient_lbl: Label = $Panel/Row/Left/PatientLabel
@onready var _per_val:     Label = $Panel/Row/Right/PerGroup/PerVal
@onready var _int_val:     Label = $Panel/Row/Right/IntGroup/IntVal
@onready var _kno_val:     Label = $Panel/Row/Right/KnoGroup/KnoVal
@onready var _com_val:     Label = $Panel/Row/Right/ComGroup/ComVal
@onready var _nrv_val:     Label = $Panel/Row/Right/NrvGroup/NrvVal

var _t := 0.0
const _INTERVAL := 0.25


func _process(delta: float) -> void:
	_t += delta
	if _t < _INTERVAL:
		return
	_t = 0.0
	_refresh()


func _refresh() -> void:
	if not is_node_ready() or not Dialogic.VAR:
		return

	var day   := int(Dialogic.VAR.get_variable("game.day",             1))
	var phase := str(Dialogic.VAR.get_variable("game.phase",           "morning"))
	var pat   := str(Dialogic.VAR.get_variable("game.current_patient", ""))

	_day_lbl.text   = "Day %d" % day
	_phase_lbl.text = phase.capitalize()

	var has_patient := not pat.is_empty()
	_patient_sep.visible = has_patient
	_patient_lbl.visible = has_patient
	if has_patient:
		_patient_lbl.text = _display_name(pat)

	_per_val.text = str(int(Dialogic.VAR.get_variable("stats.perception", 1)))
	_int_val.text = str(int(Dialogic.VAR.get_variable("stats.intellect",  1)))
	_kno_val.text = str(int(Dialogic.VAR.get_variable("stats.knowledge",  1)))
	_com_val.text = str(int(Dialogic.VAR.get_variable("stats.composure",  1)))
	_nrv_val.text = str(int(Dialogic.VAR.get_variable("stats.nerve",      1)))


func _display_name(key: String) -> String:
	match key:
		"anna":    return "Anna Volkov"
		"marisol": return "Marisol Reyes"
		_:         return key.capitalize()
