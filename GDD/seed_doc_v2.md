# The Couch — Seed Document v2.0
*Visual Novel / Dating Sim | Living Document — update as story evolves*

---

## The Kernel

A newly graduated therapist — carrying a dark, unresolved chapter of his life — opens a small private practice. He is supposed to help people understand themselves. His patients, each arriving with desires and compulsions far outside anything he studied, begin dismantling him instead. Session by session, something buried starts surfacing. He doesn't have a name for it yet. The patients do.

---

## Structural Engine

**Isekai framing.** The protagonist enters a world that operates on rules he doesn't know yet. The unknown world is adult human psychology — specifically, the sexuality of people who have already done the work he hasn't. Each patient is a region of that world with its own logic, language, and gravitational pull. The player discovers it alongside him.

**The therapist's chair is the portal.** He crossed into this world the moment he signed the lease. There is no going back to the person he was before — only forward into whoever he actually is.

---

## The Protagonist

**Who he is at the start:** Freshly graduated, technically qualified, quietly hollow. He presents as composed, professional, a little guarded. Underneath: unfinished.

**The accusation:** Something happened before the story begins — a complaint, a rumor, something unproven but career-ending enough to close one door and force him through this one. The accusation is not a simple lie. He didn't have time to process it. It will reveal in time.

**The secret:** Not "I'm innocent." The secret is "I don't fully know what I am." The patients will find out before he does.

**The arc:** Denial → exposure → reckoning → (player-determined) acceptance or consequence.

### Character Creation
The player determines:
- **Age range:** Early 20s / Late 20s / 30s
- **Gender:** Male / Female / Non-binary
- **Background:** Fresh graduate / Career changer / Studied abroad (returned)

Background options unlock specific story beats and minor arc variations. Gender affects pronouns, some patient dynamics, and certain dialogue branches. Age affects the texture of the accusation backstory, some interactions, and how patients initially read him.

---

## Bea (Beatrix)

**Role:** Receptionist, assistant, emotional anchor, slow-burn companion route.

**Who she is:** Clumsy. A little silly. Fiercely loyal. She heard the rumors before she took the job and showed up anyway — which says everything. She manages the paperwork, the scheduling, the small disasters of running an office. She is better at reading people than she appears to be.

**What she knows:** Rumors. Not details. She watches the protagonist carefully — more carefully than a normal assistant would — without ever making it obvious. He knows she might know something. Neither of them names it. Not yet.

**Her function in the story:**
- Reflects the game state back at the player through reactions, comments, small behavioral shifts
- Carries comedy between sessions that would otherwise be too heavy
- Provides warmth, continuity, a version of normal the protagonist keeps returning to
- Develops romantic tension on a track entirely separate from the patient routes
- Manages the appointment schedule — her awareness of who is coming becomes a storytelling tool

**Her arc:** Cautious → charmed → secret crush → genuinely invested → confronted with something she can't ignore → choice.

**Key distinction:** Bea is not a patient route. She is a companion route. Her relationship with the protagonist deepens differently — slower, realer, built from accumulated small moments rather than the high-voltage intensity of the sessions. She is the emotional consequence of everything that happens behind the closed door.

---

## The Patients

### Structure
- **4 patients** introduced near the beginning
- **Additional patients** arrive later as the story develops
- Each patient carries a specific desire, compulsion, or "quirk" that functions as a mirror to a different facet of the protagonist's buried self. Those quirks are also reflected in the character archetypes.

### Session Structure
The game is organised around **2-3 sessions per day**. Patients are not one-time encounters — they return across multiple sessions on their own schedules, each visit advancing their individual arc.

Each patient arc has three broad phases:
- **Early sessions** — surface presenting problem, first impressions, establishing dynamic
- **Middle sessions** — real territory emerges, mirror starts reflecting, protagonist affected
- **Late sessions** — full mirror held up, protagonist changed or not, arc resolves

Each individual session has a clear "what changes from start to end" — tracked in the outline as scene cards and flags.

### Scheduling & Declining
- Bea presents the day's proposed appointments
- The player can **decline some sessions** — a narratively justified refusal that affects the relationship with that patient over time
- Different patients return on different schedules: some weekly, some irregular, some who show up unannounced
- Bea's scheduling role makes her an indirect narrator of the protagonist's choices — she notices patterns without naming them

### Retention Mechanic
Patient routes are player-driven:
- If a patient's particular dynamic **resonates** — the player leans in, sessions deepen, new content unlocks, the patient returns more and pulls the protagonist further
- If it **doesn't resonate** — the player has a clean, narratively justified way to end the therapeutic relationship. No penalty. No shame.

Completing a patient's full arc leaves a **permanent mark on the protagonist** — knowledge, perspective, and unlocked dialogue options that carry forward. For example: fully engaging with a power dynamics route gives the protagonist a fluency in that territory that surfaces in future sessions and in interactions with Bea.

### Patient Design Principles
Each patient should:
- Be a fully realized person, not a kink delivery system
- Have her own reasons for being in therapy separate from her effect on the protagonist
- Push the protagonist in a specific psychological direction
- Carry enough humor, warmth, or strangeness to fit the tone
- Represent a distinct archetype

*(Individual patient profiles to be developed in Story Bible — Outline stage)*

---

## Bea vs. Patient Routes — Key Differences

| | Patient Routes | Bea Route |
|---|---|---|
| **Intensity** | High voltage, session-bound | Slow accumulation |
| **Knowledge** | Patient knows herself | Bea is figuring it out too |
| **Player role** | Witness / participant | Partner |
| **Tone** | Charged, surprising, sometimes uncomfortable | Warm, funny, emotionally real |
| **Endpoint** | Varies by resonance | Single route, deepest ending |

What the protagonist discovers with his patients directly influences his relationship with Bea — the true self he assembles across the patient routes is the self that eventually shows up for her.

---

## Script Markers (Dialogic 2)

When writing dialogue scripts, three standardized markers are embedded inline at the moment they trigger. These signal Dialogic 2 to fire corresponding game systems:

```
[NOTE: Brief patient file entry — adds to patient history record]
[MEMORY: Scene/character description — saves image to patient memory collection]
[DISCOVERY: What was uncovered — links to Hypothesis Board, tracks patient healing]
```

Exact marker syntax to be finalized at scripting stage. Outline stage will flag *where* in each session arc each marker fires, not just *what* it contains.

---

## Tone

**Fun on the surface. Real underneath. With teeth.**

- Playful enough that no one feels lectured
- Deep enough that something actually lands
- Adult players are demanding — the writing earns its heat through character and situation, not description alone
- The protagonist and player are on the same boat: discovering preferences, testing limits, dealing with consequences
- Surprise is a core experience — the player should regularly tilt their head and think "WTF just happened?"

---

## Intended Effect

Satisfaction. Surprise. Fun. The player walks away having discovered something about themselves they didn't expect to find in a game. The protagonist's journey and the player's journey are the same journey.

---

## Visual Content

Hybrid format: visual novel structure with dating sim relationship mechanics. NSFW visual content planned. Scene briefs and composition notes will be developed alongside script during the outline and draft stages.

---

## Open Questions (Living)

- [ ] Protagonist name options or fully player-named?
- [ ] Specific backgrounds for each character creation option — what exactly changes mechanically vs. cosmetically?
- [ ] First 4 patient identities, dynamics, quirk territories
- [ ] What Bea's "choice" moment actually is — what does she learn and when
- [ ] The specific nature of the protagonist's dark experience — revealed gradually through outline
- [ ] How the accusation backstory varies by protagonist background choice
- [ ] How declining sessions affects patient arc — temporary delay or permanent relationship damage?
- [ ] Episode structure vs. continuous narrative
- [ ] Engine (Ren'Py or Dialogic 2 / Godot confirmed for scripting)
- [ ] Hypothesis Board scope — patient healing only, or also protagonist self-discovery?

---

*Version 2.0 — Updated from player session additions*
*Changes from v1: recurring sessions, daily schedule structure, session declining, Dialogic 2 script markers, patient arc permanence mechanic, Bea scheduling role expanded*
*Next stage: Story Bible (character profiles) + Main Branch Outline*
