# Mind Harvest — Game Design Document
**Version:** 1.0 (Full Design)
**Engine:** Godot 4.6.2
**Dialogue:** Dialogic 2.x
**Project path:** `K:\Godot projects\mind-harvest`

This document is the source of truth for the game. It is written to be directly actionable by Claude Code working against the Godot project. Sections marked **[TUNABLE]** are intentional knobs.

---

## 1. Concept

The player is **Dr. [name TBD]**, a newly licensed therapist running a small private practice. Female patients come in to talk through issues that usually turn out to be barely-disguised obsessions, fixations, or romantic preoccupations. Tone is **light, comedic, self-aware**. Fan-service is delivered through the **Photo Album** — a collectible system where the player snaps reaction-timing photos at amusing or revealing moments.

Core fantasy: *be a clever, observant therapist who reads people well, decides what kind of relationship to pursue with each patient, and accidentally builds a very questionable photo collection along the way.*

**Genre:** Visual Novel / Dating Sim / Stat-driven Adventure with deduction layer
**Mood:** Light, comedic, slightly cheeky. Not serious. Not edgy. Not crude.
**Reference points:** Persona's calendar and confidant ranks, HuniePop's stat layer, Disco Elysium's deduction-as-gameplay, classic VN dialogue depth.

---

## 2. Core Game Loop

```
  [Day N begins]
        │
        ▼
   MORNING PHASE  ── pick 2 activities ──► gain stats / lore
        │
        ▼
    DAY PHASE  ── meet scheduled patients ──► branching dialogue + note-taking
                                              ├── stat-gated options
                                              ├── stat+RNG checks
                                              ├── note opportunities → discoveries
                                              └── photo opportunities
        │
        ▼
   BETWEEN SESSIONS  ── review patient files
                    ── arrange discoveries on hypothesis boards
                    ── commit intent for next session
        │
        ▼
   END OF DAY  ── auto-save ──► [Day N+1]
```

Two major systems run on top of dialogue: the **hypothesis system** (note-taking → discoveries → board commitment) and the dual-axis **patient progression** (Therapy Progress + Personal Bond). Patient arc length is emergent — the prototype ends when both Anna and Marisol reach a terminal ending state.

---

## 3. Player Character

- **Name:** TBD (placeholder: "Dr. Adrian Cole")
- **Starting stats:** all 5 at value `1` (range 0–10)
- **Backstory hook:** Just opened solo practice after leaving a stuffy clinic. Took over a shared building with a sharp-tongued receptionist (Bea) who came with the lease.

No avatar selection in the prototype; player character is depicted through dialogue and a desk-POV framing.

---

## 4. Stat System

Five stats, integer `0–10`. Stored as **Dialogic variables**.

| Stat | Domain | Affects |
|---|---|---|
| **Perception** | Reading people, noticing detail, reflexes | Best notes during session, photo QTE window, body_language discoveries |
| **Intellect** | Deduction, pattern recognition | Contradiction discoveries, hypothesis-board capacity, clever dialogue |
| **Knowledge** | Clinical/academic frameworks, references | "I know what this is" options, post-prototype diagnostic frames |
| **Composure** | Emotional endurance, professional mask | Surviving heavy beats, resisting trust loss under pressure |
| **Nerve** | Willingness to push past professional norms | Seduce/Exploit options, inappropriate-but-effective choices |

**Caps:** soft `5`, hard `10`. **[TUNABLE]**
**Display:** color-coded stat row in top HUD bar.

---

## 5. Day Structure

### 5.1 Morning Phase

UI: apartment background + activity selection (Dialogic timeline `morning_menu.dtl`).

- **Time slots per morning:** 2 **[TUNABLE]**
- Each activity = its own timeline under `dialogic/timelines/morning/`.

| Activity | Primary effect | Secondary |
|---|---|---|
| Review Patient Files | +1 Knowledge (75% roll) | Previews scheduled patients |
| Read a Book | +1 Intellect (60% roll) | Flavor text |
| Jogging | +1 Composure (70% roll) | — |
| Chat with Bea | +1 Perception (50% roll) | Bea relationship +1 |
| Analyze Last Session | +1 Insight (one-time per patient) | Unlocks patient-specific options |
| Go for a Walk | +1 Nerve (50% roll) | Random encounter hook (reserved) |

### 5.2 Day Phase

Office background. `GameState` autoload feeds the queue. Between-patient menu:

- **Next patient** (auto if queue not empty)
- **Open Patient Files** (case file + hypothesis board + photo album)
- **End Day**

Each session is one timeline (`dialogic/timelines/patients/{patient}/session_{N}.dtl`), selected by `patients.{name}.sessions_done`.

### 5.3 Patient Scheduling

Patients do **not** appear every day:

- After each session: `patients.{name}.next_day = game.day + 2`. **[TUNABLE]**
- Day-start queue = patients where `next_day <= game.day` AND `ending == ""`.
- Empty queue = free day (morning only, brief Bea scene).

**Patient arc length is emergent.** Sessions are not numbered against a known total. Arcs resolve when meter values + committed intent meet ending conditions. Most run 3–5 sessions. UI never shows "Session 2 of 3" — only "2 sessions completed."

Players sense arc proximity through:
- Qualitative meter captions that progress through stages
- Bea's between-session comments ("She seems close to a turning point")
- Optional arc-state hint when patient is near an ending ("Something is about to change")

### 5.4 End of Day

- Auto-save (slot 0 + 3 manual).
- Optional summary screen: stats gained, photos collected, meter deltas.
- Fade to Day N+1.

---

## 6. Dialogue System (Dialogic-First)

**Principle:** timelines own as much logic as possible. GDScript handles QTE, save data, UI screens, drag-and-drop only.

### 6.1 Variable Schema

```
stats/
  perception   : int = 1
  intellect    : int = 1
  knowledge    : int = 1
  composure    : int = 1
  nerve        : int = 1

game/
  day                : int = 1
  phase              : string = "morning"
  morning_slots_left : int = 2
  current_patient    : string = ""

flags/
  intro_done   : bool = false
  met_anna     : bool = false
  met_marisol  : bool = false
  # per-scene flags prefixed with patient name

patients/
  anna/
    therapy_progress : int = 30        # 0–100
    personal_bond    : int = 0         # -50 to +50
    sessions_done    : int = 0
    next_day         : int = 1
    committed_intent : string = ""     # "" | "heal" | "befriend" | "seduce" | "exploit"
    ending           : string = ""
  marisol/
    [same shape]
```

### 6.2 Choice Gating

Hidden-when-locked. Options whose `condition` fails are not rendered.

```
- "You sound frustrated." [if {stats.composure} >= 2]
- "You're clearly a control freak." [if {stats.intellect} >= 3]
- "Tell me what you really think." [if {patients.anna.committed_intent} == "exploit"]
```

### 6.3 StatCheck Event

```
[stat_check stat="perception" threshold=2 chance_per_point=10 base_chance=40 result="check_result"]
```

Rolls `base_chance + max(0, stat-threshold) * chance_per_point` against `randi() % 100`. Writes bool to named var.

### 6.4 Branching

One timeline per session. Across sessions, `PatientManager.get_next_session("anna")` picks the right `.dtl` based on `sessions_done`.

### 6.5 Voice Integration

Each text event carries a `line_id` (`{node_id}_{line_index}`). `VoicePlayer` autoload listens for Dialogic's text-shown signal, plays `assets/audio/voice/{patient}/{line_id}.ogg` if present. Silent fallback for missing files.

---

## 7. Note-Taking and Hypothesis System

### 7.1 Overview

The hypothesis system is an **opt-in power tool** for players with directional goals. Neutral play (no commitment) is a complete VN experience. Committed play unlocks dialogue options, perks, and steered endings.

Two layers:
- **Discoveries** — observations noted during sessions
- **Hypothesis Board** — between-session UI where discoveries are placed into intent slots

### 7.2 Note-Taking During Session

At key beats, the timeline fires an `OfferNotes` event. A notes panel surfaces 2–4 options:

- **Always available** — surface observation
- **Stat-gated** — requires Perception, Intellect, etc.
- **Knowledge-gated** — requires prior discovery or fact

Picking a note adds a `DiscoveryCard`. Skipping is allowed; the better option is just gone.

**Per-session note cap:** 4. **[TUNABLE]**

### 7.3 Discovery Cards

```gdscript
class_name DiscoveryCard extends Resource

@export var id              : String
@export var patient         : String
@export var session_added   : int
@export var short_label     : String
@export var description     : String
@export var tags            : Array[String]
@export var weight          : int = 1            # 1–3
@export var category        : String             # observation | confession | contradiction | vulnerability
```

**Categories:**
- **Observation** — body language, tics. Common. Weight 1.
- **Confession** — patient said something revealing. Rare. Weight 2-3.
- **Contradiction** — caught in inconsistency. Requires Intellect. Weight 2-3.
- **Vulnerability** — true exposure. Highest. Weight 3.

**Tags:** `body_language`, `vulnerability`, `confession`, `contradiction`, `personal_detail`, `fantasy`, `control`, `denial`, `self_protection`.

### 7.4 The Four Intents

Fixed across all patients. Each maps to a quadrant of the outcome space (see §8).

| Intent | Description | Primary axis effect |
|---|---|---|
| **Heal** | Guide her toward genuine breakthrough | Therapy ↑↑↑, Bond +/− neutral |
| **Befriend** | Drop the professional mask | Bond ↑↑↑, Therapy ↓ slightly |
| **Seduce** | Pursue genuine romance | Bond ↑↑, Therapy context-dependent |
| **Exploit** | Use her vulnerability for self-gain | Both volatile, hidden gains, catastrophic-loss risk |

Player can commit zero, one, or partial filling of multiple intents. **Neutral play (zero commitment) = unmodified game.**

### 7.5 Discovery → Intent Affinity

Strength contribution = base weight × tag-match multiplier.

| Tag | Heal | Befriend | Seduce | Exploit |
|---|---|---|---|---|
| body_language | ★★ | ★ | ★★★ | ★★ |
| vulnerability | ★★★ | ★★ | ★★ | ★★★ |
| confession | ★★★ | ★★ | ★★ | ★★★ |
| contradiction | ★★ | ★ | ★ | ★★★ |
| personal_detail | ★ | ★★★ | ★★ | ★ |
| fantasy | ★★ | ★ | ★★★ | ★★ |

★ = 0.5×, ★★ = 1.0×, ★★★ = 1.5×.

### 7.6 The Hypothesis Board

Per-patient corkboard accessible from the Case File.

- **Left:** draggable discovery card stack.
- **Right:** four intent slots (Heal, Befriend, Seduce, Exploit), 3 drop zones each.

A discovery can be placed in multiple intents (not consumed, *applied*).

**Per-intent strength:**
```
sum( discovery_weight * tag_match_multiplier ) across 3 slots
Max ≈ 9 (three vulnerability-tagged discoveries at perfect match)
```

**Commitment:**
- Board editable between sessions.
- Next session start = **locks** for that session.
- After session: unlocks for rearrangement.

### 7.7 Mechanical Effects (per intent, where `S` is strength)

**Heal:**
- Composure checks +5%×S chance
- Therapeutic-insight options unlock
- Patient more likely to volunteer vulnerable content

**Befriend:**
- Non-clinical options unlock ("How was your weekend?")
- Bond gains +1×S on successful interactions
- Some therapy-specific options become unavailable

**Seduce:**
- "Playful" tone options unlock; new photo opportunities
- Nerve checks +5%×S
- Trust-loss risk on accidentally heavy moments

**Exploit:**
- "Leverage" options unlock at vulnerable moments
- Intellect checks +5%×S for catching lies
- Hidden Exploit Points accumulate, redeemable for between-session events
- Catastrophic Bond loss if patient catches on

### 7.8 Intent Lockout (Narrative Consequences)

Intents can become **unavailable** mid-arc when meters cross thresholds:

- **Heal locked** when Personal Bond < −20 (therapeutic relationship broken)
- **Befriend locked** when Therapy < 15 AND Bond < 0 (no warmth to build on)
- **Seduce locked** when Therapy < 10 (insufficient trust)
- **Exploit locked** when caught (flag set by failed Exploit attempt)

Locked intents appear greyed-out with a short reason. Parsed as narrative consequence, not arbitrary restriction.

---

## 8. Dual-Axis Patient Progression

### 8.1 The Two Axes

**Therapy Progress** — professional axis. Is the therapy working?
- Range: `0–100`, starts `30`
- Endpoints: `STRANGER` (0) → `BREAKTHROUGH` (100)
- Gained by: successful Heal-aligned actions, accurate diagnoses, validating responses
- Lost by: getting things wrong, breaking confidentiality, inappropriate behavior during therapeutic moments

**Personal Bond** — personal axis. What's the patient's relationship to the player *as a person*?
- Range: `-50 to +50`, starts `0`
- Endpoints: `HOSTILE` (−50) → neutral (0) → `DEVOTED` (+50)
- Gained by: personal disclosure, Befriend/Seduce-aligned moves, between-session contact, remembered details
- Lost by: cold professionalism after intimacy, broken promises, betrayal
- Driven negative by: caught manipulation, public humiliation, malicious Exploit moves

### 8.2 Quadrant Map

```
                  HIGH PERSONAL BOND
                          │
        DEVOTEE                LOVER
   the work isn't            the work works
   working but she           and she's
   adores you                in love
                          │
LOW THERAPY ──────────────┼────────────── HIGH THERAPY
                          │
       NEMESIS                GRADUATE
   the work failed          the work worked
   and she hates you        clean professional
                            outcome
                          │
                  LOW PERSONAL BOND
```

Ending family by quadrant. Specific ending steered by committed intent over the arc and key story flags.

### 8.3 Ending Resolution

```
final_therapy >= 70 AND final_bond >= +20  → LOVER family
final_therapy >= 70 AND final_bond <  +20  → GRADUATE family
final_therapy <= 30 AND final_bond >= +20  → DEVOTEE family
final_therapy <= 30 AND final_bond <= -20  → NEMESIS family
intermediate                                → arc continues
```

Within each family, specific ending narrated based on intent history. Anna's GRADUATE ending differs sharply via Heal (sincere thanks) vs. Exploit (leaves diminished, doesn't know why).

### 8.4 UI Display

Both meters in Case File with min/max labels:
- Therapy: `0 · STRANGER` ↔ `BREAKTHROUGH · 100`, left-to-right fill
- Bond: `−50 · HOSTILE` ↔ `0` ↔ `DEVOTED · +50`, outward-from-center fill

Qualitative captions shift through stages. See §10.

---

## 9. Photo Capture System

### 9.1 Design

Reflex moment embedded in session timelines. Camera icon flashes. Click within window → capture. Miss → moment passes.

### 9.2 PhotoOpportunity Event

```
[photo_opportunity
    id="anna_desk_demo"
    patient="anna"
    title="The Desk Demonstration"
    description="Anna re-enacting her boss's spreadsheet."
    window_ms=1500
    perception_bonus_ms=300
    portrait="res://assets/photos/anna_desk_demo.png"]
```

Effective window = `window_ms + (stats.perception * perception_bonus_ms)`.
On success: adds to album, +3 Bond, optionally +1 Nerve (rare). **[TUNABLE]**
On miss: no penalty, moment lost for that playthrough.

---

## 10. UI Specification

### 10.1 Design Tokens

```
panel_bg_strong = Color(0.11, 0.094, 0.078, 0.88)
panel_bg_soft   = Color(0.11, 0.094, 0.078, 0.78)
text_primary    = Color(0.961, 0.925, 0.859)   # #f5ecdb
text_accent     = Color(0.753, 0.659, 0.471)   # #c0a878
accent_success  = Color(0.592, 0.769, 0.349)   # #97c459
accent_warning  = Color(0.937, 0.690, 0.286)   # #efb049
accent_info     = Color(0.353, 0.624, 0.831)   # #5a9fd4
accent_intimate = Color(0.847, 0.659, 0.659)   # #d8a8a8

stat_color_perception = #d8a8a8
stat_color_intellect  = #9fb8d8
stat_color_knowledge  = #a8c896
stat_color_composure  = #c0a878
stat_color_nerve      = #efb049

discovery_color_observation    = #d8a8a8
discovery_color_vulnerability  = #97c459
discovery_color_confession     = #efb049
discovery_color_contradiction  = #5a9fd4
```

### 10.2 Top HUD Bar

Full-width, anchored top, ~40px, `panel_bg_soft`.
- Left: Day · phase · current patient
- Right: five stat groups (color-coded labels + values)

Separate CanvasLayer autoload above Dialogic.

### 10.3 Dialogue Panel (anchored)

Bottom-right anchored, from ~28% screen width to right and bottom edges. `panel_bg_strong`. Top-left corner radius 12px only. Speaker name label (per-character color) above body text. Min height ~3 lines for stability.

Implemented as Dialogic layer (`text_box_anchored.tscn`) in custom `DialogicStyle` at `res://dialogic/styles/mind_harvest/`.

### 10.4 Notes Panel (in-session)

Adjacent to dialogue panel, surfaces 2–4 note options during `OfferNotes` beats. Same panel style. Only visible during note opportunities.

### 10.5 Toast Notifications

Top-right, 60px below HUD, 240px wide, 8px gap. 3px left accent border by category:
- Green: success / positive
- Amber: failure / warning
- Blue: stat gain
- Gold: photo / intent commit

Slide in (200ms), hold 2500ms, fade (300ms). Stack newest on top, cap 3 visible. Consolidate multiple effects from one choice into a single toast.

### 10.6 Patient File View

Three-column:

**Left (260px)** — identity:
- 100×100 portrait + name + age/occupation
- Therapy meter (endpoint labels)
- Bond meter (endpoint labels)
- Committed Intent block (intent + strength + lock status)
- Buttons: Hypothesis · Photos

**Center** — case notes:
- Per-session note paragraphs
- Discoveries list with category-colored dots

**Right** — timeline:
- Vertical timeline of events with deltas
- Filled dots past, hollow dot next scheduled

Session counters never show a denominator.

### 10.7 Hypothesis Board View

Two regions:
- Left: draggable discovery stack (~240px)
- Right: four intent regions, 3 drop slots each, strength meter, color-coded

Locked intents greyed with reason. Changes commit at next session start.

### 10.8 Photo Album

Grid per patient, click to enlarge with title + description.

---

## 11. Example Characters

### 11.1 Anna Volkov — "The Accountant"

- **Age:** 29
- **Occupation:** Senior accountant
- **Surface complaint:** Work stress, insomnia
- **Actual fixation:** Craves micromanagement; her control-freak boss won't *let* her control anything, and she can't admit she finds being given precise demanding orders satisfying. Comedic D/s-curious framing.
- **Personality:** Hyper-organized, panics at merged cells, says "anyway" to deflect.
- **Available intents:** Heal, Befriend, Seduce, Exploit (all four).

**Arc beats (variable session count):**

- **Early:** Surface complaints. Photo: *the desk demonstration*.
- **Mid:** "Weird dream" content slips out. Photo: *the color-coded dream journal*.
- **Late:** Resolution by quadrant + intent. Examples:
  - GRADUATE via Heal: admits desire, plans healthy outlet
  - LOVER via Seduce+Heal: finds the desire in a relationship with player
  - DEVOTEE via Befriend+Seduce, low Therapy: obsessed with player, therapy stalled
  - NEMESIS via caught Exploit: files complaint, professional disaster
  - GRADUATE via uncaught Exploit: leaves diminished, doesn't know why

### 11.2 Marisol Reyes — "The Novelist"

- **Age:** 34
- **Occupation:** Bestselling romance novelist (pen name: Maribelle de la Vega)
- **Surface complaint:** Writer's block
- **Actual fixation:** Compulsive pirate-romance fantasizing. Real life feels gray. Three cats named after her ex-husbands' literary opposites.
- **Personality:** Dramatic, theatrical, accidentally narrates her own life. Cigarette holder with no cigarette.
- **Available intents:** Heal, Befriend, Seduce, Exploit.

**Arc beats:**

- **Early:** Performs writer's block, slips into character. Photo: *the swoon*.
- **Mid:** Reveals she's writing the therapist into her manuscript. Photo: *the manuscript*.
- **Late:** Examples:
  - GRADUATE via Heal: channels energy back into work, finishes book
  - LOVER via Seduce: writes player into her best-seller dedication
  - DEVOTEE via Befriend high, Therapy low: keeps player as permanent muse
  - NEMESIS via Exploit caught: writes player as the villain

### 11.3 Beatrix "Bea" Chen — Receptionist

- **Age:** 27
- **Role:** Receptionist, sarcastic asides, brings coffee
- **Prototype function:**
  - Announces each patient
  - 2–3 morning chat timelines (Bea relationship tracked, future arc hooks reserved)
  - Comments on patient progress (replaces session-counter UI with narrative cues)
- **Personality:** Dry, observant. Calls the doctor "Doc" exclusively. Smartest person in the building.

---

## 12. Save System

Layered:
- **Dialogic state** — built-in via `Dialogic.Save.save("slot_N")`
- **Custom state** — `GameSave` resource at `user://save_slot_N.tres`
- **Triggers:** auto-save on End of Day → slot 0; manual via menu (3 slots); no mid-session saves

```gdscript
class_name GameSave extends Resource

@export var version : int = 1
@export var day : int = 1
@export var photos_by_patient : Dictionary = {}
@export var notes_by_patient : Dictionary = {}
@export var discoveries_by_patient : Dictionary = {}
@export var board_state_by_patient : Dictionary = {}   # intent → array of discovery ids
@export var bea_relationship : int = 0
@export var dialogic_save_slot : String = "slot_0"
```

---

## 13. Content Production Pipeline (External)

### 13.1 Script via SillyTavern

Custom Director system prompt enforces node-based format. Workflow:

1. One ST chat per scene (`anna_session_1` etc.)
2. Write trunk linearly; swipe for variation
3. At choice points, use ST's Create Branch once per option; name branches by choice label
4. Continue each branch independently. Merges via shared node IDs
5. Export all related chats as JSONL

### 13.2 Conversion

`pipeline/convert.py`:
- Parses JSONL chats
- Reconstructs tree from ST branch metadata
- Emits Dialogic `.dtl` timelines
- Emits `lines.csv` (`line_id, character, text`)

### 13.3 TTS

`pipeline/tts_render.py` reads `lines.csv` + `voices.yaml`, calls TTS API (ElevenLabs recommended), saves `assets/audio/voice/{patient}/{line_id}.ogg`. Caches by content hash.

### 13.4 Asset Integration

- `.dtl` → `res://dialogic/timelines/patients/{patient}/`
- `.ogg` → `res://assets/audio/voice/{patient}/`
- Hand-edit in Godot to insert `OfferNotes`, `PhotoOpportunity`, `StatCheck` events at appropriate beats

---

## 14. Technical Architecture

### 14.1 Folder Structure

```
mind-harvest/
├── project.godot
├── addons/dialogic/
├── docs/GDD.md
├── scenes/
│   ├── main.tscn
│   ├── ui/
│   │   ├── hud_bar.tscn
│   │   ├── toast_container.tscn
│   │   ├── notes_panel.tscn
│   │   ├── morning_menu.tscn
│   │   ├── patient_file_view.tscn
│   │   ├── hypothesis_board.tscn
│   │   ├── photo_album.tscn
│   │   └── photo_qte_overlay.tscn
│   └── transitions/day_fade.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd
│   │   ├── patient_manager.gd
│   │   ├── hypothesis_manager.gd
│   │   ├── save_manager.gd
│   │   └── voice_player.gd
│   ├── dialogic_events/
│   │   ├── stat_check_event.gd
│   │   ├── photo_opportunity_event.gd
│   │   ├── offer_notes_event.gd
│   │   ├── add_note_event.gd
│   │   ├── apply_meter_delta_event.gd
│   │   └── end_day_event.gd
│   ├── save/game_save.gd
│   └── data/
│       ├── photo_data.gd
│       ├── discovery_card.gd
│       └── intent_definition.gd
├── dialogic/
│   ├── styles/mind_harvest/
│   │   ├── mind_harvest_style.tres
│   │   ├── layers/text_box_anchored.tscn
│   │   └── theme/mind_harvest_theme.tres
│   ├── timelines/
│   │   ├── system/
│   │   ├── morning/
│   │   └── patients/{anna,marisol}/
│   └── characters/{player,bea,anna,marisol}.dch
├── assets/
│   ├── portraits/{anna,marisol,bea}/
│   ├── backgrounds/
│   ├── photos/{anna,marisol}/
│   ├── audio/voice/{anna,marisol,bea}/
│   └── ui/
└── pipeline/   # external, not shipped
    ├── convert.py
    └── tts_render.py
```

### 14.2 Autoloads

| Autoload | Responsibility |
|---|---|
| **GameState** | Day/phase, patient queue, day advance |
| **PatientManager** | Per-patient meters, discoveries, photos, notes |
| **HypothesisManager** | Board state, intent strength, active perks |
| **SaveManager** | `GameSave` + Dialogic save delegation |
| **VoicePlayer** | Plays per-line voice files on Dialogic signals |

### 14.3 Custom Dialogic Events

| Event | Purpose |
|---|---|
| `StatCheck` | Roll stat+RNG, write result to var |
| `PhotoOpportunity` | QTE; on success adds photo |
| `OfferNotes` | Surface note options, on pick add discovery |
| `AddNote` | Direct programmatic note add (no UI) |
| `ApplyMeterDelta` | Adjust Therapy / Bond with reasons |
| `EndDay` | Save + day++ + phase reset |
| `StartSession` | Launch right patient timeline by `sessions_done` |

---

## 15. Implementation Milestones

Each milestone = one Claude Code session of scope. Independently testable.

### Foundation (already built per v0.2)
- **M1** ✓ Skeleton loop (morning → day → end)
- **M2** ✓ Stats + activities, choice gating, `StatCheck`
- **M3** ✓ Photo Opportunity event + QTE overlay
- **M4** ✓ Patient Files UI basics, notes via `AddNote`
- **M5** ✓ Save/load with 3 slots + autosave
- **M6** ✓ Anna full arc (original 3-session structure)
- **M7** ✓ Marisol full arc (original 3-session structure)
- **M8** ✓ Polish: Bea banter, end-of-day summary, transitions

### Expansion

**M9 — Stat overhaul to 5 stats.**
Rename `Intelligence` → `Intellect`, `Patience` → `Composure`. Add `Nerve`. Update timelines, choice conditions, morning activities, HUD. Save migration: missing Nerve defaults to `1`.
*Acceptance: morning activities grant correct stats; all choice gates use new names; HUD shows 5 stats.*

**M10 — Dual-axis patient progression.**
Replace `trust` with `therapy_progress` (0-100) and `personal_bond` (-50 to +50). Update timeline writes. Quadrant-based ending resolution. Patient file shows both meters with endpoint labels. Save migration: old trust → therapy_progress, bond → 0.
*Acceptance: both meters visible, deltas apply correctly, ending resolution uses quadrants.*

**M11 — Custom Dialogic style + HUD + toasts.**
Build `mind_harvest_style.tres` + `text_box_anchored.tscn`. Anchored bottom-right panel, top-left radius only, speaker label. HUD bar autoload. Toast container autoload. Shared `mind_harvest_theme.tres`.
*Acceptance: new style applied; HUD always visible; toasts fire from `ApplyMeterDelta` and `StatCheck`.*

**M12 — Discovery system foundation.**
`DiscoveryCard` resource, `OfferNotes` event, in-session notes panel. PatientManager stores per-patient discoveries. Patient File shows discovery list with colored dots. No board yet.
*Acceptance: timeline can offer notes mid-session, player picks one, discovery appears in patient file.*

**M13 — Hypothesis Board UI.**
`hypothesis_board.tscn` with drag-and-drop. `IntentDefinition` resource. HypothesisManager computes strengths. Board accessible from patient file. Commitment locks at session start. Empty board = neutral.
*Acceptance: discoveries drag into slots, strengths display, board persists, commitment locks per session.*

**M14 — Intent perk system.**
Apply mechanical effects of committed intents. `committed_intent` Dialogic var per patient. Timeline `if` gates intent-specific options. StatCheck reads intent for bonuses. Lockout rules (Heal off below −20 Bond, etc.).
*Acceptance: committing Heal grants new options in Anna's session; Composure checks show bonus; locked intents grey out when conditions met.*

**M15 — Variable arc length.**
Remove fixed 3-session structure. Arcs resolve on meter+intent ending conditions. `sessions_done` exists but doesn't gate. Patient file shows "N sessions completed" without total. Bea hint dialogue near ending states.
*Acceptance: Anna can resolve at session 3 or 5 depending on play; UI shows no total.*

**M16 — Content layer: Anna expanded arc.**
~25 discovery cards. Expanded session timelines. Per-quadrant endings (4-6 distinct). Note opportunities throughout. New photos.
*Acceptance: Anna playable to distinct endings in all four intent directions.*

**M17 — Content layer: Marisol expanded arc.**
Same scope as M16.
*Acceptance: Marisol playable to all four endings.*

**M18 — TTS pipeline integration.**
`pipeline/convert.py` + `pipeline/tts_render.py`. `VoicePlayer` autoload. `voices.yaml` config. Voice files play on text signals.
*Acceptance: scripted line plays TTS audio file.*

**M19 — Polish.**
Qualitative meter captions across both patients. Bea arc-state hints. Toast consolidation. Album improvements. Save migration paths.
*Acceptance: full playthrough of both patients with all systems active feels integrated and responsive.*

---

## 16. Tunable Parameters

- Stat caps (soft 5, hard 10)
- Morning slots per day (2)
- Patient appointment cooldown (2 days)
- StatCheck `base_chance` / `chance_per_point` (40 / 10)
- Photo opportunity window (1500ms + 300ms/Perception)
- Meter deltas per event
- Quadrant thresholds (Therapy ≥70 / ≤30, Bond ≥+20 / ≤−20)
- Notes per session cap (4)
- Intent strength cap (3 slots × max weight)

---

## 17. Out of Scope (Prototype)

- More than 2 patients
- Bea full romance arc
- Diagnostic frame meta-cards (reserved post-prototype)
- Random encounters during Walk
- Money / shop / customization
- Localization
- Mobile / touch input
- Real art (placeholders fine)
- Achievements beyond photos
- New Game+
- Mid-session save/load

---

## 18. Design Principles

1. **Dialogic-first.** Put what can be in timelines. Custom events bridge to engine features.
2. **One session = one timeline file.**
3. **Variables are canonical state during play.** Autoloads mirror for UI but read from Dialogic vars at session start.
4. **Custom events expose parameters.** Never hardcode tuning inside event implementations.
5. **The hypothesis system is opt-in.** Neutral play is a complete experience.
6. **Player respect.** Intent endings land without judgment. Comedic frame absorbs all four directions.
7. **Variable arc length is a feature.** Resist surfacing session counters or progress percentages.
8. **Fail loud.** Content bugs visible, not silently swallowed.
9. **Placeholder-friendly.** Systems testable without finished art or audio.
