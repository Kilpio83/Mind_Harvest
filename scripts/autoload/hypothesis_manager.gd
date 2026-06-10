extends Node
## Manages the Hypothesis Board state for all patients.
## Board = 4 intent canvases (Heal/Befriend/Seduce/Exploit), each a 5×5 grid.
## Discoveries are placed as polyomino pieces.  Exclusive placement: a discovery
## may only sit on one canvas at a time.  Session lock snapshots committed_intent
## into the Dialogic variable before a session begins.

# ─── Constants ────────────────────────────────────────────────────────────────

## 5×5 canvas grids (1 = valid cell, 0 = cutout).  Each has exactly 12 valid cells.
const CANVASES: Dictionary = {
	"heal": [
		[0,0,1,0,0],
		[0,1,1,1,0],
		[1,1,1,1,0],
		[0,1,1,1,0],
		[0,0,1,0,0],
	],
	"befriend": [
		[1,1,0,0,0],
		[1,1,1,0,0],
		[0,1,1,1,0],
		[0,0,1,1,1],
		[0,0,0,1,0],
	],
	"seduce": [
		[0,1,1,0,0],
		[1,1,0,0,0],
		[1,1,1,0,0],
		[0,1,1,1,0],
		[0,0,0,1,1],
	],
	"exploit": [
		[1,1,1,0,0],
		[1,0,1,1,0],
		[0,0,1,1,1],
		[0,0,0,1,0],
		[0,0,0,1,1],
	],
}

## Tag → affinity multiplier per intent.  Unlisted tags default to 0.5×.
const TAG_AFFINITY: Dictionary = {
	"heal": {
		"body_language": 1.0, "vulnerability": 1.5, "confession": 1.5,
		"contradiction": 1.0, "personal_detail": 0.5, "fantasy": 1.0,
		"control": 0.5, "denial": 0.5, "self_protection": 0.5,
	},
	"befriend": {
		"body_language": 0.5, "vulnerability": 1.0, "confession": 1.0,
		"contradiction": 0.5, "personal_detail": 1.5, "fantasy": 0.5,
		"control": 0.5, "denial": 0.5, "self_protection": 0.5,
	},
	"seduce": {
		"body_language": 1.5, "vulnerability": 1.0, "confession": 1.0,
		"contradiction": 0.5, "personal_detail": 1.0, "fantasy": 1.5,
		"control": 0.5, "denial": 0.5, "self_protection": 0.5,
	},
	"exploit": {
		"body_language": 1.0, "vulnerability": 1.5, "confession": 1.5,
		"contradiction": 1.5, "personal_detail": 0.5, "fantasy": 1.0,
		"control": 0.5, "denial": 0.5, "self_protection": 0.5,
	},
}

const FILL_BONUS: float  = 5.0
const INTENT_ORDER: Array = ["heal", "befriend", "seduce", "exploit"]
const CANVAS_SIZE: int    = 5

# ─── State ────────────────────────────────────────────────────────────────────

## _placements[patient][intent_id] = Array of placement dicts:
##   { "id": String, "row": int, "col": int, "rotation": int, "flipped": bool }
var _placements: Dictionary = {}
## _locked[patient] = bool
var _locked: Dictionary = {}


# ─── Setup ────────────────────────────────────────────────────────────────────

func _ensure_patient(patient: String) -> void:
	if not patient in _placements:
		_placements[patient] = {}
	if not patient in _locked:
		_locked[patient] = false
	for intent_id in INTENT_ORDER:
		if not intent_id in _placements[patient]:
			_placements[patient][intent_id] = []


# ─── Shape Transforms (static) ────────────────────────────────────────────────

## Rotate a 2D shape array 90° clockwise.
static func rotate_cw(shape: Array) -> Array:
	var rows: int = shape.size()
	if rows == 0:
		return []
	var cols: int = shape[0].size()
	var result: Array = []
	for c in range(cols):
		var row: Array = []
		for r in range(rows - 1, -1, -1):
			row.append(shape[r][c])
		result.append(row)
	return result


## Mirror a 2D shape array horizontally.
static func flip_h(shape: Array) -> Array:
	var result: Array = []
	for row in shape:
		var new_row: Array = row.duplicate()
		new_row.reverse()
		result.append(new_row)
	return result


## Return list of [row, col] Vector2i for every filled cell in the shape.
static func get_cells(shape: Array) -> Array:
	var cells: Array = []
	for r in range(shape.size()):
		for c in range(shape[r].size()):
			if shape[r][c] == 1:
				cells.append(Vector2i(r, c))
	return cells


## Remove empty leading/trailing rows and columns so the top-left filled cell is at (0,0).
static func normalize_shape(shape: Array) -> Array:
	if shape.is_empty():
		return []
	var min_r: int = 9999
	var min_c: int = 9999
	var max_r: int = 0
	var max_c: int = 0
	var any_filled: bool = false
	for r in range(shape.size()):
		for c in range(shape[r].size()):
			if shape[r][c] == 1:
				any_filled = true
				if r < min_r: min_r = r
				if c < min_c: min_c = c
				if r > max_r: max_r = r
				if c > max_c: max_c = c
	if not any_filled:
		return [[]]
	var result: Array = []
	for r in range(max_r - min_r + 1):
		var row: Array = []
		for c in range(max_c - min_c + 1):
			row.append(0)
		result.append(row)
	for r in range(shape.size()):
		for c in range(shape[r].size()):
			if shape[r][c] == 1:
				result[r - min_r][c - min_c] = 1
	return result


## Apply rotation (0–3 = ×90° CW) and flip, then normalize.
static func apply_transform(base_shape: Array, rotation: int, flipped: bool) -> Array:
	var result: Array = base_shape
	if flipped:
		result = flip_h(result)
	for _i in range(rotation % 4):
		result = rotate_cw(result)
	return normalize_shape(result)


static func _shapes_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for r in range(a.size()):
		if a[r].size() != b[r].size():
			return false
		for c in range(a[r].size()):
			if a[r][c] != b[r][c]:
				return false
	return true


## Return all distinct normalized orientations of a shape (up to 8).
static func all_orientations(base_shape: Array) -> Array:
	var seen: Array = []
	for flipped in [false, true]:
		var start: Array = flip_h(base_shape) if flipped else base_shape
		var current: Array = start
		for _rot in range(4):
			var norm: Array = normalize_shape(current)
			var is_dup: bool = false
			for s in seen:
				if _shapes_equal(s, norm):
					is_dup = true
					break
			if not is_dup:
				seen.append(norm)
			current = rotate_cw(current)
	return seen


# ─── Placement Logic ──────────────────────────────────────────────────────────

## Returns a 5×5 bool grid of occupied canvas cells for (patient, intent_id).
## If exclude_id is set, that discovery's cells are excluded (for ghost preview).
func get_occupied_grid(patient: String, intent_id: String, exclude_id: String = "") -> Array:
	_ensure_patient(patient)
	var grid: Array = []
	for _r in range(CANVAS_SIZE):
		var row: Array = []
		for _c in range(CANVAS_SIZE):
			row.append(false)
		grid.append(row)

	for placement in _placements[patient][intent_id]:
		if placement["id"] == exclude_id:
			continue
		var card := DiscoveryRegistry.get_card(placement["id"])
		if card == null or card.shape.is_empty():
			continue
		var shape: Array = apply_transform(card.shape, placement["rotation"], placement["flipped"])
		for cell in get_cells(shape):
			var gr: int = placement["row"] + cell.x
			var gc: int = placement["col"] + cell.y
			if gr >= 0 and gr < CANVAS_SIZE and gc >= 0 and gc < CANVAS_SIZE:
				grid[gr][gc] = true
	return grid


## Returns true if disc_id can be placed at (row, col) with the given transform.
## Pass exclude_id to ignore a piece already on this canvas (used when checking a re-place).
func can_place(patient: String, intent_id: String, disc_id: String,
		row: int, col: int, rotation: int, flipped: bool,
		exclude_id: String = "") -> bool:
	if _locked.get(patient, false):
		return false
	var card := DiscoveryRegistry.get_card(disc_id)
	if card == null or card.shape.is_empty():
		return false
	var canvas: Array = CANVASES.get(intent_id, [])
	if canvas.is_empty():
		return false
	var shape: Array = apply_transform(card.shape, rotation, flipped)
	var cells: Array = get_cells(shape)
	var occupied: Array = get_occupied_grid(patient, intent_id, exclude_id)
	for cell in cells:
		var gr: int = row + cell.x
		var gc: int = col + cell.y
		if gr < 0 or gr >= CANVAS_SIZE or gc < 0 or gc >= CANVAS_SIZE:
			return false
		if canvas[gr][gc] != 1:
			return false
		if occupied[gr][gc]:
			return false
	return true


## Remove disc_id from every canvas for this patient.
func _remove_from_all(patient: String, disc_id: String) -> void:
	for intent_id in INTENT_ORDER:
		var arr: Array = _placements[patient][intent_id]
		for i in range(arr.size() - 1, -1, -1):
			if arr[i]["id"] == disc_id:
				arr.remove_at(i)


## Place a discovery on (patient, intent_id) at (row, col) with the given transform.
## Auto-removes any existing placement for this discovery (exclusive).
## Returns true on success.
func place_discovery(patient: String, intent_id: String, disc_id: String,
		row: int, col: int, rotation: int, flipped: bool) -> bool:
	_ensure_patient(patient)
	if _locked.get(patient, false):
		return false
	# Remove from wherever it currently is.
	_remove_from_all(patient, disc_id)
	# Validate.
	if not can_place(patient, intent_id, disc_id, row, col, rotation, flipped):
		return false
	_placements[patient][intent_id].append({
		"id":       disc_id,
		"row":      row,
		"col":      col,
		"rotation": rotation,
		"flipped":  flipped,
	})
	# Fire fill bonus toast if canvas just became full.
	if is_canvas_full(patient, intent_id):
		if ToastLayer:
			ToastLayer.show_toast(
				"Canvas filled!",
				"Powerful insight unlocked for %s." % intent_id.capitalize(),
				"photo")
	return true


## Remove a single discovery from a specific canvas.
func remove_discovery(patient: String, intent_id: String, disc_id: String) -> void:
	_ensure_patient(patient)
	var arr: Array = _placements[patient][intent_id]
	for i in range(arr.size() - 1, -1, -1):
		if arr[i]["id"] == disc_id:
			arr.remove_at(i)
			return


## Returns all placements for (patient, intent_id) as an Array of dicts.
func get_placements(patient: String, intent_id: String) -> Array:
	_ensure_patient(patient)
	return _placements[patient][intent_id]


## Returns which intent canvas disc_id is currently on, or "" if unplaced.
func find_placement_canvas(patient: String, disc_id: String) -> String:
	_ensure_patient(patient)
	for intent_id in INTENT_ORDER:
		for p in _placements[patient][intent_id]:
			if p["id"] == disc_id:
				return intent_id
	return ""


# ─── Strength & Fill ──────────────────────────────────────────────────────────

## Compute intent strength = sum(weight × max_tag_affinity) for all placed pieces,
## plus FILL_BONUS if all valid canvas cells are covered.
func get_intent_strength(patient: String, intent_id: String) -> float:
	_ensure_patient(patient)
	var affinity_table: Dictionary = TAG_AFFINITY.get(intent_id, {})
	var strength: float = 0.0
	for placement in _placements[patient][intent_id]:
		var card := DiscoveryRegistry.get_card(placement["id"])
		if card == null:
			continue
		var max_mult: float = 0.0
		for tag in card.tags:
			var mult: float = affinity_table.get(tag, 0.5)
			if mult > max_mult:
				max_mult = mult
		strength += card.weight * max_mult
	if is_canvas_full(patient, intent_id):
		strength += FILL_BONUS
	return strength


## Returns true if every valid canvas cell is covered by a placed piece.
func is_canvas_full(patient: String, intent_id: String) -> bool:
	var canvas: Array = CANVASES.get(intent_id, [])
	if canvas.is_empty():
		return false
	var occupied: Array = get_occupied_grid(patient, intent_id)
	for r in range(CANVAS_SIZE):
		for c in range(CANVAS_SIZE):
			if canvas[r][c] == 1 and not occupied[r][c]:
				return false
	return true


## Returns the intent_id with the highest current strength, or "" if all are 0.
func get_committed_intent(patient: String) -> String:
	_ensure_patient(patient)
	var best_intent: String = ""
	var best_strength: float = 0.0
	for intent_id in INTENT_ORDER:
		var s: float = get_intent_strength(patient, intent_id)
		if s > best_strength:
			best_strength = s
			best_intent = intent_id
	return best_intent


# ─── Session Lock ─────────────────────────────────────────────────────────────

## Locks the board for a session and writes committed_intent to the Dialogic variable.
func lock_for_session(patient: String) -> void:
	_ensure_patient(patient)
	_locked[patient] = true
	var committed: String = get_committed_intent(patient)
	if Dialogic.VAR:
		Dialogic.VAR.set_variable("patients." + patient + ".committed_intent", committed)
	print("[HypothesisManager] %s locked — committed: '%s'" % [patient, committed])


## Unlocks the board after a session ends.
func unlock_after_session(patient: String) -> void:
	_ensure_patient(patient)
	_locked[patient] = false
	print("[HypothesisManager] %s unlocked." % patient)


## Returns true if the board is locked for a patient (during a session).
func is_locked(patient: String) -> bool:
	return _locked.get(patient, false)


## Returns true if a specific intent is locked out by meter/flag conditions.
func is_intent_locked_out(patient: String, intent_id: String) -> bool:
	if not Dialogic.VAR:
		return false
	var therapy: int = int(Dialogic.VAR.get_variable("patients." + patient + ".therapy_progress", 30))
	var bond: int    = int(Dialogic.VAR.get_variable("patients." + patient + ".personal_bond", 0))
	match intent_id:
		"heal":
			return bond < -20
		"befriend":
			return therapy < 15 and bond < 0
		"seduce":
			return therapy < 10
		"exploit":
			# TODO: check patients.{patient}_caught_exploiting flag when implemented
			return false
	return false


# ─── Save / Load ──────────────────────────────────────────────────────────────

## Returns a deep-copy of all placements for serialization.
func get_all_placements() -> Dictionary:
	return _placements.duplicate(true)


## Restores board state from a loaded save dictionary.
func load_placements(data: Dictionary) -> void:
	_placements = data.duplicate(true)
	# Ensure all patients have all intent arrays.
	for patient in _placements:
		for intent_id in INTENT_ORDER:
			if not intent_id in _placements[patient]:
				_placements[patient][intent_id] = []
	# Locks are not persisted — board is always unlocked after load.
	_locked = {}
