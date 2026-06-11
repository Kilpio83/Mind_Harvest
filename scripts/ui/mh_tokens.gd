## Shared design tokens for all Mind Harvest UI components — Evenfall palette.
## Reference as  MHTokens.CONSTANT_NAME  from any script.
## Never inline a colour value — always go through this file.
class_name MHTokens

# ─── Evenfall palette ─────────────────────────────────────────────────────────
## Background:  cool blue-grey slate  #222B2E / #2C3539
## Surface:     dark charcoal glass   #37352F / #2A2F32
## Text:        warm cream            #F3EEE3 / #EDE7DB
## Accent:      honey-gold            #E2A33E / #F0C886

# ─── panel backgrounds ───────────────────────────────────────────────────────
const PANEL_BG_STRONG := Color(0.140, 0.168, 0.180, 0.92)  ## #243040 @ 92 % — dialogue/modal panels
const PANEL_BG_SOFT   := Color(0.160, 0.195, 0.212, 0.78)  ## #29323B @ 78 % — HUD / soft surfaces

# ─── text ────────────────────────────────────────────────────────────────────
const TEXT_PRIMARY := Color(0.953, 0.933, 0.890, 1.0)   ## #F3EEE3 — body / HUD
const TEXT_MUTED   := Color(0.580, 0.631, 0.651, 1.0)   ## #94A1A6 — secondary / muted
const TEXT_ACCENT  := Color(0.886, 0.639, 0.243, 1.0)   ## #E2A33E — gold / speaker names

# ─── accent / feedback ────────────────────────────────────────────────────────
const ACCENT_GOLD    := Color(0.886, 0.639, 0.243, 1.0)  ## #E2A33E — primary gold accent
const ACCENT_SUCCESS := Color(0.486, 0.718, 0.376, 1.0)  ## #7CB760 — pass / green (desaturated for slate bg)
const ACCENT_WARNING := Color(0.886, 0.639, 0.243, 1.0)  ## #E2A33E — fail / gold-amber
const ACCENT_PHOTO   := Color(0.941, 0.745, 0.286, 1.0)  ## #F0BE49 — photo / bright gold
const ACCENT_STAT    := Color(0.404, 0.627, 0.788, 1.0)  ## #679FC9 — stat-gain / slate-blue

# ─── discovery category colours (tuned for slate background) ─────────────────
const DISC_OBSERVATION   := Color(0.678, 0.573, 0.761, 1.0)  ## muted violet
const DISC_CONFESSION    := Color(0.886, 0.639, 0.243, 1.0)  ## gold
const DISC_CONTRADICTION := Color(0.404, 0.627, 0.788, 1.0)  ## slate-blue
const DISC_VULNERABILITY := Color(0.486, 0.718, 0.376, 1.0)  ## muted green

# ─── HUD stat label colours — Perception · Intellect · Knowledge · Composure · Nerve
const PER_COLOR  := Color(0.780, 0.561, 0.561, 1.0)  ## dusty rose
const INT_COLOR  := Color(0.404, 0.627, 0.788, 1.0)  ## slate-blue
const KNO_COLOR  := Color(0.486, 0.718, 0.376, 1.0)  ## muted green
const COMP_COLOR := Color(0.886, 0.639, 0.243, 1.0)  ## gold
const NRV_COLOR  := Color(0.780, 0.435, 0.341, 1.0)  ## clay-rust

# ─── shape ───────────────────────────────────────────────────────────────────
const CORNER_RADIUS := 10  ## panel corners
const TOAST_RADIUS  := 8   ## toast corners

# ─── toast timing (seconds) ──────────────────────────────────────────────────
const TOAST_SLIDE_SEC := 0.2
const TOAST_HOLD_SEC  := 2.5
const TOAST_FADE_SEC  := 0.3

# ─── font sizes (at 1920×1080 base resolution) ───────────────────────────────
const FONT_BODY  := 16   ## notes, discovery labels, primary content
const FONT_SMALL := 14   ## descriptions, secondary text
const FONT_LABEL := 13   ## compact labels — meter headers, HUD values
const FONT_MICRO := 12   ## smallest used element

# ─── layout constants ────────────────────────────────────────────────────────
const TOAST_WIDTH  := 320
const HUD_HEIGHT   := 48
