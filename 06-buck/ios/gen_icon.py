#!/usr/bin/env python3
"""
Generate a 1024x1024 AppIcon PNG for Buck (Euchre game).
Design: Deep red background, large white "J" (Jack/Bower) in center,
small spade symbols in the four corners.
Uses only Python stdlib: struct, zlib, math.
"""
import struct
import zlib
import math

WIDTH = 1024
HEIGHT = 1024

def make_png(pixels):
    """
    pixels: flat list of (r, g, b, a) tuples, row-major top-to-bottom.
    Returns PNG bytes.
    """
    def u32be(n):
        return struct.pack(">I", n)

    def chunk(tag, data):
        c = tag + data
        return u32be(len(data)) + c + u32be(zlib.crc32(c) & 0xFFFFFFFF)

    # IHDR
    ihdr_data = u32be(WIDTH) + u32be(HEIGHT) + bytes([8, 2, 0, 0, 0])  # 8-bit RGB
    # Convert to RGB (drop alpha for simplicity — background is opaque)
    raw_rows = []
    for y in range(HEIGHT):
        row = bytearray([0])  # filter type None
        for x in range(WIDTH):
            idx = y * WIDTH + x
            r, g, b, a = pixels[idx]
            # Alpha blend against white background
            r2 = min(255, max(0, int(r * a / 255 + 255 * (255 - a) / 255)))
            g2 = min(255, max(0, int(g * a / 255 + 255 * (255 - a) / 255)))
            b2 = min(255, max(0, int(b * a / 255 + 255 * (255 - a) / 255)))
            row += bytes([r2, g2, b2])
        raw_rows.append(bytes(row))

    compressed = zlib.compress(b"".join(raw_rows), 9)
    idat_data = compressed

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", ihdr_data)
    png += chunk(b"IDAT", idat_data)
    png += chunk(b"IEND", b"")
    return png


def draw_filled_circle(pixels, cx, cy, r, color):
    """Fill a circle."""
    r2 = r * r
    x0 = max(0, cx - r)
    x1 = min(WIDTH - 1, cx + r)
    y0 = max(0, cy - r)
    y1 = min(HEIGHT - 1, cy + r)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            dx = x - cx
            dy = y - cy
            if dx * dx + dy * dy <= r2:
                pixels[y * WIDTH + x] = color


def blend_pixel(pixels, x, y, color, alpha_override=None):
    """Blend color onto pixel at (x,y) with alpha."""
    if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT:
        return
    r, g, b, a = color
    if alpha_override is not None:
        a = alpha_override
    br, bg, bb, ba = pixels[y * WIDTH + x]
    # Simple alpha composite
    na = a + ba * (255 - a) // 255
    if na == 0:
        return
    nr = (r * a + br * ba * (255 - a) // 255) // na
    ng = (g * a + bg * ba * (255 - a) // 255) // na
    nb = (b * a + bb * ba * (255 - a) // 255) // na
    pixels[y * WIDTH + x] = (nr, ng, nb, na)


def draw_aa_circle(pixels, cx, cy, r, color):
    """Draw a filled anti-aliased circle."""
    r_outer = r
    r_inner = r - 1.5
    x0 = max(0, int(cx - r_outer) - 1)
    x1 = min(WIDTH - 1, int(cx + r_outer) + 1)
    y0 = max(0, int(cy - r_outer) - 1)
    y1 = min(HEIGHT - 1, int(cy + r_outer) + 1)
    cr, cg, cb, ca = color
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if dist <= r_inner:
                pixels[y * WIDTH + x] = color
            elif dist <= r_outer:
                alpha = int(ca * (r_outer - dist))
                blend_pixel(pixels, x, y, (cr, cg, cb, alpha))


def draw_rect(pixels, x0, y0, x1, y1, color):
    """Fill a rectangle."""
    for y in range(max(0, y0), min(HEIGHT, y1 + 1)):
        for x in range(max(0, x0), min(WIDTH, x1 + 1)):
            pixels[y * WIDTH + x] = color


def draw_rounded_rect(pixels, x0, y0, x1, y1, radius, color):
    """Fill a rounded rectangle."""
    # Fill center strips
    draw_rect(pixels, x0 + radius, y0, x1 - radius, y1, color)
    draw_rect(pixels, x0, y0 + radius, x1, y1 - radius, color)
    # Four corner circles
    draw_filled_circle(pixels, x0 + radius, y0 + radius, radius, color)
    draw_filled_circle(pixels, x1 - radius, y0 + radius, radius, color)
    draw_filled_circle(pixels, x0 + radius, y1 - radius, radius, color)
    draw_filled_circle(pixels, x1 - radius, y1 - radius, radius, color)


def rasterize_glyph_J(pixels, cx, cy, font_size, color):
    """
    Draw a simplified bold 'J' glyph using rectangles and circles.
    font_size is approximate cap height in pixels.
    """
    stroke = max(6, font_size // 7)
    cap_h = font_size
    # Vertical bar: right side of J
    bar_x = cx + font_size // 6
    top_y = cy - cap_h // 2
    bot_y = cy + cap_h // 2
    draw_rect(pixels, bar_x - stroke, top_y, bar_x + stroke, bot_y, color)
    # Top horizontal serif
    draw_rect(pixels, cx - font_size // 4, top_y, bar_x + stroke, top_y + stroke * 2, color)
    # Bottom hook: a half-circle going left
    hook_r = font_size // 4
    hook_cx = bar_x - hook_r
    hook_cy = bot_y - hook_r
    # Draw quarter-circle arc by brute force
    for angle_deg in range(90, 271):
        angle = math.radians(angle_deg)
        for rr in range(hook_r - stroke, hook_r + stroke + 1):
            hx = int(hook_cx + rr * math.cos(angle))
            hy = int(hook_cy + rr * math.sin(angle))
            if 0 <= hx < WIDTH and 0 <= hy < HEIGHT:
                pixels[hy * WIDTH + hx] = color


def rasterize_glyph_J_solid(pixels, cx, cy, font_size, color):
    """
    Draw a bold 'J' using filled shapes — solid approach.
    """
    stroke = max(10, font_size // 6)
    half_h = font_size // 2
    top_y = cy - half_h
    bot_y = cy + half_h
    bar_x = cx + stroke // 2

    # Vertical bar
    draw_rect(pixels,
              bar_x - stroke, top_y,
              bar_x + stroke, bot_y,
              color)

    # Top serif
    draw_rect(pixels,
              cx - font_size // 3, top_y,
              bar_x + stroke, top_y + stroke * 2,
              color)

    # Bottom curve going left: fill using circle sector
    hook_r = font_size // 3
    hook_cx = bar_x - hook_r
    hook_cy = bot_y - hook_r

    # Fill the hook area
    for y in range(hook_cy - hook_r - stroke, hook_cy + hook_r + stroke + 1):
        for x in range(hook_cx - hook_r - stroke, hook_cx + hook_r + stroke + 1):
            if 0 <= x < WIDTH and 0 <= y < HEIGHT:
                dx = x - hook_cx
                dy = y - hook_cy
                dist = math.sqrt(dx * dx + dy * dy)
                # Ring: between inner and outer radius
                in_ring = (hook_r - stroke) <= dist <= (hook_r + stroke)
                # Only the bottom-left quadrant and below
                in_arc = dy >= -stroke  # bottom half and a bit above
                if in_ring and in_arc:
                    pixels[y * WIDTH + x] = color
                # Fill left cap of the hook
                if dist <= hook_r + stroke and dy >= hook_r - stroke and x <= hook_cx:
                    draw_filled = True
                    # Check it's not in the "inside" of hook where bar continues
                    if x >= hook_cx - stroke and dy <= 0:
                        draw_filled = False
                    if draw_filled:
                        pixels[y * WIDTH + x] = color


def draw_spade(pixels, cx, cy, size, color):
    """
    Draw a spade suit symbol (♠) centered at cx,cy with given size.
    Approximated with geometric shapes.
    """
    # Spade = upside-down heart on top + small triangle handle
    # Upper circle pair
    r = size // 3
    # Left lobe
    draw_aa_circle(pixels, cx - r // 2, cy, r, color)
    # Right lobe
    draw_aa_circle(pixels, cx + r // 2, cy, r, color)
    # Top point (triangle)
    tip_y = cy - size // 2
    mid_y = cy
    for y in range(tip_y, mid_y):
        ratio = (y - tip_y) / max(1, mid_y - tip_y)
        half_w = int(ratio * size * 0.55)
        for x in range(cx - half_w, cx + half_w + 1):
            if 0 <= x < WIDTH and 0 <= y < HEIGHT:
                pixels[y * WIDTH + x] = color
    # Stem
    stem_w = max(2, size // 8)
    stem_h = size // 3
    draw_rect(pixels,
              cx - stem_w, cy + r - stem_w,
              cx + stem_w, cy + r - stem_w + stem_h,
              color)
    # Base of stem (wider)
    draw_rect(pixels,
              cx - size // 3, cy + r - stem_w + stem_h - stem_w,
              cx + size // 3, cy + r - stem_w + stem_h,
              color)


def main():
    # Background: deep red
    BG = (140, 25, 25, 255)
    WHITE = (255, 255, 255, 255)
    GOLD = (217, 183, 76, 255)
    SHADOW = (0, 0, 0, 80)

    # Initialize canvas with background color
    pixels = [BG] * (WIDTH * HEIGHT)

    # Add subtle radial gradient darkening at corners
    cx_bg = WIDTH // 2
    cy_bg = HEIGHT // 2
    max_dist = math.sqrt(cx_bg ** 2 + cy_bg ** 2)
    for y in range(0, HEIGHT, 2):
        for x in range(0, WIDTH, 2):
            dx = x - cx_bg
            dy = y - cy_bg
            dist = math.sqrt(dx * dx + dy * dy)
            ratio = dist / max_dist
            darkness = int(40 * ratio * ratio)
            r = max(0, BG[0] - darkness)
            g = max(0, BG[1] - darkness)
            b = max(0, BG[2] - darkness)
            pixels[y * WIDTH + x] = (r, g, b, 255)
            if x + 1 < WIDTH:
                pixels[y * WIDTH + x + 1] = (r, g, b, 255)
            if y + 1 < HEIGHT:
                pixels[(y + 1) * WIDTH + x] = (r, g, b, 255)
            if x + 1 < WIDTH and y + 1 < HEIGHT:
                pixels[(y + 1) * WIDTH + x + 1] = (r, g, b, 255)

    # Draw a white rounded-rect card outline in center for visual grounding
    card_w = 580
    card_h = 700
    card_x0 = WIDTH // 2 - card_w // 2
    card_y0 = HEIGHT // 2 - card_h // 2
    card_x1 = card_x0 + card_w
    card_y1 = card_y0 + card_h
    draw_rounded_rect(pixels, card_x0, card_y0, card_x1, card_y1, 60, (255, 255, 255, 255))

    # Draw red "J" on white card using thick strokes
    J_COLOR = (140, 25, 25, 255)
    font_size = 320
    j_cx = WIDTH // 2
    j_cy = HEIGHT // 2

    # Vertical stem of J (right side)
    stroke = 48
    half_h = font_size // 2
    top_y = j_cy - half_h - 20
    bot_y = j_cy + half_h
    bar_x = j_cx + 45

    draw_rect(pixels, bar_x - stroke, top_y, bar_x + stroke, bot_y, J_COLOR)

    # Top horizontal bar
    draw_rect(pixels, j_cx - 100, top_y, bar_x + stroke, top_y + stroke * 2, J_COLOR)

    # Bottom hook — quarter circle curving left and down
    hook_r = 120
    hook_cx = bar_x - hook_r
    hook_cy = bot_y - hook_r
    for angle_deg in range(0, 361):
        angle = math.radians(angle_deg)
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)
        # Only draw the bottom-left arc (180 to 270 degrees = cos<=0, sin>=0 area + small range)
        if not (cos_a <= 0.2 and sin_a >= -0.2):
            continue
        for rr in range(hook_r - stroke, hook_r + stroke + 1):
            hx = int(hook_cx + rr * cos_a)
            hy = int(hook_cy + rr * sin_a)
            if 0 <= hx < WIDTH and 0 <= hy < HEIGHT:
                pixels[hy * WIDTH + hx] = J_COLOR

    # Fill the hook interior cap (the curved end of J)
    for y in range(hook_cy, hook_cy + hook_r + stroke + 1):
        for x in range(hook_cx - hook_r - stroke, hook_cx + 1):
            if 0 <= x < WIDTH and 0 <= y < HEIGHT:
                dx = x - hook_cx
                dy = y - hook_cy
                dist = math.sqrt(dx * dx + dy * dy)
                if hook_r - stroke <= dist <= hook_r + stroke:
                    pixels[y * WIDTH + x] = J_COLOR

    # Connect the vertical bar down into the hook arc
    draw_rect(pixels,
              bar_x - stroke, bot_y - hook_r,
              bar_x + stroke, bot_y,
              J_COLOR)

    # Small spade symbols in the four card corners
    spade_size = 60
    margin = 90
    corners = [
        (card_x0 + margin, card_y0 + margin),
        (card_x1 - margin, card_y0 + margin),
        (card_x0 + margin, card_y1 - margin),
        (card_x1 - margin, card_y1 - margin),
    ]
    for (scx, scy) in corners:
        draw_spade(pixels, scx, scy, spade_size, J_COLOR)

    # Write PNG
    out_path = "/home/user/daily-ideas/06-buck/ios/Buck/Assets.xcassets/AppIcon.appiconset/Icon.png"
    png_bytes = make_png(pixels)
    with open(out_path, "wb") as f:
        f.write(png_bytes)
    print(f"Written {len(png_bytes)} bytes to {out_path}")
    print(f"Image size: {WIDTH}x{HEIGHT}")


if __name__ == "__main__":
    main()
