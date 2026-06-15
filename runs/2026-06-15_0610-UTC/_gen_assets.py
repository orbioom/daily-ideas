#!/usr/bin/env python3
"""Generate AppIcon PNGs + full Assets.xcassets for the 6 apps in this run.
Centralised so binary/asset correctness is guaranteed; agents write only code."""
import json, math, os
from PIL import Image, ImageDraw

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

def icon_stash():
    # warm teal -> deep teal, stacked loyalty cards w/ barcode
    img = diag_grad((0x1F, 0xB6, 0xAE), (0x0B, 0x6E, 0x6E))
    d = ImageDraw.Draw(img, "RGBA")
    # back card
    rr(d, (250, 300, 800, 560), 46, (255, 255, 255, 60))
    # mid card
    rr(d, (210, 380, 814, 660), 50, (255, 255, 255, 110))
    # front card
    rr(d, (180, 470, 844, 770), 54, (255, 255, 255, 245))
    # barcode on front card
    x = 250
    import random
    random.seed(7)
    while x < 760:
        w = random.choice([10, 14, 22, 8])
        d.rectangle((x, 560, x + w, 690), fill=(0x0B, 0x4F, 0x52, 255))
        x += w + random.choice([10, 16, 8])
    # accent chip
    rr(d, (230, 510, 320, 555), 12, (0xFF, 0xC5, 0x4D, 255))
    return img


def icon_reveille():
    # dawn: indigo top -> coral bottom, sun arc + bell-less clock ring
    img = vgrad((0x2A, 0x2A, 0x66), (0xFF, 0x8A, 0x5B))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 512, 600
    # sun
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=(0xFF, 0xE2, 0x9A, 255))
    d.ellipse((cx - 110, cy - 110, cx + 110, cy + 110), fill=(0xFF, 0xC1, 0x53, 255))
    # rays
    for k in range(12):
        a = math.pi * (k / 11.0)
        x0 = cx + math.cos(math.pi + a) * 180
        y0 = cy + math.sin(math.pi + a) * 180
        x1 = cx + math.cos(math.pi + a) * 250
        y1 = cy + math.sin(math.pi + a) * 250
        d.line((x0, y0, x1, y1), fill=(0xFF, 0xE2, 0x9A, 230), width=18)
    # horizon line
    d.rectangle((150, cy + 150, 874, cy + 168), fill=(255, 255, 255, 220))
    return img


def icon_inkling():
    # violet field, correlation scatter with trend line
    img = diag_grad((0x8B, 0x5C, 0xFF), (0x4A, 0x2E, 0xB0))
    d = ImageDraw.Draw(img, "RGBA")
    pts = [(300, 720), (380, 650), (430, 690), (500, 560), (560, 600),
           (620, 470), (690, 500), (740, 380), (300, 700)]
    import random
    random.seed(3)
    for i in range(22):
        x = random.randint(280, 760)
        # roughly along a downward-right trend
        y = int(760 - (x - 280) * 0.72 + random.randint(-55, 55))
        r = random.choice([14, 18, 22])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, 170))
    # trend line
    d.line((280, 760, 770, 410), fill=(0xFF, 0xD5, 0x66, 255), width=20)
    d.ellipse((255, 735, 305, 785), fill=(0xFF, 0xD5, 0x66, 255))
    d.ellipse((745, 385, 795, 435), fill=(0xFF, 0xD5, 0x66, 255))
    return img


def icon_sprig():
    # soft sage -> green, a sprout (two leaves + stem) and growth dot
    img = vgrad((0xBC, 0xE3, 0xC5), (0x3F, 0x9D, 0x6B))
    d = ImageDraw.Draw(img, "RGBA")
    # pot/ground arc
    d.ellipse((322, 720, 702, 900), fill=(255, 255, 255, 60))
    # stem
    d.line((512, 760, 512, 470), fill=(0x1F, 0x6E, 0x46, 255), width=26)
    # left leaf
    d.ellipse((330, 430, 520, 600), fill=(0x6F, 0xC9, 0x8C, 255))
    d.ellipse((360, 470, 510, 580), fill=(0x4F, 0xAE, 0x72, 255))
    # right leaf
    d.ellipse((512, 360, 712, 540), fill=(0x7F, 0xD6, 0x9A, 255))
    d.ellipse((540, 395, 690, 510), fill=(0x57, 0xB8, 0x7C, 255))
    # bud
    d.ellipse((484, 410, 540, 466), fill=(0xFF, 0xE0, 0x8A, 255))
    return img


def icon_yield():
    # deep green -> emerald, coin stack + up arrow
    img = diag_grad((0x16, 0x7A, 0x4A), (0x0A, 0x46, 0x2E))
    d = ImageDraw.Draw(img, "RGBA")
    # coin stack
    for i, y in enumerate(range(700, 540, -54)):
        d.ellipse((330, y, 600, y + 110), fill=(0xFF, 0xCE, 0x55, 255))
        d.ellipse((330, y - 10, 600, y + 100), fill=(0xFF, 0xDD, 0x7D, 255))
    # up arrow
    d.line((560, 640, 720, 420), fill=(255, 255, 255, 255), width=34)
    d.polygon([(720, 420), (672, 444), (732, 480)], fill=(255, 255, 255, 255))
    d.polygon([(720, 420), (720, 470), (672, 444)], fill=(255, 255, 255, 255))
    # percent dots
    d.ellipse((648, 470, 690, 512), outline=(255, 255, 255, 230), width=12)
    return img


def icon_span():
    # midnight -> plum, grid of week dots, some filled amber
    img = vgrad((0x1A, 0x1E, 0x3A), (0x3A, 0x2A, 0x55))
    d = ImageDraw.Draw(img, "RGBA")
    import random
    random.seed(11)
    cols, rows = 8, 8
    m, gap = 230, 70
    r = 22
    filled = 26
    n = 0
    for ry in range(rows):
        for cx in range(cols):
            x = m + cx * gap
            y = m + ry * gap
            n += 1
            if n <= filled:
                col = (0xFF, 0xC1, 0x5A, 255)
            elif n == filled + 1:
                col = (0xFF, 0xFF, 0xFF, 255)  # "now"
            else:
                col = (255, 255, 255, 55)
            d.ellipse((x - r, y - r, x + r, y + r), fill=col)
    return img


APPS = [
    ("01-stash", "Stash", icon_stash, (0x12, 0x8F, 0x8A), (0xF4, 0xF6, 0xF4), (0x0C, 0x14, 0x14)),
    ("02-reveille", "Reveille", icon_reveille, (0xFF, 0x6B, 0x5E), (0xF7, 0xF4, 0xF0), (0x0E, 0x10, 0x1C)),
    ("03-inkling", "Inkling", icon_inkling, (0x7C, 0x5C, 0xFF), (0xF6, 0xF4, 0xFB), (0x12, 0x10, 0x1C)),
    ("04-sprig", "Sprig", icon_sprig, (0x3F, 0x9D, 0x6B), (0xF4, 0xF8, 0xF3), (0x0E, 0x16, 0x11)),
    ("05-yield", "Yield", icon_yield, (0x16, 0x9A, 0x5C), (0xF4, 0xF7, 0xF3), (0x0A, 0x14, 0x0F)),
    ("06-span", "Span", icon_span, (0xE8, 0xA8, 0x4B), (0xF6, 0xF5, 0xF1), (0x0E, 0x10, 0x1A)),
]

for slug, app, art, accent, lLight, lDark in APPS:
    base_contents(slug, app)
    save_icon(slug, app, art())
    colorset(slug, app, "AccentColor", accent)
    colorset(slug, app, "LaunchBackground", lLight, lDark)
    print(f"  ✓ {app}")

print("done")
