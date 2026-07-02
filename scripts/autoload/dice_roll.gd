extends Node
## Autoload interface for the dice roll overlay.
## Exposes play_beat() / play_roll() and forwards signals from the overlay scene.

signal beat_finished
signal roll_finished

var _overlay: Node = null


func _ready() -> void:
	var overlay_scene := load("res://scenes/ui/dice_roll_overlay.tscn") as PackedScene
	_overlay = overlay_scene.instantiate()
	add_child(_overlay)
	_overlay.beat_finished.connect(func() -> void: beat_finished.emit())
	_overlay.roll_finished.connect(func() -> void: roll_finished.emit())


func play_beat() -> void:
	_overlay.play_beat()


## stat: display name (e.g. "perception"), chance: effective %, roll_value: 0-99,
## passed: bool, quality: "crit"|"pass"|"fail"
func play_roll(stat: String, chance: int, roll_value: int, passed: bool, quality: String) -> void:
	_overlay.play_roll(stat, chance, roll_value, passed, quality)
