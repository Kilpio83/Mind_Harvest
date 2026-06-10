# Mind Harvest — GDD Delta (v0.2 → v1.0)
**Purpose:** modify the existing prototype (built per GDD v0.2) to incorporate the v1.0 expansion. This document specifies only what changes; for unchanged systems refer to v0.2.

**Engine:** Godot 4.6.2 · **Dialogue:** Dialogic 2.x · **Project path:** `K:\Godot projects\mind-harvest`

---

## Working assumptions for this delta

1. **No save migration.** All existing save files will be wiped before the next build. Each milestone sets new defaults and moves on. No backward-compat code anywhere.
2. **Dialogue panel stays centered.** The existing centered text box is correct; UI work assumes that. Notes panel will live on the right side of the screen.
3. **Existing story content is throwaway MVP.** Anna's and Marisol's current 3-session timelines exist only to validate systems. They will be rebuilt from scratch (in §M14/M15) once the framework is complete. No need to retrofit new systems into existing timelines beyond the bare minimum required to test each milestone.
4. **Already implemented in v0.2 prototype:** top HUD bar, toast container, visual styling, speaker name label above dialogue box, per-character name color tinting. No further work on these except where a new milestone explicitly touches them (e.g., M9 adds the Nerve stat to the HUD).

---

## Reading guide

For each system: **what existed**, **what changes**, **what's new**. Followed by a milestone-by-milestone implementation plan with concrete acceptance criteria.

---

## 1. Stat System — overhaul

**Existed:** four stats — Intelligence, Patience, Knowledge, Perception.

**Changes:**
- `Intelligence` → renamed `Intellect`
- `Patience` → renamed `Composure`
- Add new stat `Nerve` (range 0–10, starts at 1)

**Final set (5 stats):** Perception · Intellect · Knowledge · Composure · Nerve.

| Stat | Affects |
|---|---|
| Perception | Best notes in session, photo QTE window, body_language discoveries |
| Intellect | Contradiction discoveries, hypothesis-board capacity, clever dialogue |
| Knowledge | "I know what this is" options, future diagnostic frames |
| Composure | Surviving heavy beats, resisting trust loss under pressure |
| Nerve | Seduce/Exploit options, inappropriate-but-effective choices |

**Morning activity stat grants:**

| Activity | New stat |
|---|---|
| Review Patient Files | Knowledge (unchanged) |
| Read a Book | Intellect (renamed) |
| Jogging | Composure (renamed) |
| Chat with Bea | Perception (unchanged) |
| Analyze Last Session | Insight (unchanged) |
| Go for a Walk | Nerve (changed from random) |

---

## 2. Patient Progression — single trust → dual axis

**Existed:** single `patients.{name}.trust` (0–100, starts 30).

**Changes:** replaced by two axes.

**New variables per patient:**

```
patients.{name}.therapy_progress : int = 30   # 0–100
patients.{name}.personal_bond    : int = 0    # -50 to +50
```

**Old `trust` variable removed entirely.** Since existing MVP timelines will be replaced wholesale in M14/M15, no audit of existing trust deltas is needed — they'll vanish with the old content. For the framework to be testable in the meantime, the bare minimum is that the variables exist and the meters render.

**Ending resolution overhaul (for the future content):**

Old (single-axis):
```
trust >= 70 + key flag  → Breakthrough
trust < 30              → Bad
otherwise               → Stuck
```

New (quadrant-based):
```
therapy >= 70 AND bond >= +20  → LOVER family
therapy >= 70 AND bond <  +20  → GRADUATE family
therapy <= 30 AND bond >= +20  → DEVOTEE family
therapy <= 30 AND bond <= -20  → NEMESIS family
intermediate                    → arc continues (no auto-resolve)
```

Within each family, specific ending narrated based on committed intent history.

---

## 3. Arc Length — fixed → variable

**Existed:** every patient has exactly 3 sessions; ending forced at session 3.

**Changes:**
- `sessions_done` counter still exists but does **not** gate ending
- Arcs resolve when meter values + committed intent meet quadrant ending conditions
- No "Session 2 of 3" anywhere in UI

Existing MVP timelines will be retired in M14/M15, so the only immediate task is the framework: meter-check step at session end, no hard ending at any fixed session number.

**UI updates:**
- Patient file header: "N sessions completed" (no `/total`)
- Timeline column: "Next session — scheduled" with no number
- Bea's between-session comments surface arc proximity through narrative

---

## 4. UI — what's left

### 4.1 Dialogue panel — kept as-is

Centered panel, speaker name label, per-character color tinting — all already in place. No work needed.

### 4.2 Top HUD bar — already implemented

**Done.** Only change: M9 adds the Nerve stat to the row.

### 4.3 Toast container — already implemented

**Done.** Wiring from new custom events into the existing toast system happens as those events are built (M10, M11, M13).

### 4.4 Patient file view — rebuild

**Existed:** basic patient file with portrait, trust meter, photo grid, notes list.

**Changes:** three-column layout.

**Left column (260px):**
- 100×100 portrait + name + age/occupation in flexbox row
- Therapy Progress meter with endpoint labels: `0 · STRANGER` ↔ `BREAKTHROUGH · 100`
- Personal Bond meter with endpoint labels: `−50 · HOSTILE` ↔ `0` ↔ `DEVOTED · +50` (signed, grows outward from center)
- Qualitative caption under each meter (text varies by current value range)
- Committed Intent block (current intent + strength + lock status)
- Two buttons at bottom: Hypothesis · Photos · N

**Center column — case notes:**
- Per-session note paragraphs (existing, retained)
- New: Discoveries list at bottom with category-colored dots

**Right column — timeline (new):**
- Vertical timeline of events (sessions, mornings, intent commits, photos) with deltas
- Filled dots for past, hollow dashed dot for next scheduled
- No session-count denominator anywhere

### 4.5 Notes panel — new

**Existed:** none.

**New:** in-session notes panel on the right side of the screen, adjacent to the centered dialogue box.

- Hidden by default
- Activated by new `OfferNotes` Dialogic event with 2-4 options
- Same panel style as the dialogue box
- Player picks one or skips
- Pick → adds DiscoveryCard via PatientManager

Existing `AddNote` event (if present from v0.2's automatic notes) is retained for direct programmatic notes without UI.

---

## 5. Hypothesis System — entirely new

See §7 of full GDD for complete spec; below is the implementation overview.

### 5.1 New Resources

```gdscript
class_name DiscoveryCard extends Resource
@export var id              : String
@export var patient         : String
@export var session_added   : int
@export var short_label     : String
@export var description     : String
@export var tags            : Array[String]
@export var weight          : int = 1
@export var category        : String   # observation | confession | contradiction | vulnerability

class_name IntentDefinition extends Resource
@export var id              : String   # "heal" | "befriend" | "seduce" | "exploit"
@export var display_name    : String
@export var description     : String
@export var slot_count      : int = 3
@export var accent_color    : Color
```

### 5.2 New Autoload

```gdscript
# autoload/hypothesis_manager.gd
- get_discoveries(patient) -> Array[DiscoveryCard]
- get_board_state(patient) -> Dictionary
- set_slot(patient, intent_id, slot_index, discovery_id_or_null)
- get_intent_strength(patient, intent_id) -> float
- get_committed_intent(patient) -> String
- lock_for_session(patient)
- unlock_after_session(patient)
- is_intent_locked(patient, intent_id) -> bool
```

### 5.3 New Custom Dialogic Events

| Event | Purpose |
|---|---|
| `OfferNotes` | Surface 2-4 note options; on pick add discovery |
| `ApplyMeterDelta` | Adjust Therapy or Bond with toast notification |

`OfferNotes` event signature:
```
[offer_notes
    title="What do you note?"
    options="[
      { id: 'anna_pen_tell', label: 'Her hand on the pen', requires: '' },
      { id: 'anna_anyway_tic', label: 'The way she says \"anyway\"', requires: 'stats.perception >= 2' },
      { id: 'anna_boss_contradiction', label: 'Her boss story doesn't add up', requires: 'stats.intellect >= 3' }
    ]"
    allow_skip=true]
```

`ApplyMeterDelta` event signature:
```
[apply_meter_delta
    patient="anna"
    axis="therapy_progress"     # or "personal_bond"
    amount=5
    reason="Validating response"]
```

### 5.4 New UI Scene: Hypothesis Board

`res://scenes/ui/hypothesis_board.tscn`:
- Two-region layout
- Left: scrollable draggable discovery card stack
- Right: four intent regions (Heal, Befriend, Seduce, Exploit), each with header, description, 3 drop slots, strength meter
- Color-coded per intent
- Locked intents shown greyed with reason text
- Drag-and-drop via Godot's GUI drag/drop API
- Accessible from the Patient File via "Hypothesis" button

### 5.5 Intent Perk System

When a session begins, `HypothesisManager.lock_for_session(patient)` snapshots the current board state. The committed intent becomes readable from Dialogic via `patients.{name}.committed_intent`.

Timelines use this variable in choice conditions:

```
- "Let's try a structured exercise." [if {patients.anna.committed_intent} == "heal"]
- "Tell me about your weekend." [if {patients.anna.committed_intent} == "befriend"]
- "You look beautiful when you're angry." [if {patients.anna.committed_intent} == "seduce"]
- "I noticed you mentioned Brendan again." [if {patients.anna.committed_intent} == "exploit"]
```

`StatCheck` event extended with optional intent-bonus parameter: `+5%×strength` when the check's primary stat matches the committed intent's affinity (see §7.7 of full GDD for the full mapping).

### 5.6 Intent Lockout Rules

`HypothesisManager.is_intent_locked(patient, intent_id)` returns true when:
- intent = "heal" AND `personal_bond < -20`
- intent = "befriend" AND `therapy_progress < 15` AND `personal_bond < 0`
- intent = "seduce" AND `therapy_progress < 10`
- intent = "exploit" AND flag `{patient}_caught_exploiting` is set

Board UI grays out locked intents and shows reason.

---

## 6. Content Pipeline — new external

**Existed:** dialogue written directly in Dialogic editor.

**New:** external pipeline for batch-authoring scripts with TTS.

- `pipeline/convert.py` — converts SillyTavern JSONL chat exports to Dialogic `.dtl` + `lines.csv`
- `pipeline/tts_render.py` — reads `lines.csv` + `voices.yaml`, calls TTS API, saves OGG files
- `VoicePlayer` autoload — plays per-line OGG on Dialogic text signal, silent fallback

Set up in M16, used to author the rebuilt content in M14/M15.

---

## 7. Implementation Milestones

Each milestone is one Claude Code session. Apply in order. Existing MVP timelines are kept around just long enough to test each milestone, then replaced wholesale in M14/M15.

### M9 — Stat overhaul to 5 stats

**Scope:**
1. Rename Dialogic variables: `intelligence` → `intellect`, `patience` → `composure`
2. Add new Dialogic variable `nerve` (int, default 1)
3. Update existing MVP timelines' choice conditions to use new names (search-and-replace across `.dtl` files)
4. Update morning activity timelines:
   - `read_book.dtl`: grants Intellect
   - `jogging.dtl`: grants Composure
   - `go_for_walk.dtl`: grants Nerve (not random)
5. Update existing HUD to include Nerve in the 5-stat row
6. No save migration code — saves will be wiped

**Acceptance:**
- All 5 stats visible in HUD with correct color labels
- Morning activities grant the correct new stat
- No existing choice gate references `intelligence` or `patience`
- New game starts with all 5 stats at 1

### M10 — Dual-axis patient progression (schema only)

**Scope:**
1. Add Dialogic variables per patient: `therapy_progress` (int 0-100, default 30), `personal_bond` (int -50 to 50, default 0)
2. Remove `trust` variable entirely
3. New `ApplyMeterDelta` custom Dialogic event
4. For the existing MVP timelines: stub out any old `trust` writes with no-ops, OR replace each with a single `ApplyMeterDelta` to `therapy_progress` to keep the playthrough functional for testing. Quality not important — this content is being rebuilt.
5. Add quadrant-based ending check helper in `PatientManager.check_arc_resolution(patient)`. Old `session_3.dtl` may still force-end the arc for now; M14 fixes that.
6. Update patient file UI:
   - Two meter widgets, signed bar for Bond
   - Endpoint labels (STRANGER/BREAKTHROUGH; HOSTILE/0/DEVOTED)
   - Qualitative captions (small initial set, expanded in M18)

**Acceptance:**
- Both meters visible in patient file with correct labels and ranges
- `ApplyMeterDelta` event fires toasts correctly (using already-implemented toast system)
- Quadrant resolution helper returns correct family for test inputs
- New game starts both axes at correct defaults

### M11 — Discovery system foundation

**Scope:**
1. New resource class `scripts/data/discovery_card.gd`
2. Create 3-5 placeholder discovery cards for Anna only (just for testing — real cards authored in M14)
3. Extend `PatientManager` with `add_discovery(patient, discovery_id)`, `get_discoveries(patient)`
4. New `OfferNotes` custom Dialogic event
5. New scene `scenes/ui/notes_panel.tscn` — positioned on the right side, appears during `OfferNotes`, dismisses on selection or skip. Verify it doesn't overlap with the centered dialogue box at the target resolution.
6. Patient File UI: add Discoveries section under case notes (colored dots by category)
7. Add 1-2 `OfferNotes` test events to Anna's existing MVP session 1 timeline

**Acceptance:**
- Playing Anna's session 1 surfaces note options on the right side at the test beats
- Notes panel and dialogue panel are both fully visible simultaneously, no overlap
- Picking a note adds a discovery; skipping adds nothing
- Discoveries visible in patient file with correct category colors
- No board yet — discoveries are just collected

### M12 — Hypothesis Board UI

**Scope:**
1. New resource class `scripts/data/intent_definition.gd`
2. Create 4 IntentDefinition assets: heal.tres, befriend.tres, seduce.tres, exploit.tres
3. New autoload `scripts/autoload/hypothesis_manager.gd`
4. New scene `scenes/ui/hypothesis_board.tscn`:
   - Left: discovery stack with drag handles
   - Right: 4 intent panels, 3 drop slots each, strength meter per panel
   - Godot GUI drag-and-drop API
5. Board accessible from Patient File via "Hypothesis" button
6. Strength calculation per §5.5 (tag × weight × multiplier)
7. Commitment lifecycle: editable between sessions, locked at session start, unlocked after session end
8. Empty board = no commitment = neutral play
9. Persist board state in `GameSave.board_state_by_patient`

**Acceptance:**
- Discoveries draggable into intent slots
- Strength updates live as cards move
- Same discovery can be in multiple intents simultaneously
- Board state survives save/load
- Committing an intent before session start sets `patients.{name}.committed_intent`

### M13 — Intent perk system

**Scope:**
1. Extend `StatCheck` event to read `committed_intent` and apply bonus (+5%×strength) when committed intent matches the check's primary stat
2. Add 1-2 intent-gated choice options to Anna's MVP session 2 (proof-of-concept, not real content — just enough to verify the gating works)
3. Implement intent lockout rules in `HypothesisManager.is_intent_locked()`
4. Hypothesis board UI shows locked intents greyed with reason
5. Add `patients.{name}.exploit_points` variable
6. Add 1 Bea hint dialogue line that varies based on committed intent (proof of concept)

**Acceptance:**
- Committing Heal in Anna's session 2 shows Heal-only options not present in neutral play
- Composure checks show bonus when Heal is committed and check uses Composure
- After manually setting Anna's Bond below -20 via debug, Heal intent grays out with reason
- Bea makes intent-aware comment

### M14 — Variable arc length

**Scope:**
1. Remove hard ending forcing from existing MVP session_3 timelines
2. Add quadrant check at end of each session timeline (call `PatientManager.check_arc_resolution(patient)`)
3. If conditions met → branch to ending stub; if not → schedule next session normally
4. Create minimal placeholder `session_4.dtl` and `session_5.dtl` for both patients (1-line timelines, expanded properly in M15/M16)
5. Update Patient File UI:
   - Remove any "X/N" displays
   - Change to "N sessions completed"
   - Timeline column says "Next session — scheduled" with no number
6. Add 1-2 Bea between-session comments triggered by meter proximity to ending thresholds

**Acceptance:**
- Anna with high Therapy + high Bond can reach an ending stub at session 3 OR 4 OR 5 depending on values
- Anna with low engagement can reach NEMESIS stub before session 3 cap
- No "Session N of M" visible in any UI
- Existing MVP content still playable end-to-end through the new system

### M15 — Content: Anna full arc (from scratch)

The existing MVP Anna content is replaced wholesale here.

**Scope:**
1. Author 20-25 DiscoveryCard assets for Anna covering all 6 tags and all 4 categories
2. Author session_1 through session_5 timelines from scratch using the SillyTavern pipeline (M16 sets the pipeline up; recommended to do M16 before this milestone)
3. Each session includes 3-4 `OfferNotes` events at meaningful beats
4. Author per-quadrant ending sub-timelines (minimum 4: GRADUATE, LOVER, DEVOTEE, NEMESIS), with intent-flavored variants where meaningful
5. Add 4-6 photo opportunities across the full arc
6. Update Anna character data with available intents (all 4)
7. Delete or archive the MVP session files

**Acceptance:**
- Anna playable to all four quadrant endings via distinct intent paths
- All 4 intents reachable through hypothesis system commitments
- Note opportunities meaningful (not filler — each one offers a real choice with stat-gated alternatives)

### M16 — Content: Marisol full arc (from scratch)

Same scope as M15 applied to Marisol. Personality and intent flavoring distinct from Anna (theatrical, fantasy-driven).

**Acceptance:** Marisol playable to all four quadrant endings via distinct intent paths.

### M17 — TTS pipeline integration

Recommended **before** M15/M16 so the new content is authored with the pipeline in place. If sequenced after, expect to re-run content through the pipeline as a separate pass.

**Scope:**
1. Build `pipeline/convert.py` (SillyTavern JSONL → Dialogic `.dtl` + lines.csv)
2. Build `pipeline/tts_render.py` with chosen TTS provider (ElevenLabs recommended)
3. Create `pipeline/voices.yaml` mapping characters to voice IDs
4. New autoload `VoicePlayer` listening to Dialogic's text-shown signal
5. Add `line_id` metadata to text events (custom property pattern; emitted by convert.py)
6. Test round-trip: write a small chat in SillyTavern, convert, render TTS, play in-game
7. Cache rendered audio by content hash

**Acceptance:**
- A small test scene authored in SillyTavern plays in-game with correct voice files
- Editing one line in the source script and re-running re-renders only that line
- Missing voice files fall back to silent (no crash)

### M18 — Polish pass

**Scope:**
1. Author full set of qualitative meter captions for both patients (5-6 per axis per patient, triggered by value ranges)
2. Expand Bea's arc-state hint dialogue catalogue
3. Toast consolidation: if multiple effects fire in one frame, merge into a single toast with combined info
4. Photo album improvements: filtering by patient, hover descriptions, captured-date timestamps
5. End-of-day summary screen update: show meter deltas per patient, photos captured, intent commits, stats gained

**Acceptance:**
- Full playthrough of Anna OR Marisol with all systems active feels integrated
- Polish issues from M9-M17 closed out

---

## 8. Risk Notes for Claude Code

A few places where mistakes are most likely.

**M9 — Variable renames:** the Dialogic Variables panel doesn't auto-rename references in `.dtl` files. Search-and-replace across all timelines is the safest approach. Verify by grepping for the old names after.

**M11 — Notes panel placement:** the panel lives on the right side of the screen, separate from the centered dialogue box. Coordinate sizing so both can be visible during an `OfferNotes` beat without overlapping. The notes panel should be hidden when not in use, not just transparent.

**M12 — Drag-and-drop in Godot:** the GUI drag-and-drop API works on Control nodes via `_get_drag_data()`, `_can_drop_data()`, `_drop_data()`. Test on different screen sizes; drop zones can misalign at non-default resolutions.

**M13 — StatCheck event extension:** v0.2's `StatCheck` has a fixed parameter set. Adding intent-awareness: make intent-bonus opt-in via a new parameter that defaults to "no bonus." Don't break existing call sites.

**M14 — Quadrant transitions:** the "intermediate values" case means the arc continues. After enough sessions with no quadrant reached, the design needs a fallback (e.g., session 6+ adds a small bias toward whichever quadrant is closest, or just hard-resolve to the closest). Worth solving before M15 where real content gets written.

**M15/M16 — Don't pre-write content during framework milestones.** Resist the temptation to "just author a few real timelines" during M11-M14. Framework milestones use minimal placeholder content. Real authoring is its own focused work in M15/M16 after the pipeline (M17) is in place.

**M17 — Voice file naming:** the `line_id` scheme must match what `VoicePlayer` looks up. Define the scheme once in `pipeline/voices.yaml` config and reference from both sides.

---

## 9. Tunable Parameters (changes from v0.2)

- Ending thresholds: Therapy ≥70 / ≤30, Bond ≥+20 / ≤−20
- Notes per session cap (4)
- Intent slot count per intent (3)
- Intent strength bonus per point (5% per strength point)
- Heal lockout threshold (Bond < -20)
- Befriend lockout threshold (Therapy < 15 AND Bond < 0)
- Seduce lockout threshold (Therapy < 10)
- Photo capture Bond reward (+3)
- Photo capture Nerve reward (rare, +1)
