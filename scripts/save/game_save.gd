class_name GameSave extends Resource

@export var version: int = 1
@export var day: int = 1
@export var photos_by_patient: Dictionary = {}
@export var notes_by_patient: Dictionary = {}
@export var discoveries_by_patient: Dictionary = {}
@export var board_state_by_patient: Dictionary = {}
@export var bea_relationship: int = 0
@export var save_date: String = ""
@export var save_name: String = ""
@export var dialogic_save_slot: String = "slot_0"
