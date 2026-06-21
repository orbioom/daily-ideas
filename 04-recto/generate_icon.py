#!/usr/bin/env python3
"""
Generate a 1024x1024 PNG app icon for Recto (Digital Bullet Journal).
Design: cream/off-white background, open notebook drawing, bullet point symbol.
Uses only Python stdlib: struct, zlib, math.
"""

import struct
import zlib
import math


def write_png(filename, width, height, pixels):
    """Write a 1024x1024 RGBA PNG using stdlib only."""

    def chunk(tag, data):
        c = struct.pack('>I', len(data)) + tag + data
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return c + struct.pack('>I', crc)

    # Build raw image data (filter byte 0 = None per scanline)
    raw_rows = []
    for y in range(height):
        row = bytearray([0])  # filter type
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            row += bytearray([r, g, b, a])
        raw_rows.append(bytes(row))

    raw_data = b''.join(raw_rows)
    compressed = zlib.compress(raw_data, 9)

    signature = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    # IHDR color type 2 = RGB — switch to 6 (RGBA)
    ihdr_data = struct.pack('>II', width, height) + bytes([8, 6, 0, 0, 0])

    png = (
        signature
        + chunk(b'IHDR', ihdr_data)
        + chunk(b'IDAT', compressed)
        + chunk(b'IEND', b'')
    )

    with open(filename, 'wb') as f:
        f.write(png)


def lerp(a, b, t):
    return a + (b - a) * t


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def dist(x1, y1, x2, y2):
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)


def smooth_step(edge0, edge1, x):
    t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


SIZE = 1024

# Colors (RGBA)
BG_COLOR       = (245, 240, 232, 255)   # cream #F5F0E8
PAPER_COLOR    = (252, 249, 244, 255)   # off-white notebook pages
SHADOW_COLOR   = (160, 145, 120, 80)    # warm shadow
COVER_COLOR    = (42, 42, 42, 255)      # near-black notebook cover
SPINE_COLOR    = (28, 28, 28, 255)      # spine
PAGE_COLOR     = (250, 246, 238, 255)   # page color
RULE_COLOR     = (200, 190, 175, 255)   # ruled line color
BULLET_COLOR   = (30, 30, 90, 255)      # dark blue ink bullet
INK_COLOR      = (35, 30, 25, 255)      # dark brown ink
LINE_COLOR     = (180, 168, 150, 200)   # ink line (semi-transparent)
BORDER_COLOR   = (20, 20, 20, 255)      # outer border


def blend_over(src_rgba, dst_rgba):
    """Alpha composite src over dst."""
    sr, sg, sb, sa = [c / 255.0 for c in src_rgba]
    dr, dg, db, da = [c / 255.0 for c in dst_rgba]
    out_a = sa + da * (1 - sa)
    if out_a < 1e-6:
        return (0, 0, 0, 0)
    out_r = (sr * sa + dr * da * (1 - sa)) / out_a
    out_g = (sg * sa + dg * da * (1 - sa)) / out_a
    out_b = (sb * sa + db * da * (1 - sa)) / out_a
    return (
        int(clamp(out_r * 255, 0, 255)),
        int(clamp(out_g * 255, 0, 255)),
        int(clamp(out_b * 255, 0, 255)),
        int(clamp(out_a * 255, 0, 255)),
    )


def draw_filled_rect(pixels, x0, y0, x1, y1, color, radius=0):
    """Fill an axis-aligned rectangle, optionally with rounded corners."""
    for y in range(max(0, y0), min(SIZE, y1)):
        for x in range(max(0, x0), min(SIZE, x1)):
            if radius > 0:
                cx = clamp(x, x0 + radius, x1 - radius)
                cy = clamp(y, y0 + radius, y1 - radius)
                d = dist(x, y, cx, cy)
                if d > radius:
                    continue
                alpha_factor = smooth_step(radius, radius - 1.5, d)
                r, g, b, a = color
                blended = blend_over((r, g, b, int(a * alpha_factor)), pixels[y * SIZE + x])
                pixels[y * SIZE + x] = blended
            else:
                pixels[y * SIZE + x] = blend_over(color, pixels[y * SIZE + x])


def draw_line_h(pixels, x0, x1, y, color, thickness=2):
    """Draw a horizontal line."""
    half = thickness // 2
    for dy in range(-half, half + 1):
        yy = y + dy
        if 0 <= yy < SIZE:
            for x in range(max(0, x0), min(SIZE, x1)):
                pixels[yy * SIZE + x] = blend_over(color, pixels[yy * SIZE + x])


def draw_circle_filled(pixels, cx, cy, radius, color):
    """Draw a filled anti-aliased circle."""
    for y in range(max(0, cy - radius - 2), min(SIZE, cy + radius + 2)):
        for x in range(max(0, cx - radius - 2), min(SIZE, cx + radius + 2)):
            d = dist(x, y, cx, cy)
            if d < radius - 1:
                pixels[y * SIZE + x] = blend_over(color, pixels[y * SIZE + x])
            elif d < radius + 1:
                alpha_factor = smooth_step(radius + 1, radius - 1, d)
                r, g, b, a = color
                blended = blend_over((r, g, b, int(a * alpha_factor)), pixels[y * SIZE + x])
                pixels[y * SIZE + x] = blended


def draw_circle_ring(pixels, cx, cy, outer_r, inner_r, color):
    """Draw a ring (hollow circle)."""
    for y in range(max(0, cy - outer_r - 2), min(SIZE, cy + outer_r + 2)):
        for x in range(max(0, cx - outer_r - 2), min(SIZE, cx + outer_r + 2)):
            d = dist(x, y, cx, cy)
            if inner_r < d < outer_r:
                # Anti-alias outer edge
                outer_aa = smooth_step(outer_r + 1, outer_r - 1, d)
                # Anti-alias inner edge
                inner_aa = smooth_step(inner_r - 1, inner_r + 1, d)
                alpha_factor = outer_aa * inner_aa
                r, g, b, a = color
                blended = blend_over((r, g, b, int(a * alpha_factor)), pixels[y * SIZE + x])
                pixels[y * SIZE + x] = blended


def draw_thick_line(pixels, x0, y0, x1, y1, color, thickness=3):
    """Draw a thick line using perpendicular offset."""
    dx = x1 - x0
    dy = y1 - y0
    length = math.sqrt(dx*dx + dy*dy)
    if length < 1:
        return
    nx = -dy / length
    ny = dx / length
    half = thickness / 2.0

    # Bounding box
    xs = sorted([x0, x1])
    ys = sorted([y0, y1])
    pad = int(half) + 2

    for y in range(max(0, ys[0] - pad), min(SIZE, ys[1] + pad)):
        for x in range(max(0, xs[0] - pad), min(SIZE, xs[1] + pad)):
            # Project point onto line
            px = x - x0
            py = y - y0
            t = clamp((px * dx + py * dy) / (length * length), 0, 1)
            # Closest point on segment
            cpx = x0 + t * dx
            cpy = y0 + t * dy
            d = dist(x, y, cpx, cpy)
            if d < half + 1:
                alpha_factor = smooth_step(half + 1, half - 0.5, d)
                r, g, b, a = color
                blended = blend_over((r, g, b, int(a * alpha_factor)), pixels[y * SIZE + x])
                pixels[y * SIZE + x] = blended


def main():
    pixels = [BG_COLOR] * (SIZE * SIZE)

    # --- Rounded square background (icon shape suggestion) ---
    # iOS clips to squircle automatically, but fill the background
    icon_radius = 220
    for y in range(SIZE):
        for x in range(SIZE):
            cx = clamp(x, icon_radius, SIZE - icon_radius)
            cy = clamp(y, icon_radius, SIZE - icon_radius)
            d = dist(x, y, cx, cy)
            if d > icon_radius:
                pixels[y * SIZE + x] = (0, 0, 0, 0)  # transparent corners

    # --- Notebook body ---
    # The notebook sits centered, slight perspective tilt
    NB_LEFT   = 220
    NB_RIGHT  = 804
    NB_TOP    = 180
    NB_BOTTOM = 844
    NB_RADIUS = 18
    SPINE_W   = 60

    # Drop shadow
    shadow_offset = 16
    draw_filled_rect(
        pixels,
        NB_LEFT + shadow_offset, NB_TOP + shadow_offset,
        NB_RIGHT + shadow_offset, NB_BOTTOM + shadow_offset,
        (100, 85, 65, 60), radius=NB_RADIUS + 4
    )

    # Cover (back + spine area, left side)
    draw_filled_rect(
        pixels,
        NB_LEFT, NB_TOP, NB_LEFT + SPINE_W, NB_BOTTOM,
        COVER_COLOR, radius=4
    )

    # Main cover rectangle
    draw_filled_rect(
        pixels,
        NB_LEFT, NB_TOP, NB_RIGHT, NB_BOTTOM,
        COVER_COLOR, radius=NB_RADIUS
    )

    # Page block (right of spine, slight inset)
    PAGE_LEFT   = NB_LEFT + SPINE_W + 4
    PAGE_RIGHT  = NB_RIGHT - 6
    PAGE_TOP    = NB_TOP + 6
    PAGE_BOTTOM = NB_BOTTOM - 6
    draw_filled_rect(
        pixels,
        PAGE_LEFT, PAGE_TOP, PAGE_RIGHT, PAGE_BOTTOM,
        PAGE_COLOR, radius=6
    )

    # Spine highlight line
    draw_thick_line(
        pixels,
        NB_LEFT + SPINE_W - 2, NB_TOP + 20,
        NB_LEFT + SPINE_W - 2, NB_BOTTOM - 20,
        (80, 75, 65, 180), thickness=3
    )

    # Spine groove lines (decorative)
    for i in range(3):
        yy = NB_TOP + 120 + i * 200
        draw_thick_line(
            pixels,
            NB_LEFT + 10, yy,
            NB_LEFT + SPINE_W - 10, yy,
            (70, 65, 55, 160), thickness=2
        )

    # Ruling lines on the page
    RULE_START_Y = PAGE_TOP + 80
    RULE_END_Y   = PAGE_BOTTOM - 60
    RULE_COUNT   = 12
    rule_step = (RULE_END_Y - RULE_START_Y) // RULE_COUNT
    for i in range(RULE_COUNT):
        ry = RULE_START_Y + i * rule_step
        draw_line_h(
            pixels,
            PAGE_LEFT + 20, PAGE_RIGHT - 20, ry,
            (195, 182, 162, 140), thickness=1
        )

    # Header line (thicker, for date)
    draw_line_h(
        pixels,
        PAGE_LEFT + 20, PAGE_RIGHT - 20,
        PAGE_TOP + 55,
        (170, 155, 130, 180), thickness=2
    )

    # "D" — date area squiggle (simulate handwritten date)
    date_y = PAGE_TOP + 36
    date_x = PAGE_LEFT + 30

    # Short date line (simulating "Mon 12" text)
    draw_thick_line(
        pixels, date_x, date_y, date_x + 110, date_y,
        (80, 70, 50, 160), thickness=3
    )
    draw_thick_line(
        pixels, date_x, date_y + 14, date_x + 68, date_y + 14,
        (80, 70, 50, 100), thickness=2
    )

    # --- Bullet point entries on the page ---
    # Entry 1: task bullet (•) + short line (completed)
    entry_x = PAGE_LEFT + 22
    entries = [
        (RULE_START_Y + rule_step * 1 - 6, "task", True),   # completed task
        (RULE_START_Y + rule_step * 3 - 6, "event", False),  # event
        (RULE_START_Y + rule_step * 5 - 6, "note", False),   # note
        (RULE_START_Y + rule_step * 7 - 6, "task", False),   # open task
    ]

    # Bullet symbols drawn as shapes
    for (ey, btype, done) in entries:
        bx = entry_x + 8
        by = ey

        if btype == "task":
            # Filled circle (bullet •)
            bcolor = (30, 30, 100, 220) if not done else (120, 115, 100, 150)
            draw_circle_filled(pixels, bx, by, 7, bcolor)
            if done:
                # Strikethrough on text line
                draw_thick_line(
                    pixels,
                    bx + 18, by, bx + 120, by,
                    (100, 90, 75, 120), thickness=2
                )
                draw_thick_line(
                    pixels,
                    bx + 18, by, bx + 120, by,
                    (90, 80, 65, 80), thickness=5
                )
            else:
                # Text line
                draw_thick_line(
                    pixels,
                    bx + 18, by, bx + 140, by,
                    (60, 50, 35, 120), thickness=2
                )

        elif btype == "event":
            # Open circle (○)
            draw_circle_ring(pixels, bx, by, 8, 5, (25, 100, 55, 210))
            draw_thick_line(
                pixels,
                bx + 18, by, bx + 105, by,
                (40, 100, 60, 100), thickness=2
            )

        elif btype == "note":
            # Dash (–)
            draw_thick_line(
                pixels,
                bx - 7, by, bx + 7, by,
                (110, 75, 25, 220), thickness=4
            )
            draw_thick_line(
                pixels,
                bx + 18, by, bx + 160, by,
                (60, 45, 20, 100), thickness=2
            )

    # --- Large central bullet symbol (prominent •) ---
    # Draw a bold "•" in the center-right of the page
    BULL_CX = PAGE_LEFT + (PAGE_RIGHT - PAGE_LEFT) * 2 // 3
    BULL_CY = PAGE_TOP + (PAGE_BOTTOM - PAGE_TOP) // 2 + 30

    # Outer glow / halo
    draw_circle_filled(pixels, BULL_CX, BULL_CY, 88, (30, 30, 100, 18))
    draw_circle_filled(pixels, BULL_CX, BULL_CY, 72, (30, 30, 100, 25))

    # Main bullet dot
    draw_circle_filled(pixels, BULL_CX, BULL_CY, 60, (28, 28, 95, 230))
    draw_circle_filled(pixels, BULL_CX, BULL_CY, 54, (32, 32, 105, 255))

    # Highlight on bullet
    draw_circle_filled(pixels, BULL_CX - 16, BULL_CY - 16, 18, (80, 80, 160, 80))

    # --- Notebook border highlight (top edge) ---
    draw_thick_line(
        pixels,
        NB_LEFT + NB_RADIUS, NB_TOP + 2,
        NB_RIGHT - NB_RADIUS, NB_TOP + 2,
        (90, 85, 75, 70), thickness=2
    )

    # --- Outer thin border around entire icon area ---
    # Top
    draw_line_h(pixels, 0, SIZE, 0, BORDER_COLOR, thickness=3)
    # Bottom
    draw_line_h(pixels, 0, SIZE, SIZE - 2, BORDER_COLOR, thickness=3)
    # Left
    for y in range(SIZE):
        for x in range(3):
            pixels[y * SIZE + x] = blend_over(BORDER_COLOR, pixels[y * SIZE + x])
    # Right
    for y in range(SIZE):
        for x in range(SIZE - 3, SIZE):
            pixels[y * SIZE + x] = blend_over(BORDER_COLOR, pixels[y * SIZE + x])

    write_png(
        '/home/user/daily-ideas/04-recto/ios/Recto/Assets.xcassets/AppIcon.appiconset/Icon.png',
        SIZE, SIZE, pixels
    )
    print("Icon.png written successfully (1024x1024 RGBA PNG)")


if __name__ == '__main__':
    main()
