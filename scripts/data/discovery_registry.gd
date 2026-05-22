class_name DiscoveryRegistry
## Static registry of all DiscoveryCard definitions.
## Real content will be expanded in M15/M16; these are M11 placeholders for Anna.
##
## Usage:
##   var card := DiscoveryRegistry.get_card("anna_desk_compulsion")

static func get_card(id: String) -> DiscoveryCard:
	var data: Dictionary = _CARDS.get(id, {})
	if data.is_empty():
		printerr("[DiscoveryRegistry] Unknown id: '%s'" % id)
		return null
	var c := DiscoveryCard.new()
	c.id               = id
	c.patient          = data["patient"]
	c.short_label      = data["label"]
	c.description      = data["desc"]
	c.tags             = data["tags"]
	c.weight           = data["weight"]
	c.category         = data["category"]
	c.stat_requirement = data.get("requires", "")
	return c


# ─── Card definitions ─────────────────────────────────────────────────────────
# Format per entry:
#   patient  — "anna" | "marisol"
#   label    — short text shown in panel and patient file
#   desc     — longer description
#   tags     — array from: body_language, vulnerability, confession,
#               contradiction, personal_detail, fantasy, control, denial, self_protection
#   weight   — 1 | 2 | 3
#   category — observation | confession | contradiction | vulnerability
#   requires — (optional) "stat_name >= N"  e.g. "perception >= 2"

const _CARDS: Dictionary = {

	# ── Anna · Session 1 ──────────────────────────────────────────────────────

	"anna_desk_compulsion": {
		"patient":  "anna",
		"label":    "The desk rearrangement",
		"desc":     "Rearranged your workspace within two minutes of arrival. Unsolicited. Thorough. Satisfied.",
		"tags":     ["body_language", "control"],
		"weight":   1,
		"category": "observation",
	},
	"anna_anyway_tell": {
		"patient":  "anna",
		"label":    "\"Anyway\" as a hard pivot",
		"desc":     "Uses \"anyway\" to close any line of conversation that approaches something real.",
		"tags":     ["body_language"],
		"weight":   1,
		"category": "observation",
	},
	"anna_autonomy_discomfort": {
		"patient":  "anna",
		"label":    "Discomfort with autonomy",
		"desc":     "States her boss gives her full latitude. Her expression indicates this is not, in fact, welcome.",
		"tags":     ["control", "denial"],
		"weight":   2,
		"category": "observation",
		"requires": "perception >= 2",
	},

	# ── Anna · Session 2 ──────────────────────────────────────────────────────

	"anna_dream_spreadsheet": {
		"patient":  "anna",
		"label":    "The color-coded dream journal",
		"desc":     "Kept a pivot-table spreadsheet of recurring dream elements. Filed under 'sleep data'.",
		"tags":     ["control", "confession"],
		"weight":   2,
		"category": "confession",
	},
	"anna_rubric_wish": {
		"patient":  "anna",
		"label":    "The rubric dream was a wish",
		"desc":     "The structured-direction dream wasn't anxiety — it was desire. She didn't deny it when pressed.",
		"tags":     ["vulnerability", "confession"],
		"weight":   3,
		"category": "vulnerability",
		"requires": "intellect >= 2",
	},
}
