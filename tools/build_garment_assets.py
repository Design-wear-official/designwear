#!/usr/bin/env python3
"""Cut the generated garment photos out of their grey backdrop.

Reads the source renders (grey background, watermark, uneven framing), and
writes one transparent 1024x1024 PNG per style/view into
assets/images/garments/, with the garment scaled and centred identically so
the colour-zone polygons in assets/garments/styles.json line up.

Usage:  python3 tools/build_garment_assets.py [SOURCE_DIR]
Needs:  pip install opencv-python numpy pillow
"""
import sys
from pathlib import Path

import cv2
import numpy as np

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else Path.home() / "Music" / "t-shirts")
OUT = Path(__file__).resolve().parent.parent / "assets" / "images" / "garments"
CANVAS = 1024
FIT = 960  # garment fits inside FIT x FIT, centred

# output name -> (source file, optional list of (x0,y0,x1,y1) patches to
# inpaint away in the *source* image, e.g. to derive a plain tee from a
# pocket tee).
JOBS = {
    "crew_front": ("Gemini_Generated_Image_bn2vyybn2vyybn2v.png", [(1462, 452, 1690, 730)]),
    "crew_pocket_left_front": ("Gemini_Generated_Image_bn2vyybn2vyybn2v.png", []),
    "crew_pocket_right_front": ("Minimal White T-Shirt with Single Chest Pocket.png", []),
    "crew_pocket_both_front": ("Gemini_Generated_Image_1smxda1smxda1smx.png", []),
    "crew_back": ("Gemini_Generated_Image_orv44gorv44gorv4.png", []),
    "henley_front": ("Gemini_Generated_Image_dq6wyedq6wyedq6w.png", []),
    "polo_front": ("Gemini_Generated_Image_xulvb3xulvb3xulv.png", []),
    "polo_back": ("Gemini_Generated_Image_qgvq3lqgvq3lqgvq.png", []),
}

# Styles generated later, named <style>_<view>.png in the source folder.
for _name in (
    "vneck_front", "vneck_back", "longsleeve_front", "longsleeve_back",
    "raglan_front", "raglan_back", "ringer_front", "ringer_back",
    "tank_front", "tank_back", "hoodie_front", "hoodie_back",
    "cap_front", "cap_back", "tote_front", "tote_back",
):
    if (SRC / f"{_name}.png").exists():
        JOBS[_name] = (f"{_name}.png", [])

# Garments with openings the cut-out must keep (the gap between tote handles).
# Styles where backdrop shows between the arms and the torso.
WEDGES = {'longsleeve_front', 'longsleeve_back', 'raglan_front', 'hoodie_front', 'hoodie_back', 'tote_front', 'tote_back'}
KEEP_HOLES = {"tote_front", "tote_back"}


def drop_backdrop_slivers(work, fg, tol=6, band=48, anywhere_top=None):
    """GrabCut keeps wedges of backdrop between the arms and the torso.
    Fit the smooth backdrop brightness from clearly-outside pixels and drop any
    pixels of the mask that match it and are reachable from outside."""
    gray = cv2.cvtColor(work, cv2.COLOR_BGR2GRAY).astype(np.float32)
    h, w = gray.shape
    outside = cv2.dilate(fg, np.ones((31, 31), np.uint8)) == 0
    ys, xs = np.where(outside)
    sel = np.random.RandomState(1).choice(len(ys), min(20000, len(ys)), replace=False)
    ys, xs = ys[sel], xs[sel]
    def feats(y, x):
        y = y / h; x = x / w
        return np.stack([np.ones_like(x), x, y, x * x, y * y, x * y], 1)
    coef, *_ = np.linalg.lstsq(feats(ys.astype(np.float32), xs.astype(np.float32)), gray[ys, xs], rcond=None)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    model = (feats(yy.ravel(), xx.ravel()) @ coef).reshape(h, w)
    cand = (np.abs(gray - model) < tol).astype(np.uint8)
    cand = cv2.morphologyEx(cand, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    # candidate pixels inside the mask, connected to the outside of it
    near = (cv2.erode(fg, np.ones((band, band), np.uint8)) == 0).astype(np.uint8)  # edge band only
    if anywhere_top:  # enclosed gaps (tote handle loops): no outside connection
        ys0 = np.where(fg.any(1))[0]
        top = ys0.min() + int((ys0.max() - ys0.min()) * anywhere_top)
        cand[top:, :] = cand[top:, :] & near[top:, :]
        near = np.ones_like(near)
    reach = (cand & fg & near) | (1 - fg)
    n, lab = cv2.connectedComponents(reach.astype(np.uint8), connectivity=4)
    ids = np.unique(lab[fg == 0]); ids = ids[ids > 0]
    bgpix = np.isin(lab, ids) & (fg == 1)
    return (fg & ~bgpix.astype(np.uint8)).astype(np.uint8)


def cutout(img_bgr, slivers=False, fill_holes=True, top=None):
    h, w = img_bgr.shape[:2]
    # The renders have a soft grey backdrop; the shirt sits in the middle.
    mask = np.full((h, w), cv2.GC_PR_BGD, np.uint8)
    m = int(min(h, w) * 0.03)
    mask[:m, :] = mask[-m:, :] = cv2.GC_BGD
    mask[:, :m] = mask[:, -m:] = cv2.GC_BGD
    mask[int(h * .10):int(h * .95), int(w * .20):int(w * .80)] = cv2.GC_PR_FGD
    mask[int(h * .30):int(h * .80), int(w * .38):int(w * .62)] = cv2.GC_FGD
    bgd = np.zeros((1, 65)); fgd = np.zeros((1, 65))
    small = 1024 / max(h, w)
    work = cv2.resize(img_bgr, None, fx=small, fy=small, interpolation=cv2.INTER_AREA)
    wm = cv2.resize(mask, (work.shape[1], work.shape[0]), interpolation=cv2.INTER_NEAREST)
    cv2.grabCut(work, wm, None, bgd, fgd, 10, cv2.GC_INIT_WITH_MASK)
    fg = ((wm == cv2.GC_FGD) | (wm == cv2.GC_PR_FGD)).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(fg)
    k = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))  # drops the watermark
    fg = (lab == k).astype(np.uint8)
    if slivers:
        fg = drop_backdrop_slivers(work, fg, anywhere_top=top)
    inv = 1 - fg  # fill interior holes (e.g. neck opening shading)
    n, lab, st, _ = cv2.connectedComponentsWithStats(inv)
    for i in range(1, n if fill_holes else 1):
        x, y, ww, hh, _a = st[i]
        if x > 0 and y > 0 and x + ww < fg.shape[1] and y + hh < fg.shape[0]:
            fg[lab == i] = 1
    fg = cv2.morphologyEx(fg, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    alpha = cv2.GaussianBlur((fg * 255).astype(np.uint8), (0, 0), 1.0)
    return cv2.resize(alpha, (w, h), interpolation=cv2.INTER_LINEAR)


def build(name, src, patches):
    # Backdrop wedges between arms and torso: crew/polo backs, and every later style.
    slivers = (name.endswith('_back') and name.split('_')[0] in ('crew', 'polo')) or name in WEDGES
    img = cv2.imread(str(SRC / src), cv2.IMREAD_COLOR)
    if img is None:
        raise SystemExit(f"missing source image: {SRC / src}")
    h, w = img.shape[:2]
    sx = w / 2752.0  # patch coordinates are written for the 2752px renders
    for (x0, y0, x1, y1) in patches:
        # Replace the pocket with the mirrored, pocket-free chest on the other
        # side of the shirt, blended in so the fabric shading stays continuous.
        x0, y0, x1, y1 = (int(v * sx) for v in (x0, y0, x1, y1))
        cx = w // 2
        mx0, mx1 = 2 * cx - x1, 2 * cx - x0
        patch = cv2.flip(img[y0:y1, mx0:mx1], 1)
        pm = np.full(patch.shape[:2], 255, np.uint8)
        pm[:6, :] = pm[-6:, :] = pm[:, :6] = pm[:, -6:] = 0
        img = cv2.seamlessClone(patch, img, pm, ((x0 + x1) // 2, (y0 + y1) // 2), cv2.NORMAL_CLONE)
    alpha = cutout(img, slivers, name not in KEEP_HOLES, 0.4 if name in KEEP_HOLES else None)
    ys, xs = np.where(alpha > 20)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    crop = img[y0:y1, x0:x1]
    a = alpha[y0:y1, x0:x1]
    s = FIT / max(crop.shape[:2])
    crop = cv2.resize(crop, None, fx=s, fy=s, interpolation=cv2.INTER_AREA)
    a = cv2.resize(a, (crop.shape[1], crop.shape[0]), interpolation=cv2.INTER_AREA)
    rgba = np.dstack([crop, a])
    canvas = np.zeros((CANVAS, CANVAS, 4), np.uint8)
    oy = (CANVAS - rgba.shape[0]) // 2
    ox = (CANVAS - rgba.shape[1]) // 2
    canvas[oy:oy + rgba.shape[0], ox:ox + rgba.shape[1]] = rgba
    # Colour of fully transparent pixels is irrelevant; zero it to shrink PNGs.
    canvas[canvas[:, :, 3] == 0] = 0
    OUT.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(OUT / f"{name}.png"), canvas)
    print("wrote", OUT / f"{name}.png", "garment box", (ox, oy, rgba.shape[1], rgba.shape[0]))


if __name__ == "__main__":
    for n, (s, p) in JOBS.items():
        build(n, s, p)
