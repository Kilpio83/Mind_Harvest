"""
Generate eye_closed.png and eye_half.png blink overlays for Kamila's portrait set.

Strategy:
  1. Detect iris centres in neutral.png (green-pixel cluster).
  2. Diff neutral vs remorse in the eye band. Pixels that changed significantly
     are eyelid/lash/sclera pixels — exactly what we want.
  3. Build overlays from remorse.png pixels, using the diff value as the alpha
     channel. Only genuinely changed pixels are visible; surrounding skin (which
     shifts slightly due to head tilt) fades to transparent.

Run once from any directory:
    python tools/generate_kamila_blink_overlays.py
"""

import os
import numpy as np
from PIL import Image, ImageFilter

PORTRAITS_DIR = r"K:\Godot projects\mind-harvest\assets\portraits\kamila"
NEUTRAL_PATH  = os.path.join(PORTRAITS_DIR, "neutral.png")
REMORSE_PATH  = os.path.join(PORTRAITS_DIR, "remorse.png")

DIFF_THRESHOLD = 30   # per-channel-sum lower bound (0–765); raise to cut more skin noise
DIFF_SCALE     = 5.0  # multiply diff to reach full opacity faster at edges
EYE_X_HALF     = 55   # ±px from iris centre to search for diff
EYE_Y_PAD      = 12   # px of padding above/below the detected diff cluster


# ──────────────────────────────────────────────
# 1. Load
# ──────────────────────────────────────────────

neutral = Image.open(NEUTRAL_PATH).convert("RGBA")
remorse = Image.open(REMORSE_PATH).convert("RGBA")
W, H = neutral.size
assert remorse.size == neutral.size, "Images must be the same size"
print(f"Portrait: {W}×{H}")

n = np.array(neutral, dtype=np.float32)
r = np.array(remorse, dtype=np.float32)


# ──────────────────────────────────────────────
# 2. Iris detection → eye centres
# ──────────────────────────────────────────────

nr, ng, nb, na = n[:,:,0], n[:,:,1], n[:,:,2], n[:,:,3]
green = (ng > 90) & (ng > nr * 1.15) & (ng > nb * 1.08) & (na > 200)
ys_g, xs_g = np.where(green)
if len(ys_g) < 5:
    raise RuntimeError("No green iris pixels found. Check neutral.png.")

mid_x = W // 2
eye_y_center = int(ys_g.mean())
left_cx  = int(xs_g[xs_g < mid_x].mean())  if (xs_g < mid_x).any()  else mid_x // 2
right_cx = int(xs_g[xs_g >= mid_x].mean()) if (xs_g >= mid_x).any() else mid_x + mid_x // 2
print(f"Iris centres — left ({left_cx},{eye_y_center}), right ({right_cx},{eye_y_center})")

eye_y0 = max(0, eye_y_center - 50)
eye_y1 = min(H, eye_y_center + 60)


# ──────────────────────────────────────────────
# 3. Per-pixel diff → soft alpha mask
# ──────────────────────────────────────────────

# Sum of absolute differences across RGB channels (ignore alpha)
diff = np.abs(n[:,:,:3] - r[:,:,:3]).sum(axis=2)  # 0 – 765

# Convert diff to a 0–255 alpha: zero below threshold, ramps to 255 above
raw_alpha = np.clip((diff - DIFF_THRESHOLD) * DIFF_SCALE, 0, 255).astype(np.uint8)

# Mask out everything outside the eye search band
eye_mask = np.zeros((H, W), dtype=np.uint8)
eye_mask[eye_y0:eye_y1, :] = raw_alpha[eye_y0:eye_y1, :]

# Constrain to ±EYE_X_HALF around each iris centre
eye_mask_left  = eye_mask.copy()
eye_mask_right = eye_mask.copy()
lx0, lx1 = max(0, left_cx - EYE_X_HALF),  min(W, left_cx + EYE_X_HALF)
rx0, rx1 = max(0, right_cx - EYE_X_HALF), min(W, right_cx + EYE_X_HALF)
zero = np.zeros((H, W), dtype=np.uint8)
eye_mask_left[:,  :lx0] = 0;  eye_mask_left[:,  lx1:] = 0
eye_mask_right[:, :rx0] = 0;  eye_mask_right[:, rx1:] = 0

# Combine and soften edges with a small blur
combined_mask = np.maximum(eye_mask_left, eye_mask_right)
mask_img = Image.fromarray(combined_mask, mode='L')
mask_img = mask_img.filter(ImageFilter.GaussianBlur(radius=1.5))
combined_mask = np.array(mask_img)


# ──────────────────────────────────────────────
# 4. Build eye_closed: remorse pixels, diff-masked alpha
# ──────────────────────────────────────────────

remorse_rgb = r[:,:,:3].clip(0, 255).astype(np.uint8)
closed_arr = np.zeros((H, W, 4), dtype=np.uint8)
closed_arr[:,:,:3] = remorse_rgb
closed_arr[:,:,3]  = combined_mask
closed_img = Image.fromarray(closed_arr, mode='RGBA')


# ──────────────────────────────────────────────
# 5. Build eye_half: top portion of mask only
#    (eyelid descending, iris still partially visible below)
# ──────────────────────────────────────────────

def top_portion_mask(full_mask, cy, portion=0.55, feather=12):
    """
    Keep only the portion of the mask above (cy + portion * eye_height_below_cy).
    Below that line, feather to transparent.
    """
    h, w = full_mask.shape
    result = full_mask.copy().astype(np.float32)
    # Determine the cutoff Y: slightly below iris centre (eyelid stops mid-iris)
    cutoff_y = int(cy + (eye_y1 - cy) * portion)
    cutoff_y = min(h - 1, cutoff_y)
    # Feather from cutoff_y downward
    for row in range(max(0, cutoff_y - feather), min(h, cutoff_y + feather)):
        dist = row - (cutoff_y - feather)
        alpha_scale = max(0.0, 1.0 - dist / (2 * feather))
        result[row, :] *= alpha_scale
    result[cutoff_y + feather:, :] = 0
    return result.clip(0, 255).astype(np.uint8)

half_mask = top_portion_mask(combined_mask, eye_y_center)
half_mask_img = Image.fromarray(half_mask, mode='L').filter(ImageFilter.GaussianBlur(radius=1.2))
half_mask = np.array(half_mask_img)

half_arr = np.zeros((H, W, 4), dtype=np.uint8)
half_arr[:,:,:3] = remorse_rgb
half_arr[:,:,3]  = half_mask
half_img = Image.fromarray(half_arr, mode='RGBA')


# ──────────────────────────────────────────────
# 6. Save overlays + preview composites
# ──────────────────────────────────────────────

closed_path = os.path.join(PORTRAITS_DIR, "eye_closed.png")
half_path   = os.path.join(PORTRAITS_DIR, "eye_half.png")
closed_img.save(closed_path)
half_img.save(half_path)
print(f"Saved:\n  {closed_path}\n  {half_path}")

# Preview: composite over neutral, crop to eye region, 2× zoom
neutral_rgba = Image.fromarray(n.clip(0,255).astype(np.uint8), mode='RGBA')
for overlay, label in [(closed_img, "preview_closed.png"), (half_img, "preview_half.png")]:
    comp = neutral_rgba.copy()
    comp.paste(overlay, (0, 0), overlay)
    crop = comp.crop((130, 110, 390, 230)).resize((520, 240), Image.NEAREST)
    crop.save(os.path.join(PORTRAITS_DIR, label))
    print(f"Preview: {label}")

print("\nDone. Check preview_closed.png and preview_half.png.")
