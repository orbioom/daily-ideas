#!/usr/bin/env python3
"""Generate AppIcon PNGs + full Assets.xcassets for the 6 apps in this run.
Centralised so binary/asset correctness is guaranteed; agents write only code.
Structure written:  <slug>/ios/<App>/<App>/Assets.xcassets/{AppIcon,AccentColor,LaunchBackground}
                     <slug>/ios/<App>/Preview Content/Preview Assets.xcassets/Contents.json
"""
import json, math, os, random
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

def icon_wren():
    # calm self-care companion: soft periwinkle -> warm peach, a little bird + heart
    img = vgrad((0x8C, 0x9A, 0xE6), (0xF6, 0xC9, 0xA8))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 512, 540
    # soft halo
    d.ellipse((cx - 250, cy - 250, cx + 250, cy + 250), fill=(255, 255, 255, 40))
    # body
    d.ellipse((cx - 150, cy - 120, cx + 150, cy + 200), fill=(0x3E, 0x46, 0x6E, 255))
    # belly
    d.ellipse((cx - 95, cy - 30, cx + 110, cy + 190), fill=(0xF3, 0xE4, 0xD2, 255))
    # head
    d.ellipse((cx - 130, cy - 230, cx + 70, cy - 30), fill=(0x4A, 0x53, 0x80, 255))
    # wing
    d.ellipse((cx + 30, cy - 60, cx + 175, cy + 140), fill=(0x33, 0x3A, 0x5E, 255))
    # eye
    d.ellipse((cx - 80, cy - 175, cx - 42, cy - 137), fill=(255, 255, 255, 255))
    d.ellipse((cx - 72, cy - 167, cx - 50, cy - 145), fill=(0x16, 0x16, 0x22, 255))
    # beak
    d.polygon([(cx - 130, cy - 140), (cx - 180, cy - 120), (cx - 128, cy - 105)],
              fill=(0xF2, 0xA6, 0x4B, 255))
    # little heart above
    hx, hy = cx + 150, cy - 230
    d.ellipse((hx - 38, hy - 30, hx + 4, hy + 12), fill=(0xE8, 0x6A, 0x6A, 255))
    d.ellipse((hx - 4, hy - 30, hx + 38, hy + 12), fill=(0xE8, 0x6A, 0x6A, 255))
    d.polygon([(hx - 38, hy - 4), (hx + 38, hy - 4), (hx, hy + 46)], fill=(0xE8, 0x6A, 0x6A, 255))
    return img


def icon_quill():
    # handwriting notebook: deep indigo, a page with a written stroke + nib
    img = diag_grad((0x3A, 0x46, 0xC4), (0x1E, 0x24, 0x6E))
    d = ImageDraw.Draw(img, "RGBA")
    # page
    rr(d, (250, 210, 774, 814), 40, (0xF6, 0xF7, 0xFC, 255))
    # ruled lines
    for i, y in enumerate(range(330, 720, 78)):
        d.line((310, y, 714, y), fill=(0xC9, 0xD2, 0xEC, 255), width=10)
    # a handwritten flowing stroke
    pts = [(330, 470), (400, 410), (470, 520), (560, 410), (650, 520), (700, 450)]
    d.line(pts, fill=(0x35, 0x40, 0xC0, 255), width=22, joint="curve")
    # nib / pen tip
    d.polygon([(700, 450), (770, 360), (812, 402), (742, 472)], fill=(0x23, 0x29, 0x40, 255))
    d.polygon([(700, 450), (730, 432), (742, 472), (722, 478)], fill=(0xE8, 0xC5, 0x6B, 255))
    d.line((715, 461, 757, 419), fill=(0xF6, 0xF7, 0xFC, 120), width=4)
    return img


def icon_stow():
    # read-it-later: warm sand -> terracotta, a card of text with a bookmark ribbon
    img = vgrad((0xE8, 0xB1, 0x7A), (0xB5, 0x5C, 0x39))
    d = ImageDraw.Draw(img, "RGBA")
    # article card
    rr(d, (260, 250, 764, 800), 38, (0xFB, 0xF6, 0xEF, 255))
    # title block
    rr(d, (320, 320, 620, 366), 12, (0x2E, 0x2A, 0x28, 255))
    # text lines
    for y in range(430, 720, 56):
        w = 700 if (y // 56) % 3 else 560
        rr(d, (320, y, min(w, 700), y + 22), 8, (0xCC, 0xC2, 0xB6, 255))
    # bookmark ribbon
    bx = 640
    d.polygon([(bx, 250), (bx + 96, 250), (bx + 96, 470),
               (bx + 48, 416), (bx, 470)], fill=(0xC8, 0x52, 0x33, 255))
    d.polygon([(bx, 250), (bx + 96, 250), (bx + 96, 286), (bx, 286)], fill=(0xA8, 0x42, 0x28, 255))
    return img


def icon_hue():
    # anti-stress coloring: a segmented mandala wheel of tasteful colors on cream
    img = vgrad((0xF3, 0xE9, 0xF6), (0xE6, 0xD3, 0xEE))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy, R = 512, 512, 330
    seg = [(0xF0, 0x7A, 0x7A), (0xF4, 0xB1, 0x5E), (0xF6, 0xDE, 0x6B),
           (0x77, 0xC9, 0x88), (0x5C, 0xB6, 0xD6), (0x6E, 0x7F, 0xD6),
           (0xB07 // 10, 0x6C, 0xD0), (0xD0, 0x77, 0xB8)]
    n = len(seg)
    for i, col in enumerate(seg):
        a0 = 360 * i / n - 90
        a1 = 360 * (i + 1) / n - 90
        d.pieslice((cx - R, cy - R, cx + R, cy + R), a0, a1, fill=col + (255,))
    # inner white flower
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=(0xFB, 0xF8, 0xFC, 255))
    for k in range(8):
        a = 2 * math.pi * k / 8
        px = cx + math.cos(a) * 95
        py = cy + math.sin(a) * 95
        d.ellipse((px - 46, py - 46, px + 46, py + 46), fill=(0xF1, 0xE3, 0xF4, 255))
    d.ellipse((cx - 58, cy - 58, cx + 58, cy + 58), fill=(0xF0, 0x7A, 0xB0, 255))
    return img


def icon_lantern():
    # mahjong solitaire: deep red lacquer, a tile with a 'dot' suit + warm glow
    img = vgrad((0x9E, 0x29, 0x22), (0x55, 0x12, 0x10))
    d = ImageDraw.Draw(img, "RGBA")
    # glow
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((312, 312, 712, 712), fill=(0xFF, 0xD9, 0x82, 130))
    glow = glow.filter(ImageFilter.GaussianBlur(70))
    img = Image.alpha_composite(img.convert("RGBA"), glow)
    d = ImageDraw.Draw(img, "RGBA")
    # tile body (ivory) with depth
    rr(d, (300, 300, 724, 760), 46, (0xCC, 0xB2, 0x86, 255))   # side depth
    rr(d, (300, 290, 724, 720), 46, (0xF4, 0xEC, 0xDA, 255))   # face
    # central jade dot motif (circle suit)
    cx, cy = 512, 505
    d.ellipse((cx - 120, cy - 120, cx + 120, cy + 120), fill=(0x1F, 0x82, 0x5C, 255))
    d.ellipse((cx - 78, cy - 78, cx + 78, cy + 78), fill=(0xF4, 0xEC, 0xDA, 255))
    d.ellipse((cx - 40, cy - 40, cx + 40, cy + 40), fill=(0xC0, 0x33, 0x2B, 255))
    return img


def icon_facet():
    # personality / self-discovery: a faceted gem split into shaded planes on violet
    img = diag_grad((0x6E, 0x5A, 0xD8), (0x33, 0x2A, 0x82))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 512, 520
    top = (cx, cy - 250)
    l = (cx - 220, cy - 60)
    r = (cx + 220, cy - 60)
    bl = (cx - 120, cy - 60)
    br = (cx + 120, cy - 60)
    bot = (cx, cy + 280)
    # crown facets
    d.polygon([top, l, bl], fill=(0xC9, 0xD6, 0xFF, 255))
    d.polygon([top, bl, br], fill=(0xEC, 0xF2, 0xFF, 255))
    d.polygon([top, br, r], fill=(0xA8, 0xBA, 0xF6, 255))
    # pavilion facets
    d.polygon([l, bl, bot], fill=(0x8E, 0x9E, 0xEA, 255))
    d.polygon([bl, br, bot], fill=(0xB6, 0xC4, 0xFB, 255))
    d.polygon([br, r, bot], fill=(0x73, 0x84, 0xDD, 255))
    # sparkle
    d.line((cx + 150, cy - 200, cx + 150, cy - 120), fill=(255, 255, 255, 220), width=12)
    d.line((cx + 110, cy - 160, cx + 190, cy - 160), fill=(255, 255, 255, 220), width=12)
    return img


APPS = [
    ("01-wren", "Wren", icon_wren, (0xE0, 0x7A, 0x5B), (0xF6, 0xF1, 0xEC), (0x15, 0x12, 0x10)),
    ("02-quill", "Quill", icon_quill, (0x4C, 0x63, 0xD8), (0xF4, 0xF5, 0xFA), (0x10, 0x12, 0x1A)),
    ("03-stow", "Stow", icon_stow, (0xC8, 0x6B, 0x3C), (0xF7, 0xF3, 0xED), (0x16, 0x12, 0x0E)),
    ("04-hue", "Hue", icon_hue, (0xC0, 0x4C, 0xC8), (0xF8, 0xF3, 0xFA), (0x16, 0x10, 0x18)),
    ("05-lantern", "Lantern", icon_lantern, (0xB5, 0x34, 0x2C), (0xF6, 0xF1, 0xEC), (0x16, 0x0E, 0x0D)),
    ("06-facet", "Facet", icon_facet, (0x5A, 0x52, 0xC8), (0xF5, 0xF4, 0xFB), (0x12, 0x11, 0x1A)),
]

for slug, app, art, accent, lLight, lDark in APPS:
    base_contents(slug, app)
    save_icon(slug, app, art())
    colorset(slug, app, "AccentColor", accent)
    colorset(slug, app, "LaunchBackground", lLight, lDark)
    print(f"  ✓ {app}")

print("done")
