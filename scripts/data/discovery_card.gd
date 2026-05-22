class_name DiscoveryCard
extends Resource
## A single observation or revelation noted during a session.
## Cards are defined in DiscoveryRegistry and instantiated at runtime.

## Unique identifier matching a key in DiscoveryRegistry._CARDS.
@export var id: String = ""
## Patient this discovery belongs to.
@export var patient: String = ""
## sessions_done value when this card was added (set by PatientManager).
@export var session_added: int = 0
## Short text shown in the notes panel and patient file.
@export var short_label: String = ""
## Longer description shown on hover / in the patient file.
@export var description: String = ""
## Hypothesis-board tags. See GDD §7.3.
@export var tags: Array[String] = []
## Contribution weight: 1 (common) · 2 (notable) · 3 (rare/heavy).
@export var weight: int = 1
## observation | confession | contradiction | vulnerability
@export var category: String = "observation"
## Stat gate shown in the notes panel. Format: "perception >= 2". Empty = always available.
@export var stat_requirement: String = ""
