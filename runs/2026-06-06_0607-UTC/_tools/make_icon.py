#!/usr/bin/env python3
"""Render a 1024x1024 on-brand Orbioom app icon using only the Python stdlib.

Usage:
    python3 make_icon.py <out.png> <glyph> [accentR,accentG,accentB]

<glyph> selects a calm foreground motif over the shared mist->ink orb ground:
    orb        two overlapping orbs
    ring        progress / timer ring with a gap
    aperture    camera aperture blades
    wave        a soft horizontal waveform band
    bars        three ascending rounded bars (insight/practice)
    jar         a rounded vessel (pantry)
    summit      a mountain peak with a marker dot (climbing)
    loaf        a domed loaf with a score line (baking)
    node        connected nodes (graph / critical path)
    text        stacked text lines with one highlighted (prose)
    spark       a compression chevron pair (densify)
    dice        a die face (board games)

The motif is drawn in soft silver with a restrained accent glow so every icon
reads as one family. Pure zlib+struct PNG writer; no third-party libraries.
"""

import zlib
import struct
import math
import sys

SIZE = 1024


def lerp(a, b, t):
    return a + (b - a) * t


def clamp8(v):
    return max(0, min(255, int(round(v))))


def mix(c1, c2, t):
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))


MIST = (0xED, 0xEE, 0xF3)
INK = (0x23, 0x26, 0x2F)
SILVER = (0xF6, 0xF7, 0xFB)
ORB_DARK = (0x2C, 0x30, 0x3B)
ORB_MID = (0x4A, 0x4F, 0x5E)


def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def aa_disc(px, py, cx, cy, r, edge=2.0):
    d = math.hypot(px - cx, py - cy)
    if d <= r - edge:
        return 1.0
    if d >= r + edge:
        return 0.0
    return (r + edge - d) / (2 * edge)


def orb_value(px, py, cx, cy, radius):
    cov = aa_disc(px, py, cx, cy, radius)
    hx = cx - radius * 0.42
    hy = cy - radius * 0.42
    hdist = math.hypot(px - hx, py - hy)
    highlight = max(0.0, 1.0 - hdist / (radius * 1.55)) ** 1.6
    return cov, highlight


def ring_coverage(px, py, cx, cy, r_out, r_in, gap_deg=70):
    d = math.hypot(px - cx, py - cy)
    band = 1.0 if r_in <= d <= r_out else 0.0
    if band == 0.0:
        # anti-alias the band edges
        e = 3.0
        if r_out < d <= r_out + e:
            band = (r_out + e - d) / e
        elif r_in - e <= d < r_in:
            band = (d - (r_in - e)) / e
        else:
            return 0.0
    ang = (math.degrees(math.atan2(py - cy, px - cx)) + 360) % 360
    start = 90 - gap_deg / 2
    end = 90 + gap_deg / 2
    if start <= ang <= end:
        return 0.0
    return band


def in_round_rect(px, py, x0, y0, x1, y1, rad):
    cx = min(max(px, x0 + rad), x1 - rad)
    cy = min(max(py, y0 + rad), y1 - rad)
    if x0 <= px <= x1 and y0 <= py <= y1:
        d = math.hypot(px - cx, py - cy)
        return 1.0 if d <= rad else max(0.0, 1.0 - (d - rad) / 2.0)
    return 0.0


def glyph_alpha(glyph, x, y, accent):
    """Return (coverage, accentMix) for the silver motif at pixel x,y."""
    cx, cy = SIZE * 0.5, SIZE * 0.5
    if glyph == "orb":
        r = SIZE * 0.205
        c2, h2 = orb_value(x, y, SIZE * 0.435, SIZE * 0.45, r)
        c1, h1 = orb_value(x, y, SIZE * 0.6, SIZE * 0.55, r)
        cov = max(c1, c2)
        hi = h1 if c1 >= c2 else h2
        return cov, hi * 0.0
    if glyph == "ring":
        return ring_coverage(x, y, cx, cy, SIZE * 0.30, SIZE * 0.225), 1.0
    if glyph == "aperture":
        cov = ring_coverage(x, y, cx, cy, SIZE * 0.285, SIZE * 0.235, gap_deg=0)
        # blades: radial spokes
        ang = (math.degrees(math.atan2(y - cy, x - cx)) + 360) % 360
        d = math.hypot(x - cx, y - cy)
        spoke = 0.0
        if d < SIZE * 0.285:
            for k in range(6):
                base = k * 60
                if abs(((ang - base + 180) % 360) - 180) < 2.2 and d > SIZE * 0.05:
                    spoke = 1.0
        return max(cov, spoke), 1.0
    if glyph == "wave":
        amp = SIZE * 0.085
        yy = cy + amp * math.sin((x / SIZE) * math.pi * 4)
        thick = SIZE * 0.022
        cov = max(0.0, 1.0 - abs(y - yy) / thick)
        return cov, 1.0
    if glyph == "bars":
        cov = 0.0
        heights = [0.16, 0.26, 0.36]
        for i, h in enumerate(heights):
            bx = SIZE * (0.34 + i * 0.13)
            cov = max(cov, in_round_rect(x, y, bx, SIZE * (0.66 - h), bx + SIZE * 0.085, SIZE * 0.66, SIZE * 0.03))
        return cov, 1.0
    if glyph == "jar":
        body = in_round_rect(x, y, SIZE * 0.36, SIZE * 0.40, SIZE * 0.64, SIZE * 0.70, SIZE * 0.05)
        lid = in_round_rect(x, y, SIZE * 0.40, SIZE * 0.32, SIZE * 0.60, SIZE * 0.40, SIZE * 0.02)
        return max(body, lid), 0.0
    if glyph == "summit":
        # triangle peak
        within = 0.0
        x0, x1 = SIZE * 0.28, SIZE * 0.72
        apex = (SIZE * 0.5, SIZE * 0.34)
        base_y = SIZE * 0.66
        if base_y >= y >= apex[1]:
            t = (y - apex[1]) / (base_y - apex[1])
            half = (x1 - x0) / 2 * t
            if abs(x - SIZE * 0.5) <= half:
                within = 1.0
        dot = aa_disc(x, y, SIZE * 0.5, SIZE * 0.30, SIZE * 0.028)
        return within, (1.0 if dot > 0 else 0.0) if dot > 0 else 0.0
    if glyph == "loaf":
        # dome
        cov = 0.0
        rx, ry = SIZE * 0.22, SIZE * 0.14
        ex = (x - cx) / rx
        ey = (y - SIZE * 0.56) / ry
        if ey <= 0 and ex * ex + ey * ey <= 1:
            cov = 1.0
        elif 0 < (y - SIZE * 0.56) < SIZE * 0.02 and abs(x - cx) < rx:
            cov = 1.0
        # score line
        score = 0.0
        sy = SIZE * 0.49 + (x - cx) * 0.12
        if cov > 0 and abs(y - sy) < SIZE * 0.008 and abs(x - cx) < rx * 0.7:
            return cov, 1.0
        return cov, 0.0
    if glyph == "node":
        pts = [(0.34, 0.38), (0.64, 0.34), (0.5, 0.58), (0.7, 0.66), (0.32, 0.64)]
        edges = [(0, 2), (1, 2), (2, 3), (2, 4)]
        cov = 0.0
        for (i, j) in edges:
            ax, ay = pts[i][0] * SIZE, pts[i][1] * SIZE
            bx, by = pts[j][0] * SIZE, pts[j][1] * SIZE
            # distance to segment
            vx, vy = bx - ax, by - ay
            t = max(0.0, min(1.0, ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy)))
            dxp = x - (ax + t * vx)
            dyp = y - (ay + t * vy)
            if math.hypot(dxp, dyp) < SIZE * 0.008:
                cov = max(cov, 0.55)
        accenti = 0.0
        for k, (nx, ny) in enumerate(pts):
            d = aa_disc(x, y, nx * SIZE, ny * SIZE, SIZE * 0.035)
            if d > 0:
                cov = max(cov, d)
                if k == 2:
                    accenti = 1.0
        return cov, accenti
    if glyph == "text":
        cov = 0.0
        accenti = 0.0
        widths = [0.30, 0.24, 0.28, 0.18]
        for i, w in enumerate(widths):
            ly = SIZE * (0.38 + i * 0.085)
            c = in_round_rect(x, y, SIZE * 0.34, ly, SIZE * (0.34 + w), ly + SIZE * 0.03, SIZE * 0.015)
            if c > 0:
                cov = max(cov, c)
                if i == 1:
                    accenti = 1.0
        return cov, accenti
    if glyph == "spark":
        # two chevrons pointing inward (compression)
        cov = 0.0
        def chevron(px, py, tipx, direction):
            # direction +1 points right, -1 points left
            dx = (px - tipx) * direction
            if dx < 0 or dx > SIZE * 0.16:
                return 0.0
            spread = dx
            if abs(abs(py - cy) - spread) < SIZE * 0.018:
                return 1.0
            return 0.0
        cov = max(chevron(x, y, SIZE * 0.36, 1), chevron(x, y, SIZE * 0.64, -1))
        return cov, 1.0
    if glyph == "dice":
        face = in_round_rect(x, y, SIZE * 0.36, SIZE * 0.36, SIZE * 0.64, SIZE * 0.64, SIZE * 0.06)
        if face <= 0:
            return 0.0, 0.0
        # pips (5)
        pips = [(0.43, 0.43), (0.57, 0.43), (0.5, 0.5), (0.43, 0.57), (0.57, 0.57)]
        for k, (pxn, pyn) in enumerate(pips):
            if aa_disc(x, y, pxn * SIZE, pyn * SIZE, SIZE * 0.022) > 0:
                return face, (1.0 if k == 2 else 0.0)
        return face * 0.0 + face, -1.0  # body marker
    # default
    return orb_value(x, y, cx, cy, SIZE * 0.2)[0], 0.0


def render(glyph, accent):
    rows = bytearray()
    cx1, cy1 = SIZE * 0.40, SIZE * 0.46
    for y in range(SIZE):
        rows.append(0)
        for x in range(SIZE):
            ty = y / (SIZE - 1)
            tx = x / (SIZE - 1)
            bg_t = smooth(min(1.0, ty * 0.85 + tx * 0.15))
            base = mix(MIST, INK, bg_t)
            vd = math.hypot(x - SIZE * 0.5, y - SIZE * 0.30)
            glow = max(0.0, 1.0 - vd / (SIZE * 0.75)) * 0.18
            color = mix(base, SILVER, glow)

            if glyph == "orb":
                r = SIZE * 0.235
                cx2, cy2 = SIZE * 0.62, SIZE * 0.56
                cov2, hi2 = orb_value(x, y, cx2, cy2, r)
                if cov2 > 0:
                    oc = mix(ORB_DARK, SILVER, hi2 * 0.9)
                    oc = mix(oc, ORB_MID, 0.15)
                    color = mix(color, oc, cov2)
                cov1, hi1 = orb_value(x, y, cx1, cy1, r)
                if cov1 > 0:
                    oc = mix(ORB_DARK, SILVER, hi1)
                    oc = mix(oc, ORB_MID, 0.10)
                    color = mix(color, oc, cov1)
            else:
                cov, accenti = glyph_alpha(glyph, x, y, accent)
                if cov > 0:
                    motif = SILVER
                    if accenti and accenti > 0:
                        motif = mix(SILVER, accent, 0.85)
                    elif accenti and accenti < 0:
                        motif = mix(SILVER, ORB_MID, 0.25)
                    color = mix(color, motif, min(1.0, cov))

            rows.append(clamp8(color[0]))
            rows.append(clamp8(color[1]))
            rows.append(clamp8(color[2]))
            rows.append(255)
    return bytes(rows)


def chunk(tag, data):
    out = struct.pack(">I", len(data))
    out += tag + data
    out += struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    return out


def write_png(path, raw):
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    idat = zlib.compress(raw, 9)
    with open(path, "wb") as f:
        f.write(sig)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", idat))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "icon-1024.png"
    glyph = sys.argv[2] if len(sys.argv) > 2 else "orb"
    accent = (0x5E, 0xF0, 0xB0)
    if len(sys.argv) > 3:
        accent = tuple(int(v) for v in sys.argv[3].split(","))
    write_png(out, render(glyph, accent))
    print("wrote", out, "glyph", glyph)
