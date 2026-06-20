#!/usr/bin/env python3
"""
Generate a 1024x1024 app icon PNG for "Pair" using only stdlib (struct + zlib).
Design:
  - Dark navy background #1A1B3A
  - Two overlapping rounded-rectangle card shapes in coral #FF6B6B
  - Sparkle / star decoration
"""

import struct
import zlib
import math
import os

SIZE = 1024

# ── colour palette ──────────────────────────────────────────────────────────
BG      = (0x1A, 0x1B, 0x3A)   # #1A1B3A  navy
CORAL   = (0xFF, 0x6B, 0x6B)   # #FF6B6B  accent
CARD_BG = (0x2D, 0x2B, 0x69)   # #2D2B69  card back
WHITE   = (0xFF, 0xFF, 0xFF)
GOLD    = (0xFF, 0xD7, 0x00)


# ── pixel buffer ─────────────────────────────────────────────────────────────
pixels = [list(BG) for _ in range(SIZE * SIZE)]


def set_pixel(x: int, y: int, rgb: tuple, alpha: float = 1.0) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        idx = y * SIZE + x
        if alpha >= 1.0:
            pixels[idx] = list(rgb)
        else:
            bg = pixels[idx]
            pixels[idx] = [
                int(bg[c] * (1 - alpha) + rgb[c] * alpha) for c in range(3)
            ]


def blend(x: int, y: int, rgb: tuple, alpha: float) -> None:
    set_pixel(x, y, rgb, alpha)


# ── drawing primitives ────────────────────────────────────────────────────────
def fill_rect(x0: int, y0: int, x1: int, y1: int, rgb: tuple) -> None:
    for y in range(max(0, y0), min(SIZE, y1)):
        for x in range(max(0, x0), min(SIZE, x1)):
            set_pixel(x, y, rgb)


def fill_rounded_rect(
    x0: int, y0: int, x1: int, y1: int, r: int,
    rgb: tuple, alpha: float = 1.0
) -> None:
    """Anti-aliased filled rounded rectangle."""
    # Clamp radius
    r = min(r, (x1 - x0) // 2, (y1 - y0) // 2)
    # Centres of corner circles
    cx = [x0 + r, x1 - r, x0 + r, x1 - r]
    cy = [y0 + r, y0 + r, y1 - r, y1 - r]

    for y in range(max(0, y0), min(SIZE, y1)):
        for x in range(max(0, x0), min(SIZE, x1)):
            # Is point inside the rounded rect?
            in_x = x0 + r <= x <= x1 - r
            in_y = y0 + r <= y <= y1 - r

            if in_x or in_y:
                blend(x, y, rgb, alpha)
            else:
                # find nearest corner centre
                nearest_cx = cx[0] if x < (x0 + x1) // 2 else cx[1]
                nearest_cy = cy[0] if y < (y0 + y1) // 2 else cy[2]
                dist = math.sqrt((x - nearest_cx) ** 2 + (y - nearest_cy) ** 2)
                if dist < r - 1:
                    blend(x, y, rgb, alpha)
                elif dist < r + 1:
                    # AA edge
                    a = (r + 1 - dist) / 2.0
                    blend(x, y, rgb, alpha * max(0.0, min(1.0, a)))


def stroke_rounded_rect(
    x0: int, y0: int, x1: int, y1: int, r: int,
    rgb: tuple, width: int = 4, alpha: float = 1.0
) -> None:
    """Draw a stroked (outline) rounded rectangle."""
    for w in range(width):
        fill_rounded_rect(x0 + w, y0 + w, x1 - w, y1 - w, max(1, r - w), rgb, alpha * 0.85)
    # Erase interior
    fill_rounded_rect(
        x0 + width, y0 + width, x1 - width, y1 - width,
        max(1, r - width), BG, 0.0
    )


def fill_circle(cx: int, cy: int, r: float, rgb: tuple, alpha: float = 1.0) -> None:
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if dist < r - 1:
                blend(x, y, rgb, alpha)
            elif dist < r + 1:
                a = (r + 1 - dist) / 2.0
                blend(x, y, rgb, alpha * max(0.0, min(1.0, a)))


def draw_sparkle(cx: int, cy: int, size: float, rgb: tuple, alpha: float = 1.0) -> None:
    """Draw a 4-point star / sparkle."""
    arms = 4
    for arm in range(arms):
        angle = math.pi / arms * arm
        # Long spike
        x1e = cx + math.cos(angle) * size
        y1e = cy + math.sin(angle) * size
        x2e = cx - math.cos(angle) * size
        y2e = cy - math.sin(angle) * size
        draw_line_aa(cx, cy, int(x1e), int(y1e), rgb, alpha, width=max(2, int(size * 0.12)))
        draw_line_aa(cx, cy, int(x2e), int(y2e), rgb, alpha, width=max(2, int(size * 0.12)))
        # Short perpendicular spike
        pa = angle + math.pi / 2
        px1 = cx + math.cos(pa) * size * 0.35
        py1 = cy + math.sin(pa) * size * 0.35
        px2 = cx - math.cos(pa) * size * 0.35
        py2 = cy - math.sin(pa) * size * 0.35
        draw_line_aa(cx, cy, int(px1), int(py1), rgb, alpha, width=max(1, int(size * 0.08)))
        draw_line_aa(cx, cy, int(px2), int(py2), rgb, alpha, width=max(1, int(size * 0.08)))
    fill_circle(cx, cy, size * 0.1, rgb, alpha)


def draw_line_aa(x0, y0, x1, y1, rgb, alpha=1.0, width=2):
    """Bresenham line with width via perpendicular offset."""
    dx = x1 - x0
    dy = y1 - y0
    length = math.sqrt(dx * dx + dy * dy)
    if length == 0:
        return
    nx = -dy / length
    ny = dx / length
    half = width / 2.0
    steps = int(length) + 1
    for i in range(steps + 1):
        t = i / max(1, steps)
        px = x0 + dx * t
        py = y0 + dy * t
        for w in range(-int(half) - 1, int(half) + 2):
            wx = int(px + nx * w)
            wy = int(py + ny * w)
            dist_from_centre = abs(w)
            if dist_from_centre < half - 0.5:
                blend(wx, wy, rgb, alpha)
            elif dist_from_centre < half + 0.5:
                a2 = (half + 0.5 - dist_from_centre)
                blend(wx, wy, rgb, alpha * max(0.0, min(1.0, a2)))


# ── icon composition ──────────────────────────────────────────────────────────
def draw_icon():
    C = SIZE // 2  # centre

    # 1. Background — already filled with BG

    # 2. Subtle radial glow in the centre
    for r in range(300, 0, -1):
        a = (300 - r) / 300 * 0.18
        fill_circle(C, C, r, (0x3A, 0x2F, 0x80), a)

    # 3. Card shadow (subtle dark ellipse)
    for r in range(220, 180, -1):
        a = (r - 180) / 40 * 0.18
        fill_circle(C + 20, C + 20, r, (0x00, 0x00, 0x00), a)

    # 4. Back card (bottom-right, slightly rotated via shear)
    card_w, card_h, card_r = 340, 440, 60
    offset = 55
    # Draw as slightly shifted / "rotated" card using a parallelogram approximation
    shear = 28
    bx0, by0 = C - card_w // 2 + offset, C - card_h // 2 + offset
    bx1, by1 = bx0 + card_w, by0 + card_h
    # Fill background card (CARD_BG tinted)
    fill_rounded_rect(bx0 + shear, by0, bx1 + shear, by1, card_r,
                      (0x38, 0x36, 0x7A), 0.95)
    # Inner border lines to give depth
    for i in range(1, 4):
        stroke_rounded_rect(
            bx0 + shear + i * 12, by0 + i * 12,
            bx1 + shear - i * 12, by1 - i * 12,
            card_r - i * 8,
            (0xFF, 0xFF, 0xFF), width=2, alpha=0.06,
        )

    # 5. Front card (top-left, no shear)
    fx0, fy0 = C - card_w // 2 - offset, C - card_h // 2 - offset
    fx1, fy1 = fx0 + card_w, fy0 + card_h
    # Card fill — slightly lighter navy
    fill_rounded_rect(fx0, fy0, fx1, fy1, card_r, (0x22, 0x22, 0x58), 1.0)
    # Coral border
    for bw in range(6):
        fill_rounded_rect(fx0 + bw, fy0 + bw, fx1 - bw, fy1 - bw,
                          card_r - bw, CORAL, 0.9 - bw * 0.12)
    # Erase interior back to card fill
    fill_rounded_rect(fx0 + 6, fy0 + 6, fx1 - 6, fy1 - 6, card_r - 6,
                      (0x22, 0x22, 0x58), 1.0)
    # Card face: coral glow fill
    fill_rounded_rect(fx0 + 6, fy0 + 6, fx1 - 6, fy1 - 6, card_r - 6,
                      CORAL, 0.08)

    # 6. Main sparkle on front card
    sp_cx = fx0 + (fx1 - fx0) // 2
    sp_cy = fy0 + (fy1 - fy0) // 2
    draw_sparkle(sp_cx, sp_cy, 90, WHITE, 0.92)
    fill_circle(sp_cx, sp_cy, 14, WHITE, 0.95)

    # 7. Small accent sparkles scattered
    sparkle_positions = [
        (C + 260, C - 260, 22, GOLD,  0.85),
        (C - 300, C + 200, 16, WHITE, 0.65),
        (C + 210, C + 280, 18, CORAL, 0.70),
        (C - 230, C - 300, 14, WHITE, 0.55),
        (C + 320, C + 60,  12, GOLD,  0.60),
        (C - 60,  C + 340, 10, WHITE, 0.45),
    ]
    for sx, sy, sr, sc, sa in sparkle_positions:
        draw_sparkle(sx, sy, sr, sc, sa)

    # 8. Corner dots — tiny circles that reinforce card motif
    dot_positions = [
        (fx0 + 28, fy0 + 28),
        (fx1 - 28, fy0 + 28),
        (fx0 + 28, fy1 - 28),
        (fx1 - 28, fy1 - 28),
    ]
    for dx, dy in dot_positions:
        fill_circle(dx, dy, 9, CORAL, 0.75)


# ── PNG encoder ───────────────────────────────────────────────────────────────
def make_png(width: int, height: int, pixel_array: list) -> bytes:
    def chunk(tag: bytes, data: bytes) -> bytes:
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    signature = b"\x89PNG\r\n\x1a\n"

    # IHDR
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    ihdr = chunk(b"IHDR", ihdr_data)

    # IDAT — raw image data with filter byte 0 per scanline
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # filter type None
        for x in range(width):
            r, g, b = pixel_array[y * width + x]
            raw += bytes([r, g, b])

    compressed = zlib.compress(bytes(raw), level=6)
    idat = chunk(b"IDAT", compressed)

    # IEND
    iend = chunk(b"IEND", b"")

    return signature + ihdr + idat + iend


# ── main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("Drawing icon...")
    draw_icon()

    print("Encoding PNG...")
    png_bytes = make_png(SIZE, SIZE, pixels)

    out_path = os.path.join(
        os.path.dirname(__file__),
        "ios/Pair/Assets.xcassets/AppIcon.appiconset/icon.png"
    )
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(png_bytes)

    kb = len(png_bytes) / 1024
    print(f"Done! Wrote {kb:.1f} KB to:\n  {out_path}")
