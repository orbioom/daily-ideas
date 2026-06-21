#!/usr/bin/env python3
"""
Generate 1024x1024 PNG AppIcon for Alley bowling app.
Dark red background, white bowling ball with finger holes,
white bowling pins in triangle formation.
Uses only Python stdlib: struct, zlib, math.
"""
import struct
import zlib
import math

WIDTH = 1024
HEIGHT = 1024

def make_png(pixels):
    """
    pixels: flat list of (R, G, B, A) tuples, row-major, top to bottom.
    Returns bytes of a valid PNG file.
    """
    def pack_chunk(chunk_type, data):
        length = struct.pack('>I', len(data))
        body = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(body) & 0xFFFFFFFF)
        return length + body + crc

    # PNG signature
    sig = b'\x89PNG\r\n\x1a\n'

    # IHDR
    ihdr_data = struct.pack('>IIBBBBB', WIDTH, HEIGHT, 8, 2, 0, 0, 0)
    ihdr = pack_chunk(b'IHDR', ihdr_data)

    # Build raw image data (filter byte 0 = None per scanline)
    raw_rows = []
    for y in range(HEIGHT):
        row = bytearray()
        row.append(0)  # filter type None
        for x in range(WIDTH):
            r, g, b, a = pixels[y * WIDTH + x]
            row.append(r)
            row.append(g)
            row.append(b)
        raw_rows.append(bytes(row))

    raw_data = b''.join(raw_rows)
    compressed = zlib.compress(raw_data, 9)
    idat = pack_chunk(b'IDAT', compressed)

    # IEND
    iend = pack_chunk(b'IEND', b'')

    return sig + ihdr + idat + iend


def clamp(v):
    return max(0, min(255, int(v)))


def blend(bg, fg_r, fg_g, fg_b, fg_a):
    """Alpha blend fg over bg (all 0-255)."""
    a = fg_a / 255.0
    r = clamp(fg_r * a + bg[0] * (1 - a))
    g = clamp(fg_g * a + bg[1] * (1 - a))
    b = clamp(fg_b * a + bg[2] * (1 - a))
    return (r, g, b, 255)


def draw_circle_aa(pixels, cx, cy, radius, r, g, b, a=255, fill=True, stroke_width=0, sr=0, sg=0, sb=0):
    """Draw an anti-aliased filled circle with optional stroke."""
    iy_min = max(0, int(cy - radius - stroke_width - 2))
    iy_max = min(HEIGHT - 1, int(cy + radius + stroke_width + 2))
    ix_min = max(0, int(cx - radius - stroke_width - 2))
    ix_max = min(WIDTH - 1, int(cx + radius + stroke_width + 2))

    outer_r = radius + stroke_width
    inner_r = radius

    for py in range(iy_min, iy_max + 1):
        for px in range(ix_min, ix_max + 1):
            dx = px - cx
            dy = py - cy
            dist = math.sqrt(dx * dx + dy * dy)

            bg = pixels[py * WIDTH + px]

            if stroke_width > 0:
                # Stroke ring
                if inner_r - 1 < dist < outer_r + 1:
                    # Anti-alias the outer edge
                    outer_alpha = clamp(255 * (1 - max(0, dist - outer_r)))
                    inner_alpha = clamp(255 * (1 - max(0, inner_r - dist)))
                    ring_alpha = min(outer_alpha, inner_alpha)
                    if ring_alpha > 0:
                        pixels[py * WIDTH + px] = blend(bg, sr, sg, sb, ring_alpha)
                        bg = pixels[py * WIDTH + px]

            if fill and dist <= inner_r + 1:
                fill_alpha = clamp(255 * (1 - max(0, dist - inner_r + 1)))
                if fill_alpha > 0:
                    pixels[py * WIDTH + px] = blend(bg, r, g, b, fill_alpha)


def draw_rounded_rect(pixels, x1, y1, x2, y2, corner_r, r, g, b, a=255):
    """Draw a filled rounded rectangle."""
    for py in range(max(0, int(y1)), min(HEIGHT, int(y2) + 1)):
        for px in range(max(0, int(x1)), min(WIDTH, int(x2) + 1)):
            dx = max(0, x1 + corner_r - px, px - (x2 - corner_r))
            dy = max(0, y1 + corner_r - py, py - (y2 - corner_r))
            dist = math.sqrt(dx * dx + dy * dy)
            alpha_f = clamp(255 * (1 - max(0, dist - corner_r + 1)))
            if alpha_f > 0:
                bg = pixels[py * WIDTH + px]
                pixels[py * WIDTH + px] = blend(bg, r, g, b, alpha_f)


def draw_finger_hole(pixels, cx, cy, radius):
    """Draw a dark finger hole on the bowling ball."""
    # Shadow ring (slightly larger, dark grey)
    draw_circle_aa(pixels, cx, cy, radius + 4, 30, 10, 10, 180)
    # Hole itself (very dark)
    draw_circle_aa(pixels, cx, cy, radius, 20, 8, 8, 255)
    # Subtle highlight at top-left
    draw_circle_aa(pixels, cx - radius * 0.3, cy - radius * 0.3, radius * 0.35, 80, 30, 30, 120)


def main():
    # Background: gradient from dark-red top to very-dark bottom
    BG_TOP = (0.22, 0.04, 0.04)       # dark crimson
    BG_BOT = (0.08, 0.02, 0.02)       # almost black

    pixels = []
    for y in range(HEIGHT):
        t = y / HEIGHT
        r = clamp((BG_TOP[0] * (1 - t) + BG_BOT[0] * t) * 255)
        g = clamp((BG_TOP[1] * (1 - t) + BG_BOT[1] * t) * 255)
        b = clamp((BG_TOP[2] * (1 - t) + BG_BOT[2] * t) * 255)
        for x in range(WIDTH):
            pixels.append((r, g, b, 255))

    # Subtle radial vignette darkening at corners
    CX, CY = WIDTH / 2, HEIGHT / 2
    max_d = math.sqrt(CX * CX + CY * CY)
    for y in range(HEIGHT):
        for x in range(WIDTH):
            dx = x - CX
            dy = y - CY
            d = math.sqrt(dx * dx + dy * dy)
            t_v = (d / max_d) ** 1.8
            dark = clamp(t_v * 60)
            p = pixels[y * WIDTH + x]
            pixels[y * WIDTH + x] = (
                max(0, p[0] - dark),
                max(0, p[1] - dark),
                max(0, p[2] - dark),
                255
            )

    # ─── Bowling Ball ─────────────────────────────────────────────────────────
    # Large white circle, left-center, slightly offset left
    BALL_CX = WIDTH * 0.42
    BALL_CY = HEIGHT * 0.50
    BALL_R = WIDTH * 0.285

    # Ball shadow
    draw_circle_aa(pixels, BALL_CX + 18, BALL_CY + 18, BALL_R + 4, 0, 0, 0, 90)

    # Ball body: off-white / pearl
    draw_circle_aa(pixels, BALL_CX, BALL_CY, BALL_R, 240, 238, 235, 255)

    # Subtle shading pass: darken bottom-right of ball
    for y in range(HEIGHT):
        for x in range(WIDTH):
            dx = x - BALL_CX
            dy = y - BALL_CY
            d = math.sqrt(dx * dx + dy * dy)
            if d <= BALL_R - 1:
                # shade towards lower-right
                shade = max(0.0, (dx + dy) / (BALL_R * 2))
                dark = int(shade * 40)
                p = pixels[y * WIDTH + x]
                pixels[y * WIDTH + x] = (
                    max(0, p[0] - dark),
                    max(0, p[1] - dark),
                    max(0, p[2] - dark),
                    255
                )

    # Highlight on upper-left of ball
    draw_circle_aa(pixels,
                   BALL_CX - BALL_R * 0.30,
                   BALL_CY - BALL_R * 0.30,
                   BALL_R * 0.40,
                   255, 255, 255, 60)

    # Three finger holes arranged in standard triangle layout
    HOLE_R = BALL_R * 0.085
    # Thumb hole (lower-center)
    THUMB_CX = BALL_CX + BALL_R * 0.08
    THUMB_CY = BALL_CY + BALL_R * 0.30
    draw_finger_hole(pixels, THUMB_CX, THUMB_CY, HOLE_R)

    # Middle finger (upper-left)
    MID_CX = BALL_CX - BALL_R * 0.16
    MID_CY = BALL_CY - BALL_R * 0.12
    draw_finger_hole(pixels, MID_CX, MID_CY, HOLE_R * 0.85)

    # Ring finger (upper-right)
    RING_CX = BALL_CX + BALL_R * 0.14
    RING_CY = BALL_CY - BALL_R * 0.14
    draw_finger_hole(pixels, RING_CX, RING_CY, HOLE_R * 0.85)

    # ─── Bowling Pins (right side, triangle of 10) ───────────────────────────
    # Pin dimensions
    PIN_R = WIDTH * 0.028
    # Row spacing (lower rows toward bottom, pin 1 at front = lowest)
    # Standard layout: 4-3-2-1 rows from back to front
    # We place them on the right half

    PIN_BASE_X = WIDTH * 0.725
    PIN_BASE_Y = HEIGHT * 0.62
    ROW_DX = PIN_R * 2.4    # horizontal gap
    ROW_DY = PIN_R * 2.8    # vertical gap between rows

    # Pin positions: row 0 (back, 4 pins) to row 3 (front, 1 pin)
    pin_rows = [4, 3, 2, 1]
    pin_positions = []
    for row_i, count in enumerate(pin_rows):
        row_y = PIN_BASE_Y - row_i * ROW_DY
        row_x_start = PIN_BASE_X - (count - 1) * ROW_DX / 2
        for col in range(count):
            px = row_x_start + col * ROW_DX
            py = row_y
            pin_positions.append((px, py))

    for (px, py) in pin_positions:
        # Pin shadow
        draw_circle_aa(pixels, px + 6, py + 6, PIN_R, 0, 0, 0, 80)
        # Pin body: white
        draw_circle_aa(pixels, px, py, PIN_R, 248, 246, 244, 255)
        # Pin highlight
        draw_circle_aa(pixels,
                       px - PIN_R * 0.28,
                       py - PIN_R * 0.28,
                       PIN_R * 0.35,
                       255, 255, 255, 100)

    # ─── App name strip (optional subtle text-like decoration) ────────────────
    # Small red stripe at bottom of icon for brand color anchor
    STRIPE_H = 48
    for y in range(HEIGHT - STRIPE_H, HEIGHT):
        for x in range(WIDTH):
            t_x = x / WIDTH
            # gradient from crimson to dark red
            stripe_r = clamp(180 * (1 - t_x * 0.3))
            stripe_g = clamp(20)
            stripe_b = clamp(20)
            alpha = 200
            bg = pixels[y * WIDTH + x]
            pixels[y * WIDTH + x] = blend(bg, stripe_r, stripe_g, stripe_b, alpha)

    # Write PNG
    output_path = '/home/user/daily-ideas/05-alley/ios/Alley/Assets.xcassets/AppIcon.appiconset/Icon.png'
    png_bytes = make_png(pixels)
    with open(output_path, 'wb') as f:
        f.write(png_bytes)

    print(f"Icon generated: {len(png_bytes):,} bytes -> {output_path}")


if __name__ == '__main__':
    main()
