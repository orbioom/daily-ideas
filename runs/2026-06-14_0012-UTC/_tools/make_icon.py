#!/usr/bin/env python3
"""Render a 1024x1024 on-brand Orbioom app icon using only the Python stdlib.

Usage:
    python3 make_icon.py <out.png> <glyph> [accentR,accentG,accentB]

Every icon shares the Orbioom ground: a soft mist->ink diagonal gradient with a
quiet upper glow, over which a calm silver motif (optionally accented) is drawn.
This keeps the whole studio reading as one family.

Glyphs for this run:
    node       a central hub with three radiating connected child nodes (mind map)
    globe      a sphere with latitude/longitude lines (geography)
    hourglass  a slim hourglass with settled sand (countdown)
    house      a home: gable roof + body + door (mortgage/loan)
    book       an open book with two page lines (vocabulary)
    mines      a grid with one accented diamond cell (minesweeper)

Pure zlib+struct PNG writer; no third-party libraries.
"""

import zlib
import struct
import math
import sys

SIZE = 1024

MIST = (0xED, 0xEE, 0xF3)
INK = (0x23, 0x26, 0x2F)
SILVER = (0xF6, 0xF7, 0xFB)
ORB_MID = (0x4A, 0x4F, 0x5E)


def lerp(a, b, t):
    return a + (b - a) * t


def clamp8(v):
    return max(0, min(255, int(round(v))))


def mix(c1, c2, t):
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))


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


def ring_cov(px, py, cx, cy, r_out, r_in):
    d = math.hypot(px - cx, py - cy)
    e = 2.5
    if r_in <= d <= r_out:
        return 1.0
    if r_out < d <= r_out + e:
        return (r_out + e - d) / e
    if r_in - e <= d < r_in:
        return (d - (r_in - e)) / e
    return 0.0


def seg_cov(px, py, x0, y0, x1, y1, half):
    """Coverage for a rounded line segment of half-thickness `half`."""
    dx, dy = x1 - x0, y1 - y0
    ll = dx * dx + dy * dy
    if ll == 0:
        d = math.hypot(px - x0, py - y0)
    else:
        t = max(0.0, min(1.0, ((px - x0) * dx + (py - y0) * dy) / ll))
        d = math.hypot(px - (x0 + t * dx), py - (y0 + t * dy))
    e = 1.6
    if d <= half - e:
        return 1.0
    if d >= half + e:
        return 0.0
    return (half + e - d) / (2 * e)


def round_rect(px, py, x0, y0, x1, y1, rad):
    cx = min(max(px, x0 + rad), x1 - rad)
    cy = min(max(py, y0 + rad), y1 - rad)
    if x0 <= px <= x1 and y0 <= py <= y1:
        d = math.hypot(px - cx, py - cy)
        if d <= rad:
            return 1.0
        return max(0.0, 1.0 - (d - rad) / 2.0)
    return 0.0


def glyph_at(glyph, x, y):
    """Return (coverage, accent) where accent>0 paints with the accent tint."""
    cx, cy = SIZE * 0.5, SIZE * 0.5
    S = SIZE

    if glyph == "node":
        hub = aa_disc(x, y, cx, cy, S * 0.072)
        kids = [(0.5, 0.255, 0.05), (0.255, 0.66, 0.044), (0.745, 0.66, 0.044)]
        cov = 0.0
        acc = 0.0
        # connectors first (under nodes)
        conn = 0.0
        for kx, ky, kr in kids:
            conn = max(conn, seg_cov(x, y, cx, cy, S * kx, S * ky, S * 0.012))
        kid_cov = 0.0
        for kx, ky, kr in kids:
            kid_cov = max(kid_cov, aa_disc(x, y, S * kx, S * ky, S * kr))
        if hub > 0:
            return hub, 1.0
        if kid_cov > 0:
            return kid_cov, 0.0
        return conn, 0.0

    if glyph == "globe":
        outline = ring_cov(x, y, cx, cy, S * 0.255, S * 0.232)
        d = math.hypot(x - cx, y - cy)
        inside = d <= S * 0.243
        lines = 0.0
        if inside:
            # equator + two parallels
            for yy in (cy, cy - S * 0.12, cy + S * 0.12):
                lines = max(lines, seg_cov(x, y, cx - S * 0.243, yy, cx + S * 0.243, yy, S * 0.009))
            # meridians as vertical ellipses (approx by scaled distance to center x)
            for k in (0.0, 0.42, 0.84):
                ex = (x - cx) / (S * 0.243 * (k if k > 0 else 0.0001))
                # central meridian (vertical line) + curved ones approximated
            lines = max(lines, seg_cov(x, y, cx, cy - S * 0.243, cx, cy + S * 0.243, S * 0.009))
            # curved meridians via ellipse rings
            for w in (0.5, 1.0):
                rx = S * 0.243 * w
                # ellipse: (x-cx)^2/rx^2 + (y-cy)^2/ry^2 = 1
                ry = S * 0.243
                val = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
                if abs(val - 1.0) < 0.05 and d <= S * 0.243:
                    lines = max(lines, 1.0 - abs(val - 1.0) / 0.05)
        if outline > 0:
            return outline, 1.0
        if lines > 0:
            return lines * 0.9, 0.0
        return 0.0, 0.0

    if glyph == "hourglass":
        # frame plates
        top = round_rect(x, y, S * 0.34, S * 0.27, S * 0.66, S * 0.305, S * 0.012)
        bot = round_rect(x, y, S * 0.34, S * 0.695, S * 0.66, S * 0.73, S * 0.012)
        if top > 0 or bot > 0:
            return max(top, bot), 0.0
        # glass triangles (outline-ish): two triangles meeting at center
        within = 0.0
        # upper triangle from y=0.305..0.5 narrowing to center
        ty0, ty1 = S * 0.305, S * 0.5
        if ty0 <= y <= ty1:
            t = (y - ty0) / (ty1 - ty0)
            half = (S * 0.135) * (1 - t)
            d = abs(x - cx)
            within = 1.0 if abs(d - half) < S * 0.012 else 0.0
        by0, by1 = S * 0.5, S * 0.695
        if by0 <= y <= by1:
            t = (y - by0) / (by1 - by0)
            half = (S * 0.135) * t
            d = abs(x - cx)
            within = max(within, 1.0 if abs(d - half) < S * 0.012 else 0.0)
        # sand in lower bulb (accent)
        sand = 0.0
        sy0, sy1 = S * 0.58, S * 0.695
        if sy0 <= y <= sy1:
            t = (y - sy0) / (sy1 - sy0)
            half = (S * 0.135) * t
            if abs(x - cx) <= half - S * 0.012:
                sand = 1.0
        # falling grain
        grain = aa_disc(x, y, cx, S * 0.55, S * 0.012)
        if sand > 0:
            return sand, 1.0
        if grain > 0:
            return grain, 1.0
        return within, 0.0

    if glyph == "house":
        body = round_rect(x, y, S * 0.345, S * 0.47, S * 0.655, S * 0.7, S * 0.012)
        # roof triangle
        roof = 0.0
        ry0, ry1 = S * 0.30, S * 0.47
        if ry0 <= y <= ry1:
            t = (y - ry0) / (ry1 - ry0)
            half = (S * 0.20) * t
            if abs(x - cx) <= half:
                roof = 1.0
        # door (accent) carved from body
        door = round_rect(x, y, S * 0.465, S * 0.565, S * 0.535, S * 0.7, S * 0.01)
        if door > 0:
            return door, 1.0
        if body > 0 or roof > 0:
            return max(body, roof), 0.0
        return 0.0, 0.0

    if glyph == "book":
        # two pages as slanted quads meeting at center spine
        cov = 0.0
        acc = 0.0
        spine = seg_cov(x, y, cx, S * 0.34, cx, S * 0.66, S * 0.012)
        # left page: a parallelogram
        # approximate each page as region between two lines
        for sgn in (-1, 1):
            # outer top corner, inner top (spine top), inner bottom, outer bottom
            ox = cx + sgn * S * 0.20
            top_y = S * 0.37
            in_top = S * 0.34
            cover = 0.0
            if S * 0.34 <= y <= S * 0.66:
                # page top edge slants from spine(0.34) up to outer(0.37)
                t = (y - S * 0.34) / (S * 0.66 - S * 0.34)
                xin = cx + sgn * (S * 0.012)
                xout = cx + sgn * (S * 0.20)
                lo = min(xin, xout)
                hi = max(xin, xout)
                if lo <= x <= hi:
                    cover = 1.0
            if cover > 0:
                cov = max(cov, cover)
        # page rules (accent lines)
        ruleacc = 0.0
        for yy in (S * 0.44, S * 0.50, S * 0.56):
            for sgn in (-1, 1):
                ruleacc = max(ruleacc, seg_cov(x, y, cx + sgn * S * 0.05, yy, cx + sgn * S * 0.165, yy, S * 0.007))
        if spine > 0:
            return spine, 1.0
        if cov > 0:
            if ruleacc > 0:
                return ruleacc, 1.0
            return cov, 0.0
        return 0.0, 0.0

    if glyph == "mines":
        # 3x3 grid of rounded cells with gaps; center cell holds an accent diamond
        n = 3
        gap = S * 0.018
        total = S * 0.40
        x0 = cx - total / 2
        y0 = cy - total / 2
        cell = (total - gap * (n - 1)) / n
        cov = 0.0
        acc = 0.0
        center_cell = (1, 1)
        for r in range(n):
            for c in range(n):
                bx = x0 + c * (cell + gap)
                by = y0 + r * (cell + gap)
                cc = round_rect(x, y, bx, by, bx + cell, by + cell, S * 0.018)
                if cc > 0:
                    if (c, r) == center_cell:
                        # diamond mine inside center cell
                        mcx = bx + cell / 2
                        mcy = by + cell / 2
                        dd = abs(x - mcx) + abs(y - mcy)
                        if dd <= cell * 0.32:
                            return 1.0, 1.0
                        # spokes
                        return cc, 0.0
                    cov = max(cov, cc)
        return cov, 0.0

    # default: a calm orb
    cov = aa_disc(x, y, cx, cy, S * 0.22)
    return cov, 0.0


def render(glyph, accent):
    rows = bytearray()
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

            cov, acc = glyph_at(glyph, x, y)
            if cov > 0:
                if acc and acc > 0:
                    motif = mix(SILVER, accent, 0.82)
                else:
                    motif = SILVER
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
    glyph = sys.argv[2] if len(sys.argv) > 2 else "node"
    accent = (0x5E, 0xF0, 0xB0)
    if len(sys.argv) > 3:
        accent = tuple(int(v) for v in sys.argv[3].split(","))
    write_png(out, render(glyph, accent))
    print("wrote", out, "glyph", glyph)
