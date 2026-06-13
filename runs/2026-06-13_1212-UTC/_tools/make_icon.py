#!/usr/bin/env python3
"""Render distinctive 1024x1024 app icons for this run using Pillow.

Usage:  python3 make_icon.py <out.png> <motif> <hexA> <hexB> <hexAccent>

<motif> picks the foreground:
    fret     guitar fretboard with a chord shape (Fretwork)
    column   classical column / portico (Portico)
    lever    a bold "L"/bar figure, athletic chevrons (Lever)
    hive     a honeycomb of hexagons with one highlighted (Hive)
    quote    big quotation marks over text lines, masked (Verbatim)
    bill     a calendar page with a checkmark / coin (Remit)

Background is a smooth vertical gradient hexA -> hexB; the glyph is drawn
with the accent + soft white so each icon reads as its own brand.
Pure Pillow; supersampled 4x then downscaled for clean antialiasing.
"""
import sys, math
from PIL import Image, ImageDraw

S = 1024
SS = 4          # supersample factor
N = S * SS


def hx(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def rounded_rect(d, box, r, fill):
    d.rounded_rectangle(box, radius=r, fill=fill)


def bg_gradient(img, top, bot):
    px = img.load()
    for y in range(N):
        t = y / (N - 1)
        # ease for a softer vertical falloff
        te = t * t * (3 - 2 * t)
        c = lerp(top, bot, te)
        for x in range(N):
            px[x, y] = c


def radial_glow(img, cx, cy, rad, color, strength=0.5):
    """Composite a soft radial highlight."""
    glow = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    steps = 60
    for i in range(steps, 0, -1):
        t = i / steps
        r = rad * t
        a = int(strength * 255 * (1 - t) ** 1.4)
        gd.ellipse([cx - r, cy - r, cx + r, cy + r],
                   fill=(color[0], color[1], color[2], a))
    img.alpha_composite(glow)


def draw_fret(d, img, accent, white):
    glow_center(img, accent)
    # fretboard panel
    bw, bh = int(N * 0.52), int(N * 0.74)
    bx, by = (N - bw) // 2, (N - bh) // 2
    rounded_rect(d, [bx, by, bx + bw, by + bh], N * 0.05, (38, 26, 18))
    rounded_rect(d, [bx, by, bx + bw, by + bh], N * 0.05, None)
    # frets (horizontal) and strings (vertical)
    nf = 5
    for i in range(nf + 1):
        y = by + bh * i / nf
        d.line([(bx, y), (bx + bw, y)], fill=(196, 160, 110), width=int(SS * 5))
    ns = 6
    xs = [bx + bw * (j + 0.5) / ns for j in range(ns)]
    for x in xs:
        d.line([(x, by), (x, by + bh)], fill=(150, 150, 160), width=int(SS * 3))
    # an open chord shape: dots on a few string/fret crossings
    dots = [(1, 1), (3, 2), (4, 2)]  # (string idx, fret idx)
    rad = N * 0.045
    for (s, f) in dots:
        cx = xs[s]
        cy = by + bh * (f - 0.5) / nf
        d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=accent)
    # nut highlight
    d.rounded_rectangle([bx, by, bx + bw, by + int(bh * 0.03) + SS * 6],
                        radius=N * 0.01, fill=(230, 225, 215))


def draw_column(d, img, accent, white):
    glow_center(img, accent)
    cx = N // 2
    # capital + base widths
    shaft_w = int(N * 0.30)
    cap_w = int(N * 0.42)
    top = int(N * 0.26)
    bot = int(N * 0.74)
    # base
    d.rectangle([cx - cap_w // 2, bot, cx + cap_w // 2, bot + int(N * 0.05)], fill=white)
    d.rectangle([cx - cap_w // 2, top - int(N * 0.05), cx + cap_w // 2, top], fill=white)
    # shaft
    d.rectangle([cx - shaft_w // 2, top, cx + shaft_w // 2, bot], fill=white)
    # flutes
    nfl = 5
    for i in range(1, nfl):
        x = cx - shaft_w // 2 + shaft_w * i / nfl
        d.line([(x, top + SS * 8), (x, bot - SS * 8)], fill=lerp(white, (120, 120, 130), 0.45), width=int(SS * 4))
    # accent sun/disc behind capital (stoic dawn)
    r = int(N * 0.085)
    d.ellipse([cx - r, top - int(N * 0.12) - r, cx + r, top - int(N * 0.12) + r], fill=accent)


def draw_lever(d, img, accent, white):
    glow_center(img, accent)
    # bold ascending chevrons (progression)
    cx, cy = N // 2, N // 2
    w = int(N * 0.46)
    th = int(N * 0.085)
    gap = int(N * 0.14)
    cols = [white, lerp(white, accent, 0.5), accent]
    for i, col in enumerate(cols):
        yy = cy + gap - i * gap
        pts_up = [
            (cx - w // 2, yy + th),
            (cx, yy - th + int(N * 0.0)),
            (cx + w // 2, yy + th),
            (cx + w // 2 - th, yy + th + th),
            (cx, yy + th),
            (cx - w // 2 + th, yy + th + th),
        ]
        d.polygon(pts_up, fill=col)


def draw_hive(d, img, accent, white):
    glow_center(img, accent)
    # honeycomb of 7 hexagons (center + ring), center highlighted
    cx, cy = N // 2, N // 2
    R = int(N * 0.135)        # hex circumradius
    def hexagon(cxx, cyy, r):
        return [(cxx + r * math.cos(math.pi / 180 * (60 * k - 90)),
                 cyy + r * math.sin(math.pi / 180 * (60 * k - 90))) for k in range(6)]
    # ring centers (pointy-top): vertical neighbor + 6 around
    dist = R * math.sqrt(3) * 0.5 * 2 * 0.92
    ring = []
    for k in range(6):
        ang = math.pi / 180 * (60 * k - 90)
        ring.append((cx + dist * math.cos(ang) * 0.95, cy + dist * math.sin(ang) * 0.95))
    pad = R * 0.07
    for (hx_, hy_) in ring:
        d.polygon(hexagon(hx_, hy_, R - pad), fill=lerp(white, (255, 255, 255), 0.0))
    # outer in muted, center in accent
    for (hx_, hy_) in ring:
        d.polygon(hexagon(hx_, hy_, R - pad), fill=(245, 243, 230))
    d.polygon(hexagon(cx, cy, R - pad), fill=accent)


def draw_quote(d, img, accent, white):
    glow_center(img, accent)
    # large opening quotation marks + masked text lines
    qx, qy = int(N * 0.30), int(N * 0.30)
    r = int(N * 0.052)
    for off in (0, int(N * 0.135)):
        # comma-like quote: circle + tail
        d.ellipse([qx + off - r, qy - r, qx + off + r, qy + r], fill=accent)
        d.polygon([(qx + off - r, qy), (qx + off + r, qy),
                   (qx + off - int(r * 0.2), qy + int(r * 2.0))], fill=accent)
    # text lines below, some masked (filled), some faint (memorization)
    lx = int(N * 0.27)
    lw = int(N * 0.46)
    ly = int(N * 0.50)
    lh = int(N * 0.055)
    gaps = int(N * 0.035)
    fills = [white, white, lerp(white, (120, 120, 130), 0.6), white, lerp(white, (120, 120, 130), 0.6)]
    widths = [1.0, 0.7, 0.85, 0.55, 0.8]
    for i in range(5):
        y = ly + i * (lh + gaps)
        rounded_rect(d, [lx, y, lx + int(lw * widths[i]), y + lh], lh // 2, fills[i])


def draw_bill(d, img, accent, white):
    glow_center(img, accent)
    # calendar page with binding + a check
    pw, ph = int(N * 0.52), int(N * 0.54)
    px, py = (N - pw) // 2, int(N * 0.27)
    rounded_rect(d, [px, py, px + pw, py + ph], N * 0.045, white)
    # header band
    d.rounded_rectangle([px, py, px + pw, py + int(ph * 0.26)], radius=N * 0.045, fill=accent)
    d.rectangle([px, py + int(ph * 0.13), px + pw, py + int(ph * 0.26)], fill=accent)
    # binding rings
    for fx in (0.32, 0.68):
        rx = px + pw * fx
        d.rounded_rectangle([rx - SS * 10, py - SS * 22, rx + SS * 10, py + SS * 18],
                            radius=SS * 10, fill=lerp(white, (120, 120, 130), 0.4))
    # big check mark on body
    bx, by = px + pw * 0.30, py + ph * 0.62
    d.line([(bx, by), (bx + pw * 0.12, by + ph * 0.13),
            (bx + pw * 0.40, by - ph * 0.16)],
           fill=accent, width=int(SS * 18), joint="curve")


def glow_center(img, accent):
    radial_glow(img, N // 2, int(N * 0.42), int(N * 0.55), accent, strength=0.28)


MOTIFS = {
    "fret": draw_fret, "column": draw_column, "lever": draw_lever,
    "hive": draw_hive, "quote": draw_quote, "bill": draw_bill,
}


def main():
    out, motif, a, b, acc = sys.argv[1:6]
    img = Image.new("RGBA", (N, N), (0, 0, 0, 255))
    bg_gradient(img, hx(a), hx(b))
    d = ImageDraw.Draw(img, "RGBA")
    MOTIFS[motif](d, img, hx(acc), (246, 247, 251))
    img = img.convert("RGB").resize((S, S), Image.LANCZOS)
    img.save(out, "PNG")
    print("wrote", out)


if __name__ == "__main__":
    main()
