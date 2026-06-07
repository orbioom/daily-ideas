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
    if glyph == "skein":
        # ball of yarn: a silver disc wound with diagonal accent strands
        ball = aa_disc(x, y, cx, cy, SIZE * 0.205)
        if ball <= 0:
            return 0.0, 0.0
        # diagonal winding lines in both directions
        for off in (-0.18, -0.06, 0.06, 0.18):
            d1 = ((x - cx) + (y - cy)) / SIZE - off
            if abs(d1) < 0.012:
                return ball, 1.0
            d2 = ((x - cx) - (y - cy)) / SIZE - off
            if abs(d2) < 0.012:
                return ball, 1.0
        return ball, 0.0
    if glyph == "barbell":
        bar = in_round_rect(x, y, SIZE * 0.30, SIZE * 0.475, SIZE * 0.70, SIZE * 0.525, SIZE * 0.02)
        plate = 0.0
        for bx in (0.305, 0.355, 0.605, 0.655):
            plate = max(plate, in_round_rect(x, y, SIZE * bx, SIZE * 0.40, SIZE * (bx + 0.04), SIZE * 0.60, SIZE * 0.018))
        grip = 0.0
        if SIZE * 0.46 < y < SIZE * 0.54 and abs(x - cx) < SIZE * 0.06:
            grip = 1.0 if (int(x) // 14) % 2 == 0 else 0.0
        if grip > 0:
            return bar, 1.0
        return max(bar, plate), 0.0
    if glyph == "depth":
        # three downward chevrons (descent into depth); middle is accent
        cov = 0.0
        accenti = 0.0
        for i, yc in enumerate((0.38, 0.50, 0.62)):
            apex_y = SIZE * (yc + 0.06)
            top_y = SIZE * yc
            if top_y <= y <= apex_y:
                t = (y - top_y) / (apex_y - top_y)
                # two arms forming a V meeting at center bottom
                left = cx - SIZE * 0.16 * (1 - t)
                right = cx + SIZE * 0.16 * (1 - t)
                if abs(x - left) < SIZE * 0.018 or abs(x - right) < SIZE * 0.018:
                    cov = 1.0
                    if i == 1:
                        accenti = 1.0
        return cov, accenti
    if glyph == "plank":
        # a board with a vertical kerf cut line through it
        board = in_round_rect(x, y, SIZE * 0.30, SIZE * 0.43, SIZE * 0.70, SIZE * 0.57, SIZE * 0.03)
        if board <= 0:
            return 0.0, 0.0
        # kerf: thin vertical accent gap-line near center
        if abs(x - SIZE * 0.55) < SIZE * 0.009:
            return board, 1.0
        # grain lines (subtle, body tone)
        for gy in (0.475, 0.525):
            if abs(y - SIZE * gy) < SIZE * 0.004:
                return board, -1.0
        return board, 0.0
    if glyph == "signal":
        # radio beacon: a base dot with concentric broadcast arcs rising
        bx, by = cx, SIZE * 0.62
        dot = aa_disc(x, y, bx, by, SIZE * 0.03)
        if dot > 0:
            return dot, 1.0
        d = math.hypot(x - bx, y - by)
        ang = math.degrees(math.atan2(by - y, x - bx))  # upward positive
        if -10 <= ang <= 190:  # upper arcs only
            for k, rr in enumerate((0.11, 0.18, 0.25)):
                if abs(d - SIZE * rr) < SIZE * 0.013 and y < by:
                    return 1.0, (1.0 if k == 0 else 0.0)
        return 0.0, 0.0
    if glyph == "spool":
        # filament spool seen edge-on: two flanges + wound core, accent hub
        flange = 0.0
        for fx in (0.345, 0.625):
            flange = max(flange, in_round_rect(x, y, SIZE * fx, SIZE * 0.34, SIZE * (fx + 0.03), SIZE * 0.66, SIZE * 0.012))
        core = in_round_rect(x, y, SIZE * 0.375, SIZE * 0.42, SIZE * 0.625, SIZE * 0.58, SIZE * 0.01)
        if core > 0:
            # winding lines
            if (int(x) // 18) % 2 == 0:
                return core, -1.0
            return core, 0.0
        hub = aa_disc(x, y, cx, cy, SIZE * 0.035)
        if hub > 0:
            return hub, 1.0
        return flange, 0.0
    if glyph == "hexcomb":
        # three honeycomb hexagons; center accented
        def hexagon(px, py, hcx, hcy, R):
            dx = abs(px - hcx); dy = abs(py - hcy)
            # pointy-top hex via two constraints
            if dy > R or dx > R * 0.8660254:
                return 0.0
            if dx * 0.5 + dy * 0.8660254 > R * 0.8660254:
                return 0.0
            return 1.0
        R = SIZE * 0.115
        dx = R * 0.8660254 * 2
        centers = [(cx, cy - R * 1.05, False), (cx - dx * 0.52, cy + R * 0.55, False),
                   (cx + dx * 0.52, cy + R * 0.55, False), (cx, cy + R * 0.05, True)]
        for (hx, hy, acc) in centers:
            outer = hexagon(x, y, hx, hy, R)
            inner = hexagon(x, y, hx, hy, R - SIZE * 0.016)
            if outer > 0 and inner == 0:
                return 1.0, (1.0 if acc else 0.0)
            if acc and inner > 0:
                # fill center hex lightly with accent
                return 0.8, 1.0
        return 0.0, 0.0
    if glyph == "glass":
        # martini/coupe: triangular bowl on a stem with a base, accent garnish dot
        cov = 0.0
        # bowl: inverted triangle
        topy = SIZE * 0.36
        tipy = SIZE * 0.56
        if topy <= y <= tipy:
            t = (y - topy) / (tipy - topy)
            half = SIZE * 0.17 * (1 - t)
            if abs(x - cx) <= half and abs(x - cx) >= half - SIZE * 0.016:
                cov = 1.0
            if abs(y - topy) < SIZE * 0.016 and abs(x - cx) <= SIZE * 0.17:
                cov = 1.0  # rim
        # stem
        if SIZE * 0.56 < y < SIZE * 0.66 and abs(x - cx) < SIZE * 0.012:
            cov = 1.0
        # base
        if SIZE * 0.655 < y < SIZE * 0.67 and abs(x - cx) < SIZE * 0.07:
            cov = 1.0
        garnish = aa_disc(x, y, cx + SIZE * 0.08, SIZE * 0.40, SIZE * 0.022)
        if garnish > 0:
            return garnish, 1.0
        return cov, 0.0
    if glyph == "moon":
        # crescent moon: big disc minus offset disc; small accent star
        outer = aa_disc(x, y, cx, cy, SIZE * 0.20)
        cut = aa_disc(x, y, cx + SIZE * 0.085, cy - SIZE * 0.05, SIZE * 0.175)
        cres = max(0.0, outer - cut)
        star = aa_disc(x, y, SIZE * 0.64, SIZE * 0.40, SIZE * 0.018)
        if star > 0:
            return star, 1.0
        return cres, 0.0
    if glyph == "track":
        # running track: a rounded-rect oval lane outline + accent start marker
        outer = in_round_rect(x, y, SIZE * 0.30, SIZE * 0.40, SIZE * 0.70, SIZE * 0.60, SIZE * 0.10)
        inner = in_round_rect(x, y, SIZE * 0.36, SIZE * 0.455, SIZE * 0.64, SIZE * 0.545, SIZE * 0.045)
        ring = max(0.0, outer - inner)
        marker = in_round_rect(x, y, SIZE * 0.49, SIZE * 0.40, SIZE * 0.51, SIZE * 0.455, SIZE * 0.005)
        if marker > 0:
            return marker, 1.0
        return ring, 0.0
    if glyph == "dart":
        # concentric dartboard rings + a bullseye accent
        d = math.hypot(x - cx, y - cy)
        for k, rr in enumerate((0.12, 0.19, 0.26)):
            if abs(d - SIZE * rr) < SIZE * 0.014:
                return 1.0, 0.0
        bull = aa_disc(x, y, cx, cy, SIZE * 0.035)
        if bull > 0:
            return bull, 1.0
        return 0.0, 0.0
    if glyph == "dial":
        # watch dial: outer ring + two hands; hub accent
        d = math.hypot(x - cx, y - cy)
        ring = 1.0 if abs(d - SIZE * 0.225) < SIZE * 0.013 else 0.0
        if ring > 0:
            return ring, 0.0
        def hand(ax, ay, length, thick):
            mag = math.hypot(ax, ay)
            ux, uy = ax / mag, ay / mag
            px, py = x - cx, y - cy
            t = px * ux + py * uy
            if 0 <= t <= length:
                perp = abs(px * (-uy) + py * ux)
                if perp < thick:
                    return 1.0
            return 0.0
        h1 = hand(-0.5, -0.86, SIZE * 0.11, SIZE * 0.012)
        h2 = hand(0.0, -1.0, SIZE * 0.165, SIZE * 0.010)
        hub = aa_disc(x, y, cx, cy, SIZE * 0.02)
        if hub > 0:
            return hub, 1.0
        return max(h1, h2), 0.0
    if glyph == "sprout":
        stem = 0.0
        if abs(x - cx) < SIZE * 0.011 and SIZE * 0.42 < y < SIZE * 0.66:
            stem = 1.0
        def leaf(lcx, lcy, ang, rx, ry):
            ca, sa = math.cos(ang), math.sin(ang)
            dx = (x - lcx) * ca + (y - lcy) * sa
            dy = -(x - lcx) * sa + (y - lcy) * ca
            return 1.0 if (dx / rx) ** 2 + (dy / ry) ** 2 <= 1 else 0.0
        l1 = leaf(SIZE * 0.42, SIZE * 0.47, 0.6, SIZE * 0.075, SIZE * 0.030)
        l2 = leaf(SIZE * 0.58, SIZE * 0.47, -0.6, SIZE * 0.075, SIZE * 0.030)
        tip = aa_disc(x, y, cx, SIZE * 0.41, SIZE * 0.022)
        if tip > 0:
            return tip, 1.0
        return max(stem, l1, l2), 0.0
    if glyph == "fly":
        shank = 1.0 if abs(y - cy) < SIZE * 0.010 and SIZE * 0.40 < x < SIZE * 0.60 else 0.0
        d = math.hypot(x - SIZE * 0.55, y - SIZE * 0.56)
        bend = 1.0 if abs(d - SIZE * 0.075) < SIZE * 0.011 and y > cy and x > SIZE * 0.46 else 0.0
        hackle = 0.0
        if abs(x - SIZE * 0.40) < SIZE * 0.05 and abs((y - cy) - (x - SIZE * 0.40) * 0.8) < SIZE * 0.006:
            hackle = 1.0
        bead = aa_disc(x, y, SIZE * 0.40, cy, SIZE * 0.024)
        if bead > 0:
            return bead, 1.0
        return max(shank, bend, hackle), 0.0
    if glyph == "scope":
        ang = -0.5
        ca, sa = math.cos(ang), math.sin(ang)
        dx = (x - cx) * ca + (y - cy) * sa
        dy = -(x - cx) * sa + (y - cy) * ca
        tube = 1.0 if abs(dy) < SIZE * 0.045 and abs(dx) < SIZE * 0.20 else 0.0
        ox = cx + 0.20 * SIZE * ca
        oy = cy - 0.20 * SIZE * sa
        dd = math.hypot(x - ox, y - oy)
        objc = 1.0 if SIZE * 0.044 < dd < SIZE * 0.058 else 0.0
        star = aa_disc(x, y, SIZE * 0.64, SIZE * 0.36, SIZE * 0.020)
        if star > 0:
            return star, 1.0
        return max(tube, objc), 0.0
    if glyph == "thermo":
        stem = 1.0 if abs(x - cx) < SIZE * 0.016 and SIZE * 0.34 < y < SIZE * 0.58 else 0.0
        bulb_d = math.hypot(x - cx, y - SIZE * 0.62)
        bulb_ring = 1.0 if abs(bulb_d - SIZE * 0.055) < SIZE * 0.013 else 0.0
        bulb_fill = aa_disc(x, y, cx, SIZE * 0.62, SIZE * 0.030)
        if bulb_fill > 0:
            return bulb_fill, 1.0
        tick = 0.0
        for ty in (0.40, 0.46, 0.52):
            if abs(y - SIZE * ty) < SIZE * 0.004 and SIZE * 0.516 < x < SIZE * 0.545:
                tick = 1.0
        if tick > 0:
            return tick, -1.0
        return max(stem, bulb_ring), 0.0
    if glyph == "flag":
        # golf: a flagstick rising from a small hole with a triangular pennant
        pole = 1.0 if abs(x - SIZE * 0.45) < SIZE * 0.011 and SIZE * 0.30 < y < SIZE * 0.66 else 0.0
        if pole > 0:
            return pole, 0.0
        # pennant: triangle to the right of the pole top
        topy, boty = SIZE * 0.31, SIZE * 0.44
        flag = 0.0
        if topy <= y <= boty:
            t = (y - topy) / (boty - topy)
            tip = SIZE * 0.45 + SIZE * 0.16 * (1 - t)
            if SIZE * 0.45 <= x <= tip:
                flag = 1.0
        if flag > 0:
            return flag, 1.0
        # hole: a thin ellipse at the base, body tone
        ex = (x - SIZE * 0.47) / (SIZE * 0.085)
        ey = (y - SIZE * 0.665) / (SIZE * 0.022)
        if ex * ex + ey * ey <= 1:
            return 1.0, -1.0
        return 0.0, 0.0
    if glyph == "feather":
        # a quill feather along a diagonal rachis with barb texture; accent tip
        ang = -0.62
        ca, sa = math.cos(ang), math.sin(ang)
        dx = (x - cx) * ca + (y - cy) * sa   # along shaft
        dy = -(x - cx) * sa + (y - cy) * ca  # across shaft
        L = SIZE * 0.22
        cov = 0.0
        if -L <= dx <= L:
            # vane half-width tapers toward the tip (dx = +L)
            t = (dx + L) / (2 * L)
            half = SIZE * 0.085 * (1 - t) * (0.4 + 0.6 * t)
            if abs(dy) < SIZE * 0.008:
                cov = 1.0  # rachis (center quill)
            elif abs(dy) <= half:
                gap = (int((dx + L) / (SIZE * 0.020))) % 2 == 0
                cov = 1.0 if gap else 0.55  # barb comb texture
        # accent at the feather tip (inverse of the shaft transform at dx=+L, dy=0)
        tipx = cx + L * ca
        tipy = cy + L * sa
        if aa_disc(x, y, tipx, tipy, SIZE * 0.026) > 0:
            return 1.0, 1.0
        return cov, 0.0
    if glyph == "note":
        # a single eighth note: a filled head + stem + flag
        head = 0.0
        ex = (x - SIZE * 0.44) / (SIZE * 0.058)
        ey = (y - SIZE * 0.62) / (SIZE * 0.046)
        if ex * ex + ey * ey <= 1:
            head = 1.0
        stem = 1.0 if abs(x - SIZE * 0.497) < SIZE * 0.010 and SIZE * 0.34 < y < SIZE * 0.625 else 0.0
        flagm = 0.0
        topy, boty = SIZE * 0.34, SIZE * 0.46
        if topy <= y <= boty:
            t = (y - topy) / (boty - topy)
            right = SIZE * 0.497 + SIZE * 0.075 * (1 - t * 0.4)
            if SIZE * 0.497 <= x <= right and (x - SIZE * 0.497) > (SIZE * 0.055 * t):
                flagm = 1.0
        if head > 0:
            return head, 1.0
        return max(stem, flagm), 0.0
    if glyph == "cog":
        # a gear: ring body with radial teeth and a hollow accent hub
        d = math.hypot(x - cx, y - cy)
        ang = (math.degrees(math.atan2(y - cy, x - cx)) + 360) % 360
        r_body = SIZE * 0.20
        r_tooth = SIZE * 0.235
        seg = 360.0 / 8
        within_tooth = ((ang % seg) < seg * 0.5)
        outer = r_tooth if within_tooth else r_body
        ring = 1.0 if SIZE * 0.105 <= d <= outer else 0.0
        if ring > 0:
            return ring, 0.0
        hub = aa_disc(x, y, cx, cy, SIZE * 0.045)
        if hub > 0:
            return hub, 1.0
        return 0.0, 0.0
    if glyph == "disc":
        # a flying disc seen at a slight tilt: a flattened ellipse rim with an
        # inner ellipse, plus a small accent flight marker
        ox, oy = cx, cy
        rx, ry = SIZE * 0.225, SIZE * 0.13
        ex = (x - ox) / rx
        ey = (y - oy) / ry
        d = ex * ex + ey * ey
        rim = 1.0 if 0.74 <= d <= 1.0 else 0.0
        if rim > 0:
            return rim, 0.0
        inner = 1.0 if d <= 0.40 else 0.0
        if inner > 0:
            return inner, 1.0
        return 0.0, 0.0
    if glyph == "pill":
        # a capsule on a slight diagonal; one half accented, one half body tone
        ang = -0.5
        ca, sa = math.cos(ang), math.sin(ang)
        dx = (x - cx) * ca + (y - cy) * sa
        dy = -(x - cx) * sa + (y - cy) * ca
        halfL = SIZE * 0.16
        rad = SIZE * 0.072
        inside = False
        if abs(dx) <= halfL - rad:
            inside = abs(dy) <= rad
        else:
            ecx = (halfL - rad) * (1 if dx > 0 else -1)
            inside = math.hypot(dx - ecx, dy) <= rad
        if not inside:
            return 0.0, 0.0
        if abs(dx) < SIZE * 0.006:
            return 1.0, 1.0  # divider line accent
        if dx > 0:
            return 1.0, 1.0  # accent half
        return 1.0, -1.0     # silver/body half
    if glyph == "plane":
        # top-down aircraft: fuselage + swept wings + tailplane; accent nose dot
        fuse = in_round_rect(x, y, SIZE * 0.478, SIZE * 0.32, SIZE * 0.522, SIZE * 0.70, SIZE * 0.022)
        wing = in_round_rect(x, y, SIZE * 0.30, SIZE * 0.50, SIZE * 0.70, SIZE * 0.545, SIZE * 0.02)
        tail = in_round_rect(x, y, SIZE * 0.42, SIZE * 0.635, SIZE * 0.58, SIZE * 0.665, SIZE * 0.014)
        nose = aa_disc(x, y, cx, SIZE * 0.325, SIZE * 0.024)
        if nose > 0:
            return nose, 1.0
        return max(fuse, wing, tail), 0.0
    if glyph == "rocket":
        # upright rocket: body + nose cone + two fins; accent porthole
        body = in_round_rect(x, y, SIZE * 0.44, SIZE * 0.36, SIZE * 0.56, SIZE * 0.64, SIZE * 0.045)
        nose = 0.0
        if SIZE * 0.28 <= y <= SIZE * 0.36:
            t = (y - SIZE * 0.28) / (SIZE * 0.08)
            half = SIZE * 0.06 * t
            if abs(x - cx) <= half:
                nose = 1.0
        fin = 0.0
        if SIZE * 0.54 <= y <= SIZE * 0.66:
            t = (y - SIZE * 0.54) / (SIZE * 0.12)
            edgeL = cx - SIZE * 0.06 - SIZE * 0.07 * t
            edgeR = cx + SIZE * 0.06 + SIZE * 0.07 * t
            if (edgeL <= x <= cx - SIZE * 0.06) or (cx + SIZE * 0.06 <= x <= edgeR):
                fin = 1.0
        window = aa_disc(x, y, cx, SIZE * 0.45, SIZE * 0.028)
        if window > 0:
            return window, 1.0
        return max(body, nose, fin), 0.0
    if glyph == "battery":
        # upright cell: terminal nub + outline ring + accent charge fill
        nub = in_round_rect(x, y, SIZE * 0.46, SIZE * 0.305, SIZE * 0.54, SIZE * 0.345, SIZE * 0.012)
        if nub > 0:
            return nub, 0.0
        outer = in_round_rect(x, y, SIZE * 0.38, SIZE * 0.35, SIZE * 0.62, SIZE * 0.69, SIZE * 0.035)
        inner = in_round_rect(x, y, SIZE * 0.405, SIZE * 0.375, SIZE * 0.595, SIZE * 0.665, SIZE * 0.02)
        ring = max(0.0, outer - inner)
        if ring > 0:
            return ring, 0.0
        fill = in_round_rect(x, y, SIZE * 0.42, SIZE * 0.50, SIZE * 0.58, SIZE * 0.655, SIZE * 0.012)
        if fill > 0:
            return fill, 1.0
        return 0.0, 0.0
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
