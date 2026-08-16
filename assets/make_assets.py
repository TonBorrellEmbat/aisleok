#!/usr/bin/env python3
"""AisleOK App Store asset generator.

Keynote/Preview language: flat color, simple geometry, cheap to recolor.
Edit COLORS and COPY, then re-run:

    /tmp/imgvenv/bin/python /workspace/ibs-aisle-checker/assets/make_assets.py
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont


OUT_DIR = "/workspace/ibs-aisle-checker/assets"

# ---------------------------------------------------------------------------
# Brand (locked) — wellness, not clinic. No Fig lime.
# ---------------------------------------------------------------------------
AMBER = (227, 155, 26)        # #E39B1A  brand / small-portion
CREAM = (246, 239, 227)       # #F6EFE3
NEAR_BLACK = (28, 25, 22)     # #1C1916
SOFT_WHITE = (255, 251, 244)  # #FFFBF4
SAGE = (111, 143, 98)         # #6F8F62  eat
CLAY = (196, 90, 58)          # #C45A3A  skip
SAND = (196, 180, 154)        # #C4B49A  unknown
CAMERA = (42, 36, 28)         # #2A241C  warm camera dark
DOT_CREAM = (255, 246, 228)   # #FFF6E4  icon portion dot
WHITE = (255, 255, 255)
SAND_INK = (92, 80, 62)
WARM_SHELF = (58, 48, 36)

FONT_BOLD_PATH = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
FONT_REG_PATH = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
FONT_BOLD_FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REG_FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

# Growth-signed headlines. Wrap only at the newlines here.
COPY = {
    "wordmark": "AisleOK",
    "aso1": {
        "headline": "Scan it.\nEat, nibble, or skip.",
        "chips": ("Photo of label", "Search produce"),
    },
    "aso2": {
        "headline": "Lactose.\nA few spoons is\nusually fine.",
        "verdict": "Small portion",
        "product": "Chobani Plain Greek Yogurt",
        "chip": "Lactose",
        "body": "A few spoons. Not the cup.",
        "button": "Scan another",
    },
    "aso3": {
        "headline": "Onion powder.\nThis jar is a no.",
        "verdict": "Skip",
        "product": "Rao's Marinara",
        "chip": "Onion powder",
        "body": None,
        "button": "Scan another",
    },
    "aso4": {
        "headline": "No fake\ngreen light.",
        "verdict": "Unknown",
        "product": "Harvest Day Granola",
        "chip": None,
        "body": "We don't know this one.",
        "button": "Photo of label",
    },
    "aso5": {
        "headline": "No barcode,\nstill works.",
        "card1": "Photo of label",
        "search": "banana",
        "eat": "Eat",
        "caption": "Produce, bakery, leftover jars.",
    },
}

SHOT_W, SHOT_H = 1290, 2796
PHONE_W = 1040
BEZEL = 20
PHONE_RADIUS = 80


def font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    path = FONT_BOLD_PATH if bold else FONT_REG_PATH
    fb = FONT_BOLD_FB if bold else FONT_REG_FB
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.truetype(fb, size)


def text_wh(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont) -> tuple[int, int]:
    bbox = draw.textbbox((0, 0), text, font=fnt)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def fit_font(draw, text, max_w, max_size, min_size, bold=True):
    for size in range(max_size, min_size - 1, -1):
        fnt = font(size, bold)
        w, _ = text_wh(draw, text, fnt)
        if w <= max_w:
            return fnt, size
    return font(min_size, bold), min_size


def draw_lines(draw, cx, top, lines, fnt, fill, leading):
    y = top
    for line in lines:
        draw.text((cx, y), line, font=fnt, fill=fill, anchor="ma")
        y += leading
    return y


def draw_l_brackets(draw, box, arm, stroke, color, radius=0):
    """Four scanner L-brackets. box = outer edges; caller centers the box."""
    x0, y0, x1, y1 = [int(round(v)) for v in box]
    arm = int(round(arm))
    stroke = int(round(stroke))
    r = min(int(radius), max(0, stroke // 2))

    def arm_pair(hx0, hy0, hx1, hy1, vx0, vy0, vx1, vy1):
        if r:
            draw.rounded_rectangle((hx0, hy0, hx1, hy1), radius=r, fill=color)
            draw.rounded_rectangle((vx0, vy0, vx1, vy1), radius=r, fill=color)
        else:
            draw.rectangle((hx0, hy0, hx1, hy1), fill=color)
            draw.rectangle((vx0, vy0, vx1, vy1), fill=color)

    arm_pair(x0, y0, x0 + arm, y0 + stroke, x0, y0, x0 + stroke, y0 + arm)
    arm_pair(x1 - arm, y0, x1, y0 + stroke, x1 - stroke, y0, x1, y0 + arm)
    arm_pair(x0, y1 - stroke, x0 + arm, y1, x0, y1 - arm, x0 + stroke, y1)
    arm_pair(x1 - arm, y1 - stroke, x1, y1, x1 - stroke, y1 - arm, x1, y1)


def pill_size(draw, text, fnt, pad_x, pad_y, min_h=0):
    tw, th = text_wh(draw, text, fnt)
    return int(tw + pad_x * 2), max(int(th + pad_y * 2), min_h)


def draw_pill(draw, cx, cy, text, fnt, fill, text_fill, pad_x=28, pad_y=14, min_h=0):
    w, h = pill_size(draw, text, fnt, pad_x, pad_y, min_h)
    x0, y0 = int(cx - w / 2), int(cy - h / 2)
    draw.rounded_rectangle((x0, y0, x0 + w, y0 + h), radius=h / 2, fill=fill)
    draw.text((cx, cy), text, font=fnt, fill=text_fill, anchor="mm")
    return w, h


def rounded_mask(size, radius, scale=4):
    w, h = size
    sw, sh = w * scale, h * scale
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, sw - 1, sh - 1), radius=radius * scale, fill=255
    )
    return mask.resize((w, h), Image.Resampling.LANCZOS)


def squircle_mask(size: int, n: float = 5.0, scale: int = 4) -> Image.Image:
    s = size * scale
    mask = Image.new("L", (s, s), 0)
    draw = ImageDraw.Draw(mask)
    pts = []
    c = (s - 1) / 2.0
    a = c
    steps = 720
    exp = 2.0 / n
    for i in range(steps):
        t = 2.0 * math.pi * i / steps
        ct, st = math.cos(t), math.sin(t)
        x = a * math.copysign(abs(ct) ** exp, ct)
        y = a * math.copysign(abs(st) ** exp, st)
        pts.append((c + x, c + y))
    draw.polygon(pts, fill=255)
    return mask.resize((size, size), Image.Resampling.LANCZOS)


def draw_gear(draw, cx, cy, r, color, width=2):
    """Small cog — trigger list, not a sunburst."""
    teeth = 8
    inner = r * 0.70
    outer = r * 1.22
    hole = r * 0.32
    pts = []
    for i in range(teeth):
        a = i * (2 * math.pi / teeth) - math.pi / 2
        half = math.pi / teeth * 0.36
        gap = math.pi / teeth * 0.72
        pts.append((cx + inner * math.cos(a - gap), cy + inner * math.sin(a - gap)))
        pts.append((cx + inner * math.cos(a - half), cy + inner * math.sin(a - half)))
        pts.append((cx + outer * math.cos(a - half), cy + outer * math.sin(a - half)))
        pts.append((cx + outer * math.cos(a + half), cy + outer * math.sin(a + half)))
        pts.append((cx + inner * math.cos(a + half), cy + inner * math.sin(a + half)))
    draw.polygon(pts, fill=color)
    draw.ellipse(
        (cx - inner + 1, cy - inner + 1, cx + inner - 1, cy + inner - 1),
        fill=CAMERA if color == SOFT_WHITE else CREAM,
    )
    draw.ellipse((cx - hole, cy - hole, cx + hole, cy + hole), fill=color)


def draw_status_bar(draw, w, color, y=26):
    fnt = font(26, bold=True)
    pad = 44
    draw.text((pad, y), "9:41", font=fnt, fill=color, anchor="lt")

    bw, bh = 36, 17
    bx = w - pad - bw
    by = y + 6
    draw.rounded_rectangle((bx, by, bx + bw, by + bh), radius=4, outline=color, width=2)
    draw.rectangle((bx + 4, by + 4, bx + 21, by + bh - 4), fill=color)
    nub_x = bx + bw + 2
    draw.rounded_rectangle((nub_x, by + 5, nub_x + 3, by + bh - 5), radius=1, fill=color)

    wx, wy = bx - 30, by + bh // 2 + 3
    for rad in (11, 7, 3):
        draw.arc((wx - rad, wy - rad, wx + rad, wy + rad), 210, 330, fill=color, width=2)
    draw.ellipse((wx - 1.6, wy - 1.6, wx + 1.6, wy + 1.6), fill=color)

    bars_r = wx - 28
    base = by + bh
    for i, ht in enumerate((6, 9, 12, 16)):
        x = bars_r - 22 + i * 6
        draw.rounded_rectangle((x, base - ht, x + 4, base), radius=1, fill=color)


def draw_home_indicator(draw, w, h, color):
    bar_w, bar_h = 180, 6
    x0 = (w - bar_w) // 2
    y0 = h - 24
    draw.rounded_rectangle((x0, y0, x0 + bar_w, y0 + bar_h), radius=3, fill=color)


def draw_wordmark(draw, w, y, color, size=26):
    fnt = font(size, bold=True)
    draw.text((w // 2, y), COPY["wordmark"], font=fnt, fill=color, anchor="mt")


def frame_phone(canvas: Image.Image, ui: Image.Image, cx: int, top: int):
    bezel = BEZEL
    radius = PHONE_RADIUS
    sw, sh = ui.size
    pw, ph = sw + bezel * 2, sh + bezel * 2
    x = int(cx - pw / 2)
    y = int(top)

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (x + 8, y + 18, x + pw + 8, y + ph + 18),
        radius=radius,
        fill=(28, 25, 22, 64),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(20))
    canvas.paste(Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB"))

    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((x, y, x + pw, y + ph), radius=radius, fill=NEAR_BLACK)

    screen_r = max(10, radius - bezel)
    mask = rounded_mask((sw, sh), screen_r)
    canvas.paste(ui, (x + bezel, y + bezel), mask)
    return x, y, pw, ph


def compose_shot(bg, headline, headline_fill, ui) -> Image.Image:
    img = Image.new("RGB", (SHOT_W, SHOT_H), bg)
    draw = ImageDraw.Draw(img)
    cx = SHOT_W // 2

    lines = headline.split("\n")
    longest = max(lines, key=lambda s: text_wh(draw, s, font(80, True))[0])
    # 140px+ side margin so the long lactose line never kisses the edge
    fnt, size = fit_font(draw, longest, SHOT_W - 280, 82, 58, bold=True)
    leading = int(size * 1.36)

    sw, sh = ui.size
    ph = sh + BEZEL * 2
    bottom_pad = 64
    top_band = 76
    gap_after_type = 44
    headline_block = leading * len(lines)

    avail = SHOT_H - top_band - headline_block - gap_after_type - bottom_pad
    if ph > avail:
        scale = avail / ph
        ui = ui.resize(
            (max(640, int(ui.size[0] * scale)), max(1100, int(ui.size[1] * scale))),
            Image.Resampling.LANCZOS,
        )
        ph = ui.size[1] + BEZEL * 2

    phone_top = top_band + headline_block + gap_after_type
    leftover = SHOT_H - (phone_top + ph)
    if leftover > 120:
        phone_top += (leftover - 64) // 2

    draw_lines(draw, cx, top_band, lines, fnt, headline_fill, leading)
    frame_phone(img, ui, cx, phone_top)
    return img


def make_icon() -> Image.Image:
    """1024 RGB, no alpha. Amber field, white brackets, cream center dot."""
    s = 1024
    img = Image.new("RGB", (s, s), AMBER)
    draw = ImageDraw.Draw(img)
    c = s / 2.0
    half = 372
    box = (c - half, c - half, c + half, c + half)
    draw_l_brackets(draw, box, arm=228, stroke=52, color=WHITE, radius=0)
    d = 228
    draw.ellipse((c - d / 2, c - d / 2, c + d / 2, c + d / 2), fill=DOT_CREAM)
    return img


def make_icon_preview(icon: Image.Image) -> Image.Image:
    bg = Image.new("RGB", (1024, 1024), CREAM)
    mask = squircle_mask(1024, n=5.0)
    bg.paste(icon, (0, 0), mask)
    return bg


def screen_size():
    sw = PHONE_W - BEZEL * 2
    sh = int(round(sw * 2.00))
    return sw, sh


def _draw_aisle_hint(draw, box):
    x0, y0, x1, y1 = box
    cx = (x0 + x1) / 2
    cy = (y0 + y1) / 2
    jw, jh = 210, 268
    jx0, jy0 = cx - jw / 2, cy - jh / 2 + 8
    draw.rounded_rectangle((jx0, jy0, jx0 + jw, jy0 + jh), radius=22, fill=WARM_SHELF)
    draw.rounded_rectangle((jx0 + 28, jy0 - 22, jx0 + jw - 28, jy0 + 10), radius=8, fill=(72, 60, 46))
    draw.rounded_rectangle((jx0 + 22, jy0 + 48, jx0 + jw - 22, jy0 + jh - 36), radius=10, fill=CREAM)
    bx0 = jx0 + 38
    by0 = jy0 + 168
    rng = [3, 1, 2, 1, 3, 2, 1, 1, 3, 1, 2, 3, 1, 2, 1, 3, 2, 1]
    x = bx0
    for i, w in enumerate(rng):
        if i % 2 == 0:
            draw.rectangle((x, by0, x + w * 3, by0 + 44), fill=NEAR_BLACK)
        x += w * 3


def make_ui_scan() -> Image.Image:
    w, h = screen_size()
    img = Image.new("RGB", (w, h), CAMERA)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw, w, SOFT_WHITE)
    draw_wordmark(draw, w, 88, SOFT_WHITE, size=28)
    draw_gear(draw, w - 54, 106, 14, SOFT_WHITE, width=2)

    chip_fnt = font(24, bold=True)
    chip_h = 64
    chips_y = h - 130
    well_top = 168
    well_bot = chips_y - 80
    cy = (well_top + well_bot) / 2.0
    cx = w / 2.0
    side = 500
    box = (cx - side / 2, cy - side / 2, cx + side / 2, cy + side / 2)
    _draw_aisle_hint(draw, box)
    draw_l_brackets(draw, box, arm=112, stroke=16, color=WHITE, radius=0)

    labels = COPY["aso1"]["chips"]
    gap = 18
    sizes = [pill_size(draw, t, chip_fnt, 28, 16, min_h=chip_h) for t in labels]
    total = sizes[0][0] + sizes[1][0] + gap
    x = cx - total / 2
    for (label, (pw, ph)) in zip(labels, sizes):
        draw_pill(draw, x + pw / 2, chips_y, label, chip_fnt, SOFT_WHITE, NEAR_BLACK, 28, 16, chip_h)
        x += pw + gap

    draw_home_indicator(draw, w, h, (90, 80, 68))
    return img


def make_ui_verdict(verdict, verdict_color, product, chip, body, button, primary) -> Image.Image:
    w, h = screen_size()
    img = Image.new("RGB", (w, h), CREAM)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw, w, NEAR_BLACK)
    draw_wordmark(draw, w, 88, NEAR_BLACK, size=26)

    cx = w / 2.0
    y = 500

    v_fnt, v_size = fit_font(draw, verdict, w - 96, 76, 56, bold=True)
    draw.text((cx, y), verdict, font=v_fnt, fill=verdict_color, anchor="mm")
    y += int(v_size * 1.18)

    p_fnt, _ = fit_font(draw, product, w - 120, 30, 22, bold=False)
    draw.text((cx, y), product, font=p_fnt, fill=NEAR_BLACK, anchor="mm")
    y += 90

    if chip:
        chip_fnt = font(24, bold=True)
        draw_pill(draw, cx, y, chip, chip_fnt, verdict_color, SOFT_WHITE, 28, 16, min_h=56)
        y += 90

    if body:
        b_fnt = font(28, bold=False)
        draw.text((cx, y), body, font=b_fnt, fill=NEAR_BLACK, anchor="mm")

    btn_fnt = font(30, bold=True)
    btn_y = h - 230
    if primary:
        draw_pill(draw, cx, btn_y, button, btn_fnt, AMBER, SOFT_WHITE, 52, 24, min_h=84)
    else:
        draw_pill(draw, cx, btn_y, button, btn_fnt, SAND, NEAR_BLACK, 52, 24, min_h=84)

    draw_home_indicator(draw, w, h, (160, 148, 128))
    return img


def make_ui_fallback() -> Image.Image:
    w, h = screen_size()
    img = Image.new("RGB", (w, h), CREAM)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw, w, NEAR_BLACK)
    draw_wordmark(draw, w, 88, NEAR_BLACK, size=26)

    cx = w / 2.0
    card_w = w - 96
    card_h = 176
    card_x0 = (w - card_w) // 2
    radius = 28

    gap = 24
    block_h = card_h * 2 + gap + 72
    block_top = (h - block_h) // 2 + 10

    y0 = block_top
    draw.rounded_rectangle((card_x0, y0, card_x0 + card_w, y0 + card_h), radius=radius, fill=SOFT_WHITE)
    draw.rounded_rectangle((card_x0, y0, card_x0 + card_w, y0 + card_h), radius=radius, outline=SAND, width=2)
    thumb = 108
    tx = card_x0 + 32
    ty = y0 + (card_h - thumb) // 2
    draw.rounded_rectangle((tx, ty, tx + thumb, ty + thumb), radius=16, fill=CAMERA)
    inset = 18
    tbox = (tx + inset, ty + inset, tx + thumb - inset, ty + thumb - inset)
    draw_l_brackets(draw, tbox, arm=22, stroke=5, color=WHITE, radius=0)
    # cream center dot so the thumb matches the icon language
    tcx, tcy = (tbox[0] + tbox[2]) / 2, (tbox[1] + tbox[3]) / 2
    draw.ellipse((tcx - 8, tcy - 8, tcx + 8, tcy + 8), fill=DOT_CREAM)
    label_fnt = font(30, bold=True)
    draw.text((tx + thumb + 28, y0 + card_h // 2), COPY["aso5"]["card1"], font=label_fnt, fill=NEAR_BLACK, anchor="lm")

    y1 = y0 + card_h + gap
    draw.rounded_rectangle((card_x0, y1, card_x0 + card_w, y1 + card_h), radius=radius, fill=SOFT_WHITE)
    draw.rounded_rectangle((card_x0, y1, card_x0 + card_w, y1 + card_h), radius=radius, outline=SAND, width=2)

    sx = card_x0 + 58
    sy = y1 + card_h // 2
    draw.ellipse((sx - 15, sy - 17, sx + 13, sy + 11), outline=NEAR_BLACK, width=3)
    draw.line((sx + 9, sy + 7, sx + 20, sy + 20), fill=NEAR_BLACK, width=3)
    q_fnt = font(32, bold=False)
    draw.text((sx + 38, sy), COPY["aso5"]["search"], font=q_fnt, fill=NEAR_BLACK, anchor="lm")

    eat_fnt = font(24, bold=True)
    ew, _eh = pill_size(draw, COPY["aso5"]["eat"], eat_fnt, 26, 14, min_h=54)
    ex = card_x0 + card_w - 38 - ew / 2
    draw_pill(draw, ex, sy, COPY["aso5"]["eat"], eat_fnt, SAGE, SOFT_WHITE, 26, 14, 54)

    cap_fnt = font(24, bold=False)
    draw.text((cx, y1 + card_h + 52), COPY["aso5"]["caption"], font=cap_fnt, fill=SAND_INK, anchor="mt")

    draw_home_indicator(draw, w, h, (160, 148, 128))
    return img


def save_rgb(img: Image.Image, name: str) -> str:
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    rgb = img.convert("RGB")
    rgb.save(path, "PNG", optimize=True)
    print(f"{name}: {rgb.size[0]}x{rgb.size[1]} mode={rgb.mode} -> {path}")
    return path


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    icon = make_icon()
    save_rgb(icon, "icon-1024.png")
    save_rgb(make_icon_preview(icon), "icon-preview.png")

    c = COPY
    save_rgb(compose_shot(CREAM, c["aso1"]["headline"], NEAR_BLACK, make_ui_scan()), "aso-1-job.png")
    save_rgb(
        compose_shot(
            AMBER, c["aso2"]["headline"], SOFT_WHITE,
            make_ui_verdict(c["aso2"]["verdict"], AMBER, c["aso2"]["product"], c["aso2"]["chip"], c["aso2"]["body"], c["aso2"]["button"], True),
        ),
        "aso-2-dose.png",
    )
    save_rgb(
        compose_shot(
            CLAY, c["aso3"]["headline"], SOFT_WHITE,
            make_ui_verdict(c["aso3"]["verdict"], CLAY, c["aso3"]["product"], c["aso3"]["chip"], c["aso3"]["body"], c["aso3"]["button"], True),
        ),
        "aso-3-skip.png",
    )
    save_rgb(
        compose_shot(
            SAND, c["aso4"]["headline"], NEAR_BLACK,
            make_ui_verdict(c["aso4"]["verdict"], SAND_INK, c["aso4"]["product"], c["aso4"]["chip"], c["aso4"]["body"], c["aso4"]["button"], False),
        ),
        "aso-4-unknown.png",
    )
    save_rgb(compose_shot(CREAM, c["aso5"]["headline"], NEAR_BLACK, make_ui_fallback()), "aso-5-fallback.png")

    # keep the generator next to the PNGs
    here = os.path.abspath(__file__)
    dest = os.path.join(OUT_DIR, "make_assets.py")
    if os.path.normpath(here) != os.path.normpath(dest):
        with open(here, "r", encoding="utf-8") as f:
            body = f.read()
        with open(dest, "w", encoding="utf-8") as f:
            f.write(body)
        print(f"wrote generator -> {dest}")


if __name__ == "__main__":
    main()
