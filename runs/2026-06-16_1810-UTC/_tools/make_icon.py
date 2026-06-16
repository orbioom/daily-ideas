#!/usr/bin/env python3
"""Render a 1024x1024 designed app icon (Pillow).

Usage:
    python3 make_icon.py <out.png> <glyph> <bgTopHex> <bgBotHex> <accentHex>

Each icon: a soft diagonal gradient (bgTop -> bgBot) with a quiet radial glow,
over which a clean glyph is drawn (white motif + accent highlights). Glyphs are
purpose-built per app so the six read as distinct but share one calm family.

Glyphs:
    spade     FreeCell solitaire (Citadel)
    cage      Calcudoku math puzzle: grid w/ a cage + math sign (Quotient)
    star      Civics / citizenship: a star within a soft shield (Citizen)
    pie       Quarterly tax: a ring with one accent quarter wedge (Quarter)
    ripple    Anxiety grounding: concentric calming ripples + center (Haven)
    cup       Kitchen toolkit: a measuring cup with handle + line (Galley)
"""
import sys, math
from PIL import Image, ImageDraw

SS = 4                       # supersample factor
SIZE = 1024
N = SIZE * SS                # working canvas size


def hx(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(int(round(lerp(c1[i], c2[i], t))) for i in range(3))


def gradient_bg(bg_top, bg_bot, accent):
    img = Image.new("RGB", (N, N))
    px = img.load()
    cx, cy = N * 0.5, N * 0.30
    glow_r = N * 0.85
    for y in range(N):
        ty = y / (N - 1)
        for x in range(N):
            tx = x / (N - 1)
            t = min(1.0, ty * 0.82 + tx * 0.18)
            t = t * t * (3 - 2 * t)
            base = mix(bg_top, bg_bot, t)
            d = math.hypot(x - cx, y - cy)
            glow = max(0.0, 1.0 - d / glow_r) * 0.14
            px[x, y] = mix(base, (255, 255, 255), glow)
    return img


def rounded_square_mask():
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    r = int(N * 0.225)
    d.rounded_rectangle([0, 0, N - 1, N - 1], radius=r, fill=255)
    return m


WHITE = (246, 247, 251)


def draw_glyph(img, glyph, accent):
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = N * 0.5, N * 0.5
    acc = accent + (255,)
    white = WHITE + (255,)

    if glyph == "spade":
        # spade body: two lobes + a triangle, on felt
        r = N * 0.16
        d.ellipse([cx - r * 1.55, cy - r * 0.6, cx - r * 0.05, cy + r * 0.9], fill=white)
        d.ellipse([cx + r * 0.05, cy - r * 0.6, cx + r * 1.55, cy + r * 0.9], fill=white)
        d.polygon([(cx - r * 1.5, cy + r * 0.45), (cx + r * 1.5, cy + r * 0.45),
                   (cx, cy - r * 1.35)], fill=white)
        # stem
        d.polygon([(cx, cy + r * 0.2), (cx - r * 0.5, cy + r * 1.55),
                   (cx + r * 0.5, cy + r * 1.55)], fill=white)
        # small accent diamond inset (the "free cell" jewel)
        s = N * 0.052
        d.polygon([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)], fill=acc)

    elif glyph == "cage":
        # 3x3 grid; thick accent cage around top-left 2 cells; '+' in a cell
        total = N * 0.46
        x0 = cx - total / 2
        y0 = cy - total / 2
        cell = total / 3
        lw = max(2, int(N * 0.006))
        for i in range(4):
            d.line([(x0, y0 + i * cell), (x0 + total, y0 + i * cell)], fill=white, width=lw)
            d.line([(x0 + i * cell, y0), (x0 + i * cell, y0 + total)], fill=white, width=lw)
        # accent cage (top row, 2 cells)
        clw = max(3, int(N * 0.013))
        pad = cell * 0.10
        d.rounded_rectangle([x0 + pad, y0 + pad, x0 + 2 * cell - pad, y0 + cell - pad],
                            radius=int(cell * 0.16), outline=acc, width=clw)
        # plus sign centered in middle cell
        mx, my = cx, y0 + cell * 1.5
        ps = cell * 0.26
        d.line([(mx - ps, my), (mx + ps, my)], fill=white, width=clw)
        d.line([(mx, my - ps), (mx, my + ps)], fill=white, width=clw)
        # minus accent in bottom-right cell
        bx, by = x0 + cell * 2.5, y0 + cell * 2.5
        d.line([(bx - ps, by), (bx + ps, by)], fill=acc, width=clw)

    elif glyph == "star":
        # soft shield with a 5-point star
        sw, sh = N * 0.34, N * 0.40
        d.rounded_rectangle([cx - sw, cy - sh * 0.92, cx + sw, cy + sh * 0.25],
                            radius=int(N * 0.05), fill=white)
        d.polygon([(cx - sw, cy + sh * 0.18), (cx + sw, cy + sh * 0.18),
                   (cx, cy + sh * 0.95)], fill=white)
        # star
        pts = []
        R = N * 0.155
        r = R * 0.42
        for k in range(10):
            ang = -math.pi / 2 + k * math.pi / 5
            rad = R if k % 2 == 0 else r
            pts.append((cx + rad * math.cos(ang), (cy - N * 0.03) + rad * math.sin(ang)))
        d.polygon(pts, fill=acc)

    elif glyph == "pie":
        # ring with one accent quarter wedge (quarterly)
        R = N * 0.215
        rin = N * 0.115
        d.ellipse([cx - R, cy - R, cx + R, cy + R], fill=white)
        # accent quarter (top-right)
        d.pieslice([cx - R, cy - R, cx + R, cy + R], start=-90, end=0, fill=acc)
        d.ellipse([cx - rin, cy - rin, cx + rin, cy + rin], fill=None)
        # punch the hole using background-ish: redraw center as glow white circle
        d.ellipse([cx - rin, cy - rin, cx + rin, cy + rin], fill=white)
        # tiny accent dot center
        dr = N * 0.035
        d.ellipse([cx - dr, cy - dr, cx + dr, cy + dr], fill=acc)

    elif glyph == "ripple":
        # concentric calming ripples + solid center (grounding)
        lw = max(3, int(N * 0.016))
        for i, rr in enumerate([0.085, 0.145, 0.205]):
            col = acc if i == 1 else white
            R = N * rr
            d.ellipse([cx - R, cy - R, cx + R, cy + R], outline=col, width=lw)
        core = N * 0.05
        d.ellipse([cx - core, cy - core, cx + core, cy + core], fill=white)

    elif glyph == "cup":
        # measuring cup: trapezoid body + handle + a measure line + spout
        bw_top, bw_bot = N * 0.30, N * 0.225
        top, bot = cy - N * 0.12, cy + N * 0.18
        body = [(cx - bw_top, top), (cx + bw_top, top),
                (cx + bw_bot, bot), (cx - bw_bot, bot)]
        d.polygon(body, fill=white)
        # spout (top-left)
        d.polygon([(cx - bw_top, top), (cx - bw_top - N * 0.05, top - N * 0.03),
                   (cx - bw_top + N * 0.02, top + N * 0.03)], fill=white)
        # handle (right)
        hlw = max(4, int(N * 0.022))
        d.arc([cx + bw_top - N * 0.02, top + N * 0.02, cx + bw_top + N * 0.16, top + N * 0.20],
              start=-70, end=80, fill=white, width=hlw)
        # accent measure line across body
        ly = cy + N * 0.0
        d.line([(cx - bw_top * 0.86, ly), (cx + bw_top * 0.5, ly)], fill=acc, width=max(3, int(N * 0.012)))

    else:
        d.ellipse([cx - N * 0.18, cy - N * 0.18, cx + N * 0.18, cy + N * 0.18], fill=white)


def main():
    out = sys.argv[1]
    glyph = sys.argv[2]
    bg_top = hx(sys.argv[3])
    bg_bot = hx(sys.argv[4])
    accent = hx(sys.argv[5])

    img = gradient_bg(bg_top, bg_bot, accent)
    draw_glyph(img, glyph, accent)
    # round the corners onto an opaque iOS-style square (Xcode also masks, but keep crisp)
    img = img.resize((SIZE, SIZE), Image.LANCZOS).convert("RGB")
    img.save(out)
    print("wrote", out, glyph)


if __name__ == "__main__":
    main()
