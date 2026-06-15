#!/usr/bin/env python3
"""Generate AppIcon PNGs + full Assets.xcassets for the 6 apps in this run.
Centralised so binary/asset correctness is guaranteed; agents write only code.
Structure written:  <slug>/ios/<App>/<App>/Assets.xcassets/{AppIcon,AccentColor,LaunchBackground}
                     <slug>/ios/<App>/Preview Content/Preview Assets.xcassets/Contents.json
"""
import json, math, os
from PIL import Image, ImageDraw, ImageFilter

RUN = os.path.dirname(os.path.abspath(__file__))
S = 1024


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def vgrad(top, bot):
    img = Image.new("RGB", (S, S), top)
    px = img.load()
    for y in range(S):
        c = lerp(top, bot, y / (S - 1))
        for x in range(S):
            px[x, y] = c
    return img


def diag_grad(c0, c1):
    img = Image.new("RGB", (S, S), c0)
    px = img.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2 * (S - 1))
            px[x, y] = lerp(c0, c1, t)
    return img


def radial(inner, outer):
    img = Image.new("RGB", (S, S), outer)
    px = img.load()
    cx = cy = S / 2
    maxd = math.hypot(cx, cy)
    for y in range(S):
        for x in range(S):
            t = min(1.0, math.hypot(x - cx, y - cy) / maxd)
            px[x, y] = lerp(inner, outer, t)
    return img


def rr(d, box, r, fill):
    d.rounded_rectangle(box, radius=r, fill=fill)


def save_icon(slug, app, img):
    folder = os.path.join(RUN, slug, "ios", app, app, "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(folder, exist_ok=True)
    img.convert("RGB").save(os.path.join(folder, "icon-1024.png"))
    with open(os.path.join(folder, "Contents.json"), "w") as f:
        json.dump({
            "images": [{"filename": "icon-1024.png", "idiom": "universal",
                        "platform": "ios", "size": "1024x1024"}],
            "info": {"author": "xcode", "version": 1}}, f, indent=2)


def hexc(v):
    return f"0x{v:02X}"


def colorset(slug, app, name, light, dark=None):
    folder = os.path.join(RUN, slug, "ios", app, app, "Assets.xcassets", name + ".colorset")
    os.makedirs(folder, exist_ok=True)
    colors = [{
        "color": {"color-space": "srgb", "components": {
            "red": hexc(light[0]), "green": hexc(light[1]),
            "blue": hexc(light[2]), "alpha": "1.000"}},
        "idiom": "universal"}]
    if dark:
        colors.append({
            "appearances": [{"appearance": "luminosity", "value": "dark"}],
            "color": {"color-space": "srgb", "components": {
                "red": hexc(dark[0]), "green": hexc(dark[1]),
                "blue": hexc(dark[2]), "alpha": "1.000"}},
            "idiom": "universal"})
    with open(os.path.join(folder, "Contents.json"), "w") as f:
        json.dump({"colors": colors, "info": {"author": "xcode", "version": 1}}, f, indent=2)


def base_contents(slug, app):
    root = os.path.join(RUN, slug, "ios", app, app, "Assets.xcassets")
    os.makedirs(root, exist_ok=True)
    with open(os.path.join(root, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
    prev = os.path.join(RUN, slug, "ios", app, "Preview Content", "Preview Assets.xcassets")
    os.makedirs(prev, exist_ok=True)
    with open(os.path.join(prev, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)


# ---------- per-app icon art ----------

def soft_shadow(img, box, r, blur=24, alpha=70):
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.rounded_rectangle(box, radius=r, fill=(0, 0, 0, alpha))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(img.convert("RGBA"), sh)


def icon_tetra():
    # 2048 merge game: warm arcade background, a stack of merging numbered tiles
    img = diag_grad((0x3A, 0x2C, 0x5A), (0x16, 0x12, 0x2E)).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    # glow behind
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((250, 250, 774, 774), fill=(0xF6, 0xB8, 0x5C, 110))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img, "RGBA")
    tiles = [
        ((300, 300, 540, 540), (0xF2, 0x9A, 0x4E)),   # back-left
        ((484, 300, 724, 540), (0xF4, 0xC2, 0x55)),   # back-right
        ((392, 470, 700, 778), (0xE8, 0x6A, 0x6A)),   # big front (the merge)
    ]
    for box, col in tiles:
        x0, y0, x1, y1 = box
        img = soft_shadow(img, (x0, y0 + 14, x1, y1 + 14), 40, blur=26, alpha=90)
        d = ImageDraw.Draw(img, "RGBA")
        rr(d, box, 40, col + (255,))
        rr(d, (x0, y0, x1, y0 + (y1 - y0) // 3), 40, tuple(min(255, c + 22) for c in col) + (120,))
    # the merged number "8" on the big tile (a clean rounded glyph drawn with ellipses)
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 546, 624
    for (oy, rad) in [(-66, 58), (66, 74)]:
        d.ellipse((cx - rad, cy + oy - rad, cx + rad, cy + oy + rad),
                  outline=(0xFF, 0xFB, 0xF2, 255), width=30)
    return img


def icon_tonus():
    # pelvic floor trainer: calm teal->green, a breathing ring with a held core
    img = vgrad((0x2E, 0x9E, 0x9A), (0x1C, 0x6E, 0x74)).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 512, 512
    # outer soft halo
    d.ellipse((cx - 330, cy - 330, cx + 330, cy + 330), fill=(255, 255, 255, 26))
    # progress ring (open at bottom, like a session ring)
    d.arc((cx - 250, cy - 250, cx + 250, cy + 250), 130, 410, fill=(0xEB, 0xF7, 0xF2, 255), width=58)
    # active sweep
    d.arc((cx - 250, cy - 250, cx + 250, cy + 250), 130, 300, fill=(0xCB, 0xF0, 0x86, 255), width=58)
    # core orb (the "hold")
    orb = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    od = ImageDraw.Draw(orb)
    od.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=(0xF4, 0xFD, 0xF7, 255))
    orb = orb.filter(ImageFilter.GaussianBlur(2))
    img = Image.alpha_composite(img, orb)
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse((cx - 92, cy - 92, cx + 92, cy + 92), fill=(0x35, 0xB0, 0x88, 255))
    d.ellipse((cx - 50, cy - 50, cx + 50, cy + 50), fill=(0xCB, 0xF0, 0x86, 255))
    return img


def icon_dactyl():
    # touch typing trainer: dark mechanical keyboard, a highlighted home key with caret
    img = vgrad((0x21, 0x2A, 0x3B), (0x12, 0x17, 0x22)).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    keycols = (0x2C, 0x37, 0x4D)
    accent = (0x4F, 0xC9, 0xB0)
    # three rows of keycaps
    def keycap(x, y, w, h, col):
        nonlocal img, d
        img = soft_shadow(img, (x, y + 10, x + w, y + h + 10), 24, blur=14, alpha=120)
        d = ImageDraw.Draw(img, "RGBA")
        rr(d, (x, y, x + w, y + h), 26, col + (255,))
        rr(d, (x + 10, y + 8, x + w - 10, y + h // 2), 18, tuple(min(255, c + 16) for c in col) + (90,))
    gap, kw, kh = 24, 150, 150
    startx = 512 - (3 * kw + 2 * gap) // 2
    rows = [302, 302 + kh + gap, 302 + 2 * (kh + gap)]
    for ri, ry in enumerate(rows):
        for ci in range(3):
            kx = startx + ci * (kw + gap)
            if ri == 1 and ci == 1:
                keycap(kx, ry, kw, kh, accent)   # home key highlighted
            else:
                keycap(kx, ry, kw, kh, keycols)
    # blinking caret + bump glyph on the home key
    d = ImageDraw.Draw(img, "RGBA")
    hx, hy = startx + (kw + gap) + kw // 2, rows[1] + kh // 2
    d.line((hx, hy - 42, hx, hy + 42), fill=(0x10, 0x16, 0x20, 255), width=16)
    d.rounded_rectangle((hx - 30, hy + 50, hx + 30, hy + 62), radius=6, fill=(0x10, 0x16, 0x20, 200))
    return img


def icon_felt():
    # poker bankroll tracker: green felt, a stacked chip with rising trend
    img = radial((0x1C, 0x7A, 0x4E), (0x0C, 0x3A, 0x28)).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 512, 540
    # chip shadow
    img = soft_shadow(img, (cx - 230, cy - 200, cx + 230, cy + 260), 230, blur=40, alpha=120)
    d = ImageDraw.Draw(img, "RGBA")
    # chip body
    d.ellipse((cx - 240, cy - 240, cx + 240, cy + 240), fill=(0xC2, 0x37, 0x37, 255))
    d.ellipse((cx - 240, cy - 240, cx + 240, cy + 240), outline=(0xF4, 0xEC, 0xDF, 255), width=10)
    # edge dashes
    for k in range(12):
        a = 2 * math.pi * k / 12
        ex, ey = cx + math.cos(a) * 210, cy + math.sin(a) * 210
        d.ellipse((ex - 26, ey - 26, ex + 26, ey + 26), fill=(0xF4, 0xEC, 0xDF, 255))
    d.ellipse((cx - 165, cy - 165, cx + 165, cy + 165), fill=(0xA8, 0x2A, 0x2A, 255))
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), outline=(0xF4, 0xEC, 0xDF, 220), width=8)
    # rising trend line on the chip face
    pts = [(cx - 110, cy + 70), (cx - 40, cy - 4), (cx + 20, cy + 34), (cx + 110, cy - 90)]
    d.line(pts, fill=(0xF6, 0xD8, 0x6B, 255), width=24, joint="curve")
    d.polygon([(cx + 110, cy - 90), (cx + 70, cy - 84), (cx + 104, cy - 48)], fill=(0xF6, 0xD8, 0x6B, 255))
    return img


def icon_equinox():
    # menopause companion: warm dawn gradient split by a horizon, a rising marigold sun
    top = (0x6E, 0x52, 0x8E)     # dusk violet (the "before")
    bot = (0xF4, 0xB5, 0x7A)     # warm dawn (the "after")
    img = vgrad(top, bot).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 512, 560
    # sun glow
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((cx - 240, cy - 240, cx + 240, cy + 240), fill=(0xFF, 0xD9, 0x8A, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img, "RGBA")
    # sun disc
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=(0xF6, 0xC1, 0x5A, 255))
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), outline=(0xFB, 0xE4, 0xA8, 255), width=10)
    # petals around (marigold) — soft warm ring
    for k in range(12):
        a = 2 * math.pi * k / 12
        px = cx + math.cos(a) * 205
        py = cy + math.sin(a) * 205
        d.ellipse((px - 40, py - 40, px + 40, py + 40), fill=(0xEE, 0xA9, 0x55, 200))
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=(0xF6, 0xC1, 0x5A, 255))
    # a calm horizon line
    d.line((150, 752, 874, 752), fill=(0xFB, 0xE3, 0xC8, 200), width=12)
    return img


def icon_iris():
    # eye care / screen break: restful blue-teal, a stylized eye with a calm iris
    img = radial((0x3E, 0x8F, 0xC9), (0x1A, 0x3E, 0x66)).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 512, 512
    # eye almond (white)
    d.ellipse((cx - 300, cy - 175, cx + 300, cy + 175), fill=(0xF2, 0xF7, 0xFB, 255))
    # clip-ish lids using arcs for shape definition
    d.arc((cx - 305, cy - 185, cx + 305, cy + 165), 180, 360, fill=(0x12, 0x33, 0x55, 90), width=14)
    # iris
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=(0x2C, 0x7F, 0xA8, 255))
    # iris striations (radial)
    for k in range(24):
        a = 2 * math.pi * k / 24
        d.line((cx + math.cos(a) * 60, cy + math.sin(a) * 60,
                cx + math.cos(a) * 144, cy + math.sin(a) * 144),
               fill=(0x6F, 0xC8, 0xE6, 160), width=6)
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), outline=(0x1C, 0x55, 0x74, 255), width=8)
    # pupil
    d.ellipse((cx - 64, cy - 64, cx + 64, cy + 64), fill=(0x10, 0x22, 0x33, 255))
    # catch-light
    d.ellipse((cx + 28, cy - 60, cx + 70, cy - 18), fill=(0xFF, 0xFF, 0xFF, 230))
    return img


APPS = [
    ("01-tetra",   "Tetra",   icon_tetra,   (0xF2, 0x9A, 0x4E), (0xF6, 0xF2, 0xEC), (0x16, 0x12, 0x22)),
    ("02-tonus",   "Tonus",   icon_tonus,   (0x2C, 0x9E, 0x8A), (0xEF, 0xF6, 0xF3), (0x0C, 0x18, 0x18)),
    ("03-dactyl",  "Dactyl",  icon_dactyl,  (0x4F, 0xC9, 0xB0), (0xF2, 0xF5, 0xF8), (0x10, 0x15, 0x1F)),
    ("04-felt",    "Felt",    icon_felt,    (0x2E, 0x9E, 0x6A), (0xF1, 0xF5, 0xF2), (0x0A, 0x16, 0x10)),
    ("05-equinox", "Equinox", icon_equinox, (0xD8, 0x8A, 0x55), (0xFA, 0xF4, 0xEE), (0x18, 0x12, 0x1C)),
    ("06-iris",    "Iris",    icon_iris,    (0x2F, 0x86, 0xB8), (0xEF, 0xF4, 0xF9), (0x0C, 0x16, 0x20)),
]

for slug, app, art, accent, lLight, lDark in APPS:
    base_contents(slug, app)
    save_icon(slug, app, art())
    colorset(slug, app, "AccentColor", accent)
    colorset(slug, app, "LaunchBackground", lLight, lDark)
    print(f"  ✓ {app}")

print("done")
