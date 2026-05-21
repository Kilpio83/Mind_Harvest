## Shared design tokens for all Mind Harvest UI components.
## Reference as  MHTokens.CONSTANT_NAME  from any script.
## Never inline a colour value — always go through this file.
class_name MHTokens

# ─── panel backgrounds ───────────────────────────────────────────────────────
const PANEL_BG_STRONG := Color(0.11,  0.094, 0.078, 0.88)  ## #1c1814 @ 88 %
const PANEL_BG_SOFT   := Color(0.11,  0.094, 0.078, 0.78)  ## #1c1814 @ 78 %

# ─── text ────────────────────────────────────────────────────────────────────
const TEXT_PRIMARY := Color(0.961, 0.925, 0.859, 1.0)   ## #f5ecdb — body / HUD
const TEXT_ACCENT  := Color(0.753, 0.659, 0.471, 1.0)   ## #c0a878 — speaker names

# ─── accent bars (toast left border & stat-check feedback) ───────────────────
const ACCENT_SUCCESS := Color(0.592, 0.769, 0.349, 1.0)  ## #97c459 — pass / green
const ACCENT_WARNING := Color(0.937, 0.690, 0.286, 1.0)  ## #efb049 — fail / amber
const ACCENT_PHOTO   := Color(0.831, 0.659, 0.290, 1.0)  ## #d4a84a — photo / gold
const ACCENT_STAT    := Color(0.353, 0.624, 0.831, 1.0)  ## #5a9fd4 — stat-gain / blue

# ─── HUD stat label colours ──────────────────────────────────────────────────
const INT_COLOR := Color(0.624, 0.722, 0.847, 1.0)  ## #9fb8d8
const PAT_COLOR := Color(0.753, 0.659, 0.471, 1.0)  ## #c0a878
const KNO_COLOR := Color(0.659, 0.784, 0.588, 1.0)  ## #a8c896
const PER_COLOR := Color(0.847, 0.659, 0.659, 1.0)  ## #d8a8a8

# ─── shape ───────────────────────────────────────────────────────────────────
const CORNER_RADIUS := 12  ## dialogue panel top-left only
const TOAST_RADIUS  := 6   ## all corners

# ─── toast timing (seconds) ──────────────────────────────────────────────────
const TOAST_SLIDE_SEC := 0.2
const TOAST_HOLD_SEC  := 2.5
const TOAST_FADE_SEC  := 0.3

# ─── layout constants ────────────────────────────────────────────────────────
const TOAST_WIDTH  := 240
const HUD_HEIGHT   := 40
