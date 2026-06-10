# Mind Harvest — Game Design Document
**Version:** 0.2 (Defaults Locked)
**Engine:** Godot 4.6.2
**Dialogue:** Dialogic 2.x
**Project path:** `K:\Godot projects\mind-harvest`

This document is the source of truth for the prototype. It is written to be directly actionable by Claude Code working against the Godot project. Sections marked **[TUNABLE]** are intentional knobs; **[TBD]** marks decisions that depend on designer answers.

---

## 1. Concept

The player is **Dr. [name TBD]**, a newly licensed therapist running a small private practice. Each day, female patients come in to talk through their issues — which usually turn out to be barely-disguised secret obsessions, kinks, or romantic fixations. The tone is **light, comedic, and self-aware**, leaning into VN/dating-sim tropes. Fan-service is delivered through the **Photo Album**: a collectible system where the player snaps reaction-timing photos of patients at amusing/revealing moments during sessions.

The core fantasy is: *be a clever, observant, slightly mischievous therapist who reads people well, helps them (more or less), and accidentally builds a very questionable photo collection along the way.*

**Genre:** Visual Novel / Dating Sim / Stat-driven Adventure
**Mood:** Light, comedic, slightly cheeky. Not serious. Not edgy. Not crude.
**Reference points:** HuniePop's stat layer, Persona's calendar/day structure, classic VN dialogue depth.

---

## 2. Core Game Loop

```
  [Day N begins]
        │
        ▼
   MORNING PHASE  ── pick 2 activities ──► gain stats / lore
        │
        ▼
    DAY PHASE  ── meet each patient ──► branching dialogue
                                        ├── stat-gated options
                                        ├── stat+RNG checks
                                        └── photo opportunities
        │
        ▼
   END OF DAY  ── auto-save ──► [Day N+1]
```

The player can choose to end the day at any time during the Day Phase from a between-patients menu. Skipped patients return next day with no penalty (configurable).

---

## 3. Player Character

- **Name:** TBD (placeholder: "Dr. Adrian Cole")
- **Starting stats:** all 4 at value `1` (range 0–10)
- **Backstory hook:** Just opened solo practice after leaving a stuffy clinic. Took over a shared building with a sharp-tongued receptionist (Bea) who came with the lease.

Player character is depicted only through dialogue and (optionally) a desk-POV framing. No avatar selection in the prototype.

---

## 4. Stat System

Four stats, integer `0–10`. Stats are stored as **Dialogic variables** so timelines can read and modify them natively without going through GDScript.

| Stat | Domain | Affects |
|---|---|---|
| **Intelligence** | Deduction, fast thinking, clever responses | Unlocking "witty" / "insightful" options |
| **Patience** | Composure, emotional endurance | Surviving emotionally heavy moments, holding back inappropriate reactions |
| **Knowledge** | Book learning, references, technical recall | Identifying patterns, naming conditions, citing techniques |
| **Perception** | Reading people, noticing detail, reflexes | Photo Opportunity reaction window, noticing hidden lore |

**Caps:** soft cap `5`, hard cap `10`. **[TUNABLE]**
**Display:** small icon row in the morning menu and during sessions (optional hide via settings).

---

## 5. Day Structure

### 5.1 Morning Phase

UI: apartment background + activity selection menu. The menu is rendered by a Dialogic timeline (`morning_menu.dtl`) that uses a choice block looped until time slots are spent.

- **Time slots per morning:** 2 **[TUNABLE]**
- Each activity consumes 1 slot.
- Each activity is its own Dialogic timeline under `dialogic/timelines/morning/`.

**Initial activity list:**

| Activity | Primary effect | Secondary |
|---|---|---|
| Review Patient Files | +1 Knowledge (75% roll) | Previews today's patients, may unlock new dialogue options |
| Read a Book | +1 Intelligence (60% roll) | Random flavor text |
| Jogging | +1 Patience (70% roll) | None |
| Chat with Bea | +1 Perception (50% roll) | Light flirty banter, Bea relationship +1 |
| Analyze Last Session | +1 Insight (one-time per patient) | Unlocks specific options for that patient today |
| Go for a Walk | random +1 to any stat (40% roll) | Random encounter chance |

RNG outcomes are visible (success/fail flavor) so players feel agency. All values **[TUNABLE]**.

### 5.2 Day Phase

UI: office background. A simple "queue" autoload feeds the next patient. Between patients, the player sees a between-sessions menu:

- **Next patient** (auto if queue not empty)
- **Open Patient Files** (album of all collected info + photos)
- **End Day**

Each patient session is one Dialogic timeline (`dialogic/timelines/patients/{patient}/session_{N}.dtl`), selected based on `patients.{name}.progress`.

### 5.3 Patient Scheduling

With only 2 patients in the prototype and 3 sessions each, patients do **not** appear every day. Rule:

- After each session, set `patients.{name}.next_day = game.day + 2` (one-day cooldown).
- At day start, the queue = all patients where `next_day <= game.day` AND `progress < 3` AND `ending == ""`.
- If the queue is empty, it's a "free day" — Morning Phase only, then End of Day with a brief Bea scene to fill the office. This gives the player a stat-grinding lever and prevents dead air.

Prototype length is therefore **emergent**: the game ends when both Anna and Marisol have reached an ending state. Expected range: 5–8 days depending on play style.

### 5.4 End of Day

- Auto-save (slot 0 = autosave, plus 3 manual slots).
- Optional summary screen (skippable): stats gained today, photos collected today, trust deltas.
- Fade to "Day N+1".

---

## 6. Dialogue System (Dialogic-First Architecture)

**Design principle:** Dialogic timelines own as much game logic as possible. GDScript is only used for things Dialogic can't do natively (reflex QTE, complex save data, UI screens). This means a non-programmer can later extend the game by editing timelines.

### 6.1 Variable Schema

Defined in the Dialogic Variables panel (project-wide):

```
stats/
  intelligence : int = 1
  patience     : int = 1
  knowledge    : int = 1
  perception   : int = 1

game/
  day          : int = 1
  phase        : string = "morning"
  morning_slots_left : int = 2
  current_patient    : string = ""

flags/
  intro_done   : bool = false
  met_anna     : bool = false
  met_marisol  : bool = false
  # plus per-scene flags, prefixed with patient name

patients/
  anna/
    trust      : int = 0    # 0–100
    progress   : int = 0    # story stage (0 = not met, 1 = first session done, ...)
    last_day   : int = -1
    ending     : string = ""   # "" | "breakthrough" | "stuck" | "bad"
  marisol/
    [same shape]

photos/
  count : int = 0
  # individual photos tracked in PatientManager autoload, not Dialogic
```

Using nested groups (the `stats/intelligence` form) keeps the Dialogic Variables panel tidy.

### 6.2 Choice Gating (use Dialogic's native condition system)

Inside a choice block, each choice can have a `condition` expression. Two patterns:

**Hard gate (option only appears if condition met):**
```
- "You're clearly a control freak." [if {stats.intelligence} >= 3]
```

**Soft gate (option always visible but disabled or flagged):**
```
- "You sound frustrated." [Patience ≥ 1]
```
**Locked decision for prototype:** hidden-when-locked. Options whose `condition` fails are not rendered at all. Cleaner timelines, fewer edge cases in the layout. Greyed-out display can be revisited post-prototype if playtesting shows players can't tell stats matter.

### 6.3 Stat Check Custom Event — `StatCheck`

A custom Dialogic event so timelines can write:

```
[stat_check stat="perception" threshold=2 chance_per_point=10 base_chance=40 result="check_result"]
```

Semantics: rolls `base_chance + max(0, stat - threshold) * chance_per_point` against `randi() % 100`. Writes `true` or `false` into the named Dialogic variable. Optional `quality` output (`"crit" | "pass" | "fail"`) for tiered outcomes.

Implementation: a `DialogicEvent` subclass in `scripts/dialogic_events/stat_check_event.gd`. Registered in `addons/dialogic/Editor/Events/` per Dialogic 2.x docs.

### 6.4 Branching

Each patient's session is a single timeline with internal branching by `if` blocks on flags. Across sessions, the *which timeline to load* decision is driven by `patients.{name}.progress`:

```
PatientManager.get_next_session("anna")
  → "res://dialogic/timelines/patients/anna/session_2.dtl"
```

This keeps each session as a discrete, editable file rather than a single mega-timeline.

---

## 7. Photo Capture System

### 7.1 Design

A **Photo Opportunity** is a brief reflex moment embedded in a session timeline. A camera icon flashes on screen; the player has a window of time to click/press to "snap." Success adds the photo to the patient's file. Miss → dialogue continues without the photo. Each photo is one-shot per playthrough (a missed photo is recoverable only on a fresh New Game+).

### 7.2 Custom Event — `PhotoOpportunity`

```
[photo_opportunity
    id="anna_desk_demo"
    patient="anna"
    title="The Desk Demonstration"
    description="Anna re-enacting her boss's spreadsheet, with full theatrical commitment."
    window_ms=1500
    perception_bonus_ms=300
    portrait="res://assets/photos/anna_desk_demo.png"]
```

**Behavior:**
1. Timeline pauses.
2. UI overlay shows the camera icon (top-right).
3. Effective window = `window_ms + (stats.perception * perception_bonus_ms)`.
4. Player clicks icon / presses configurable key → success.
5. Timer expires → fail.
6. Writes `flags.last_photo_success : bool` to Dialogic vars so the timeline can branch reaction text ("*The camera shutter clicks.*" vs "*You hesitate. The moment passes.*").
7. On success, calls `PatientManager.add_photo(patient, photo_data)`.

### 7.3 Photo Asset Notes

Photos are static images stored in `assets/photos/{patient}/{photo_id}.png`. Placeholder art is fine for prototype. **[TBD: art direction]**

---

## 8. Patient Files & Photo Album UI

A standalone Godot scene `scenes/ui/patient_file_view.tscn` accessible from:
- Morning menu (via "Review Patient Files" activity)
- Between-patient menu in the Day Phase
- Main menu (post-prototype)

**Per-patient view:**
- Portrait + name + occupation + age
- Trust meter (0–100)
- Sessions completed (e.g., "Session 2/4")
- Notes section — short procedurally-built recap from flags (e.g., "Confessed obsession with control. Recommended structured journaling.")
- Photo grid — collected photos with title + description; click to enlarge

The Notes section pulls from a `PatientManager`-built list of "discovered facts," each unlocked by setting a Dialogic flag in a timeline.

---

## 9. Save System

**Strategy:** layered.

- **Dialogic state** — handled by Dialogic's built-in save (variables, current timeline position if mid-session). Use `Dialogic.Save.save("slot_N")`.
- **Custom state** — `PatientManager` photos collection, discovered-notes lists, and any non-Dialogic UI state — serialized by `SaveManager` to `user://save_slot_N.tres` (a `Resource` with `@export` fields, the Godot-idiomatic approach).
- **Triggers:**
  - Auto-save on End of Day → slot 0
  - Manual save / load via main menu (3 slots)
  - No mid-session saves in prototype (avoids re-rolling RNG)

**Schema for the custom save resource** (`scripts/save/game_save.gd`):
```gdscript
class_name GameSave extends Resource

@export var version : int = 1
@export var day : int = 1
@export var photos_by_patient : Dictionary = {}   # { "anna": [PhotoData, ...] }
@export var notes_by_patient : Dictionary = {}    # { "anna": ["fact_id_1", ...] }
@export var bea_relationship : int = 0
@export var dialogic_save_slot : String = "slot_0"
```

---

## 10. Example Characters

### 10.1 Anna Volkov — "The Accountant"

- **Age:** 29
- **Occupation:** Senior accountant at a mid-size firm
- **Surface complaint:** Work stress, can't sleep
- **Actual fixation:** Secretly craves being micromanaged. Her control-freak boss won't *let* her control anything, and she can't admit she finds being given precise, demanding orders deeply satisfying. Played as comedic D/s-curious without explicit content.
- **Personality:** Hyper-organized, color-coded calendar, eats lunch at exactly 12:00, panics if a spreadsheet has a merged cell. Furtive, fidgety, says "anyway" a lot to change subjects.
- **Arc (3 sessions):**
  1. **Session 1:** Stress complaint surface-level. Photo opportunity: the *desk demonstration* (re-enacts how she'd organize her boss's desk, with too much passion).
  2. **Session 2:** Slips and describes a "weird dream" that's clearly a fantasy. Photo opportunity: *the spreadsheet confession* (she shows you her dream-journal spreadsheet, color-coded).
  3. **Session 3:** Climax of arc — depending on trust score and prior key choices, arrives at **Breakthrough** (admits the desire, plans to find a healthier outlet), **Stuck** (deflects forever), or **Bad** (decides therapy is a scam, storms out). Photo: *the resignation letter* (she's drafted one to her boss).

### 10.2 Marisol Reyes — "The Novelist"

- **Age:** 34
- **Occupation:** Bestselling romance novelist (pen name: Maribelle de la Vega)
- **Surface complaint:** Writer's block
- **Actual fixation:** Cannot stop fantasizing in elaborate pirate-romance scenarios. Real life feels gray compared to her own books. Divorced, lives alone with three cats named after her ex-husbands' literary opposites.
- **Personality:** Dramatic, theatrical, gestures wildly, accidentally narrates her own life ("And then she sat upon the leather chair, her thoughts adrift..."). Smokes a cigarette holder that has never had a cigarette in it. Calls the player "Doctor" with an emphasis that varies wildly by mood.
- **Arc (3 sessions):**
  1. **Session 1:** Performs "writer's block" but keeps slipping into character. Photo: *the swoon* (re-enacts a scene from her latest book and faints onto your couch).
  2. **Session 2:** Reveals she's been writing the therapist into her latest manuscript. Photo: *the manuscript* (she lets you read a page — it's spicy).
  3. **Session 3:** Arc resolves to **Breakthrough** (channels the energy back into work, finishes the book), **Stuck** (keeps escaping into fantasy indefinitely), or **Bad** (decides you should be her muse and starts showing up at your apartment — played for laughs).

### 10.3 Beatrix "Bea" Chen — Receptionist

- **Age:** 27
- **Role:** Receptionist, brings coffee, makes sarcastic asides
- **Function in prototype:**
  - Announces each patient at the start of their session
  - Has 2–3 morning "chat" timelines with light flirty banter
  - Has a tracked relationship score that does nothing in the prototype but plants the hook for a future arc
- **Personality:** Dry, observant, calls the doctor "Doc" exclusively. Sees through everything. Probably the smartest person in the building.

---

## 11. Stat Checks, Trust, and Endings

### 11.1 Stat Check Math

```
Hard gate:        option visible iff stat >= threshold
Probabilistic:    success = roll(0,99) < base_chance + max(0, stat - threshold) * chance_per_point
Default base:     40
Default per pt:   10
Crit success:     roll <= base_chance - 30 (optional, for high-stat flavor wins)
```

Tune `base_chance` and `chance_per_point` per check — these are passed as event parameters, not hardcoded.

### 11.2 Trust

Each patient has a `trust` integer, range `0–100`, starting at `30`. Typical deltas:

| Event | Δ trust |
|---|---|
| Successful stat check during dialogue | +5 to +10 |
| Failed stat check during dialogue | −5 to −10 |
| Insightful key choice (story-flagged) | +10 to +15 |
| Tone-deaf choice | −10 to −15 |
| Successful photo capture | +3 |
| Missed photo (failed QTE) | 0 (no penalty — they didn't notice) |

Deltas are passed as event parameters per choice, not hardcoded. Trust persists across days and across sessions.

### 11.3 Ending Resolution

At the end of each patient's Session 3, the timeline branches into one of three endings based on final `trust` and a per-character "key flag" (a story choice that must be made correctly across earlier sessions):

| Condition | Ending |
|---|---|
| `trust >= 70` AND key flag set | **Breakthrough** |
| `trust < 30` | **Bad** |
| otherwise | **Stuck** |

The key flag is patient-specific and documented in their arc section above (e.g., for Anna it's whether the player named her actual fixation in Session 2 instead of accepting her surface deflection).

---

## 12. Technical Architecture

### 12.1 Project Folder Structure

```
mind-harvest/
├── project.godot
├── addons/
│   └── dialogic/                       # plugin
├── docs/
│   └── GDD.md                          # this file
├── scenes/
│   ├── main.tscn                       # root scene, hosts Dialogic layout
│   ├── ui/
│   │   ├── morning_menu.tscn           # rendered by timeline; this is the host scene
│   │   ├── patient_file_view.tscn
│   │   ├── photo_album.tscn
│   │   └── photo_qte_overlay.tscn      # camera icon + click-to-capture
│   └── transitions/
│       └── day_fade.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd               # day/phase/queue
│   │   ├── patient_manager.gd          # photos, notes, trust delta helpers
│   │   └── save_manager.gd
│   ├── dialogic_events/
│   │   ├── stat_check_event.gd
│   │   ├── photo_opportunity_event.gd
│   │   ├── add_note_event.gd
│   │   └── end_day_event.gd
│   ├── save/
│   │   └── game_save.gd
│   └── data/
│       └── photo_data.gd
├── dialogic/
│   ├── timelines/
│   │   ├── system/
│   │   │   ├── intro.dtl
│   │   │   ├── morning_menu.dtl
│   │   │   ├── day_intro.dtl
│   │   │   ├── between_patients.dtl
│   │   │   └── end_of_day.dtl
│   │   ├── morning/
│   │   │   ├── review_files.dtl
│   │   │   ├── read_book.dtl
│   │   │   ├── jogging.dtl
│   │   │   ├── chat_bea.dtl
│   │   │   ├── analyze_session.dtl
│   │   │   └── walk.dtl
│   │   └── patients/
│   │       ├── anna/
│   │       │   ├── session_1.dtl
│   │       │   ├── session_2.dtl
│   │       │   └── session_3.dtl
│   │       └── marisol/
│   │           ├── session_1.dtl
│   │           ├── session_2.dtl
│   │           └── session_3.dtl
│   ├── characters/
│   │   ├── player.dch
│   │   ├── bea.dch
│   │   ├── anna.dch
│   │   └── marisol.dch
│   └── variables/                      # auto-managed by Dialogic
└── assets/
    ├── portraits/
    │   ├── anna/
    │   ├── marisol/
    │   └── bea/
    ├── backgrounds/
    │   ├── apartment.png
    │   ├── office.png
    │   └── street.png
    ├── photos/
    │   ├── anna/
    │   └── marisol/
    └── ui/
        └── camera_icon.png
```

### 12.2 Autoloads

| Autoload | Responsibility |
|---|---|
| **GameState** | Current day, phase, patient queue, day-advance method. Owns "next patient" logic. |
| **PatientManager** | Per-patient data: trust, progress, photos collected, notes. Exposes `add_photo`, `add_note`, `add_trust`, `get_next_session_timeline`. Bridge between Dialogic and the UI scenes. |
| **SaveManager** | Loads/saves the `GameSave` resource + delegates Dialogic save. Slot management. |

GDScript on these is intentionally thin — most logic lives in timelines and is exposed via custom events.

### 12.3 Custom Dialogic Events (priority order)

| Event | Purpose | Phase |
|---|---|---|
| `StatCheck` | Rolls stat+RNG, writes result to a variable | M2 |
| `PhotoOpportunity` | QTE; on success adds photo and sets flag | M3 |
| `AddNote` | Records a "discovered fact" to a patient's file | M4 |
| `EndDay` | Triggers save, day++ , phase reset, returns to morning | M1 |
| `StartSession` | Used in `between_patients.dtl` to launch the right patient timeline based on progress | M1 |

All events have an editor block (icon + form fields) so timeline authors can drop them in without writing GDScript.

### 12.4 How Dialogic Hosts the Whole Game

The single `main.tscn` contains a `DialogicLayout` node. The game starts by running `system/intro.dtl`, which jumps into `system/morning_menu.dtl`. The morning menu timeline is essentially a loop:

```
- while {game.morning_slots_left} > 0:
    - choice "Review patient files" [if not done today]
        > jump to morning/review_files.dtl, decrement slots, return
    - choice "Read a book"
        > ...
- end while
- jump to system/day_intro.dtl
```

The Day Phase works the same way: `system/between_patients.dtl` is a loop that calls `StartSession` until the queue is empty or the player picks "End Day," which fires `EndDay`.

UI screens like the patient album are **not** Dialogic timelines — they're regular Godot scenes opened on top of the layout, then closed back to it.

---

## 13. Implementation Milestones

| # | Milestone | Acceptance |
|---|---|---|
| **M1** | Skeleton loop | Empty morning timeline → empty day timeline → end day → next day. No stats, no photos. Save/load skeleton works. |
| **M2** | Stats + activities | All 4 stats; 6 morning activities; `StatCheck` event implemented; choice gating works. |
| **M3** | Photo Opportunity | `PhotoOpportunity` event, QTE overlay scene, `PatientManager.add_photo`. |
| **M4** | Patient Files UI | Album scene, notes via `AddNote`, accessible from morning + between-patient menus. |
| **M5** | Full save/load | `GameSave` resource + Dialogic save, 3 slots + autosave, slot UI. |
| **M6** | Anna full 3-session arc | All three timelines, two photo opportunities, three endings reachable. |
| **M7** | Marisol full 3-session arc | Same as M6. |
| **M8** | Polish | Bea banter timelines, end-of-day summary, transitions, audio hooks. |

Each milestone is independently testable.

---

## 14. Tunable Parameters

Locked design decisions are baked into the doc above. These remain as knobs to tune during playtesting:

- Stat caps (current: soft 5, hard 10)
- Morning slots per day (current: 2; consider 3 on "weekend" days post-prototype)
- Stat-check `base_chance` and `chance_per_point` defaults (current: 40 / 10)
- Trust deltas per event (see §11.2 ranges)
- Trust thresholds for ending resolution (current: 70 / 30; see §11.3)
- Patient appointment cooldown (current: 2 days)
- Photo opportunity reaction window base (current: 1500ms) and Perception bonus (current: 300ms/point)

Items genuinely deferred (not part of prototype design):

- Money / economy / per-session fees
- Audio direction and music library
- Random encounters during the "Walk" activity (hook reserved, no content)
- Bea full romance arc (utility-only in prototype)
- Patient roster beyond Anna and Marisol

---

## 15. Out of Scope (Prototype)

To keep M1–M8 achievable:

- More than 2 patient arcs (Bea route excluded too — only banter)
- Multiple endings beyond the per-patient 3-state arc
- Localization
- Mobile/touch input (desktop only)
- Mid-session save/load
- Real art (placeholders fine)
- Random events on walks (hook reserved, not implemented)
- Money / shop / customization
- Achievements beyond photo collection

---

## 16. Design Principles (for contributors / Claude Code)

1. **Dialogic-first.** If it can live in a timeline, put it in a timeline. Custom events bridge to engine features; GDScript builds UI screens and serialization. Do not move dialogue branching logic into GDScript.
2. **One session = one timeline file.** Don't merge sessions or characters into mega-timelines.
3. **Variables are the canonical state during play.** Autoloads mirror as needed for UI but should read from Dialogic vars at session start, not maintain a separate truth.
4. **Custom events expose parameters.** Never hardcode tuning values inside an event implementation — pass them in.
5. **Fail loud.** If a timeline asks for a patient that doesn't exist, error visibly. Silent fallbacks make content bugs invisible.
6. **Placeholder-friendly.** Anything art- or audio-related should accept a missing-asset placeholder so the loop is testable without finished assets.
