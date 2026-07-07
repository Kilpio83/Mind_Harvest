@tool
extends DialogicPortrait

const EMOTION_TEXTURES := {
	"Admiration":    "res://assets/portraits/kamila/admiration.png",
	"Amusement":     "res://assets/portraits/kamila/amusement.png",
	"Anger":         "res://assets/portraits/kamila/anger.png",
	"Annoyance":     "res://assets/portraits/kamila/annoyance.png",
	"Approval":      "res://assets/portraits/kamila/approval.png",
	"Caring":        "res://assets/portraits/kamila/caring.png",
	"Confusion":     "res://assets/portraits/kamila/confusion.png",
	"Curiosity":     "res://assets/portraits/kamila/curiosity.png",
	"Desire":        "res://assets/portraits/kamila/desire.png",
	"Disappointment":"res://assets/portraits/kamila/disappointment.png",
	"Disapproval":   "res://assets/portraits/kamila/disapproval.png",
	"Disgust":       "res://assets/portraits/kamila/disgust.png",
	"Embarrassment": "res://assets/portraits/kamila/embarrassment.png",
	"Excitement":    "res://assets/portraits/kamila/excitement.png",
	"Fear":          "res://assets/portraits/kamila/fear.png",
	"Gratitude":     "res://assets/portraits/kamila/gratitude.png",
	"Grief":         "res://assets/portraits/kamila/grief.png",
	"Joy":           "res://assets/portraits/kamila/joy.png",
	"Love":          "res://assets/portraits/kamila/love.png",
	"Nervousness":   "res://assets/portraits/kamila/nervousness.png",
	"Neutral":       "res://assets/portraits/kamila/neutral.png",
	"Optimism":      "res://assets/portraits/kamila/optimism.png",
	"Pride":         "res://assets/portraits/kamila/pride.png",
	"Realization":   "res://assets/portraits/kamila/realization.png",
	"Relief":        "res://assets/portraits/kamila/relief.png",
	"Remorse":       "res://assets/portraits/kamila/remorse.png",
	"Sadness":       "res://assets/portraits/kamila/sadness.png",
	"Surprise":      "res://assets/portraits/kamila/surprise.png",
}

var _blink_timer: Timer
var _breath_time := 0.0
var _rest_y := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	$Blink.modulate.a = 0.0
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_do_blink)
	add_child(_blink_timer)
	_blink_timer.start(randf_range(3.0, 7.0))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not $Base.texture:
		return
	_breath_time += delta
	var breath := sin(_breath_time * TAU / 3.6)
	$Base.material.set_shader_parameter("breath", breath)


func _do_blink() -> void:
	$Blink.modulate.a = 1.0
	$Blink.play("blink")


func _on_blink_animation_finished() -> void:
	$Blink.modulate.a = 0.0
	_blink_timer.start(randf_range(3.0, 7.0))


func _update_portrait(passed_character: DialogicCharacter, passed_portrait: String) -> void:
	if passed_portrait == "":
		passed_portrait = passed_character.default_portrait

	# Strip "_Animated" suffix so "Neutral_Animated" maps to "Neutral"
	var key := passed_portrait.replace("_Animated", "")
	var path: String = EMOTION_TEXTURES.get(key, EMOTION_TEXTURES.get("Neutral", ""))
	if path.is_empty():
		return

	var tex: Texture2D = load(path)
	$Base.texture = tex
	$Base.centered = false
	$Base.position = tex.get_size() * Vector2(-0.5, -1.0)
	_rest_y = $Base.position.y

	$Blink.centered = false
	$Blink.position = $Base.position

	set_meta("texture_holder_node", $Base)


func _get_covered_rect() -> Rect2:
	if $Base.texture:
		return Rect2($Base.position, $Base.texture.get_size() * $Base.scale)
	return Rect2()
