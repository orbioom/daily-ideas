#!/usr/bin/env python3
"""Render a 1024x1024 Orbioom app icon for Split using only the Python stdlib.

Motif: a calm mist -> ink vertical gradient background with two gently
overlapping orbs (suggesting a "split"), each lit by a soft silver radial
highlight. No third-party libraries (zlib + struct only).
"""

import zlib
import struct
import math

SIZE = 1024


def lerp(a, b, t):
    return a + (b - a) * t


def clamp8(v):
    return max(0, min(255, int(round(v))))


def mix(c1, c2, t):
    return (
        lerp(c1[0], c2[0], t),
        lerp(c1[1], c2[1], t),
        lerp(c1[2], c2[2], t),
    )


# Brand tokens.
MIST = (0xED, 0xEE, 0xF3)
INK = (0x23, 0x26, 0x2F)
SILVER = (0xF6, 0xF7, 0xFB)
ORB_DARK = (0x2C, 0x30, 0x3B)
ORB_MID = (0x4A, 0x4F, 0x5E)


def orb_value(px, py, cx, cy, radius):
    """Return (coverage, highlight_t) for a point against an orb.

    coverage in [0,1] with a soft anti-aliased edge; highlight_t in [0,1]
    is the radial lighting where the top-left of the orb glows silver.
    """
    dx = px - cx
    dy = py - cy
    dist = math.sqrt(dx * dx + dy * dy)
    edge = 2.0
    if dist <= radius - edge:
        coverage = 1.0
    elif dist >= radius + edge:
        coverage = 0.0
    else:
        coverage = (radius + edge - dist) / (2 * edge)
    # Highlight strongest toward upper-left of the orb.
    hx = cx - radius * 0.42
    hy = cy - radius * 0.42
    hdist = math.sqrt((px - hx) ** 2 + (py - hy) ** 2)
    htotal = radius * 1.55
    highlight = max(0.0, 1.0 - hdist / htotal)
    highlight = highlight ** 1.6
    return coverage, highlight


def render():
    rows = bytearray()

    # Two overlapping orbs.
    r = SIZE * 0.255
    cx1, cy1 = SIZE * 0.40, SIZE * 0.46
    cx2, cy2 = SIZE * 0.62, SIZE * 0.56

    for y in range(SIZE):
        rows.append(0)  # PNG filter type 0 for this scanline
        # Vertical mist -> ink background with a gentle diagonal tilt.
        for x in range(SIZE):
            ty = y / (SIZE - 1)
            tx = x / (SIZE - 1)
            bg_t = min(1.0, ty * 0.85 + tx * 0.15)
            # ease
            bg_t = bg_t * bg_t * (3 - 2 * bg_t)
            base = mix(MIST, INK, bg_t)

            # subtle radial vignette of light near top-center
            vd = math.sqrt((x - SIZE * 0.5) ** 2 + (y - SIZE * 0.30) ** 2)
            glow = max(0.0, 1.0 - vd / (SIZE * 0.75)) * 0.18
            color = mix(base, SILVER, glow)

            # Orb 2 (drawn first, behind).
            cov2, hi2 = orb_value(x, y, cx2, cy2, r)
            if cov2 > 0:
                orb_col = mix(ORB_DARK, SILVER, hi2 * 0.9)
                orb_col = mix(orb_col, ORB_MID, 0.15)
                color = mix(color, orb_col, cov2)

            # Orb 1 (front).
            cov1, hi1 = orb_value(x, y, cx1, cy1, r)
            if cov1 > 0:
                orb_col = mix(ORB_DARK, SILVER, hi1)
                orb_col = mix(orb_col, ORB_MID, 0.10)
                color = mix(color, orb_col, cov1)

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
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else "icon-1024.png"
    raw = render()
    write_png(out, raw)
    print("wrote", out)
