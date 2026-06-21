#!/usr/bin/env python3
"""
Generate a 1024x1024 AppIcon for Count (Blackjack Strategy Trainer).
Design: dark casino-felt green background, white spade symbol, white "21" text.
Uses only Python stdlib: struct, zlib, math.
"""
import struct
import zlib
import math

SIZE = 1024

def make_png(width, height, pixels):
    """Create PNG bytes from a flat list of (R, G, B, A) tuples."""
    def pack_chunk(chunk_type, data):
        length = struct.pack(">I", len(data))
        crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
        return length + chunk_type + data + struct.pack(">I", crc)

    signature = b"\x89PNG\r\n\x1a\n"
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    ihdr = pack_chunk(b"IHDR", ihdr_data)

    raw_rows = []
    for y in range(height):
        row = b"\x00"
        for x in range(width):
            r, g, b, _ = pixels[y * width + x]
            row += bytes([r, g, b])
        raw_rows.append(row)

    raw_data = b"".join(raw_rows)
    compressed = zlib.compress(raw_data, 9)
    idat = pack_chunk(b"IDAT", compressed)
    iend = pack_chunk(b"IEND", b"")

    return signature + ihdr + idat + iend


def lerp(a, b, t):
    return a + (b - a) * t


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def fill_bg(pixels, width, height):
    """Dark green felt gradient background with subtle texture."""
    for y in range(height):
        for x in range(width):
            # radial gradient from center: lighter in center, darker at edges
            cx = x / width - 0.5
            cy = y / height - 0.5
            dist = math.sqrt(cx * cx + cy * cy) * 2.0  # 0..~1.4

            # base dark casino felt green
            r_base, g_base, b_base = 22, 74, 26
            # lighter center
            r_light, g_light, b_light = 32, 98, 36
            t = clamp(1.0 - dist, 0.0, 1.0)
            t = t * t  # ease

            r = int(lerp(r_base, r_light, t))
            g = int(lerp(g_base, g_light, t))
            b = int(lerp(b_base, b_light, t))
            pixels[y * width + x] = (r, g, b, 255)


def sdf_rounded_rect(px, py, cx, cy, hw, hh, r):
    """Signed distance field for rounded rectangle."""
    dx = abs(px - cx) - hw + r
    dy = abs(py - cy) - hh + r
    return math.sqrt(max(dx, 0) ** 2 + max(dy, 0) ** 2) - r


def draw_felt_border(pixels, width, height):
    """Draw a subtle lighter border/frame like a casino table."""
    border = 40
    for y in range(height):
        for x in range(width):
            d = sdf_rounded_rect(x, y, width // 2, height // 2, width // 2 - border, height // 2 - border, 80)
            # outer ring
            if 0 <= d <= 20:
                alpha = clamp(1.0 - d / 20.0, 0.0, 1.0) * 0.18
                r, g, b, a = pixels[y * width + x]
                r = int(r + (255 - r) * alpha)
                g = int(g + (255 - g) * alpha)
                b = int(b + (255 - b) * alpha)
                pixels[y * width + x] = (r, g, b, 255)


def spade_alpha(px, py, cx, cy, scale):
    """
    Compute a coverage value [0..1] for a spade glyph centered at (cx,cy).
    The spade is composed of:
      - Three overlapping circles (left lobe, right lobe, top circle)
      - A triangle/stem pointing down
    All coordinates are in a [-1..1] normalized space scaled by `scale`.
    """
    # Normalize
    nx = (px - cx) / scale
    ny = (py - cy) / scale  # +y = down in screen space

    # --- Top circle (the round top of the spade) ---
    # center at (0, -0.30), radius 0.42
    dx0 = nx - 0.0
    dy0 = ny - (-0.30)
    d_top = math.sqrt(dx0 * dx0 + dy0 * dy0) - 0.42

    # --- Left lobe ---
    # center at (-0.32, 0.10), radius 0.34
    dx1 = nx - (-0.32)
    dy1 = ny - 0.10
    d_left = math.sqrt(dx1 * dx1 + dy1 * dy1) - 0.34

    # --- Right lobe ---
    dx2 = nx - 0.32
    dy2 = ny - 0.10
    d_right = math.sqrt(dx2 * dx2 + dy2 * dy2) - 0.34

    # Union of the three circles
    d_body = min(d_top, d_left, d_right)

    # --- Stem: a thin rounded rect going down ---
    # from y=0.44 to y=0.72, width 0.13
    stem_hw = 0.13
    stem_top = 0.44
    stem_bot = 0.72
    stem_cy = (stem_top + stem_bot) / 2.0
    stem_hh = (stem_bot - stem_top) / 2.0
    sdx = abs(nx) - stem_hw
    sdy = abs(ny - stem_cy) - stem_hh
    d_stem_inner = math.sqrt(max(sdx, 0) ** 2 + max(sdy, 0) ** 2) - 0.04
    if sdx < 0 and sdy < 0:
        d_stem_inner = max(sdx, sdy)

    # --- Base triangle/flare at bottom of stem ---
    # A triangle from (-0.32, 0.72) to (0.32, 0.72) to (0, 0.42)
    # We approximate as: inside if ny > 0.42 and |nx| < lerp(0.0, 0.32, (ny-0.42)/(0.72-0.42))
    d_base = 1.0
    if ny > 0.42 and ny < 0.74:
        t = (ny - 0.42) / (0.72 - 0.42)
        half_w = 0.32 * clamp(t, 0, 1)
        d_base = abs(nx) - half_w

    # Union of stem and base
    d_stem = min(d_stem_inner, d_base)

    # Full spade = union of body and stem
    d = min(d_body, d_stem)

    # Anti-alias over ~2 pixels
    aa = 2.0 / scale
    return clamp(1.0 - d / aa, 0.0, 1.0)


def draw_spade(pixels, width, height, cx, cy, scale, color=(255, 255, 255)):
    """Draw a white spade symbol with anti-aliasing."""
    r0, g0, b0 = color
    half = int(scale * 1.1)
    x0 = max(0, int(cx - half))
    x1 = min(width, int(cx + half))
    y0 = max(0, int(cy - half))
    y1 = min(height, int(cy + half))
    for y in range(y0, y1):
        for x in range(x0, x1):
            alpha = spade_alpha(x + 0.5, y + 0.5, cx, cy, scale)
            if alpha > 0:
                br, bg, bb, ba = pixels[y * width + x]
                na = alpha
                pixels[y * width + x] = (
                    int(br * (1 - na) + r0 * na),
                    int(bg * (1 - na) + g0 * na),
                    int(bb * (1 - na) + b0 * na),
                    255
                )


def draw_circle_aa(pixels, width, height, cx, cy, radius, color, thickness=2):
    """Draw an anti-aliased circle outline."""
    r0, g0, b0, a0 = color
    r_int = int(radius + thickness + 2)
    for dy in range(-r_int, r_int + 1):
        for dx in range(-r_int, r_int + 1):
            x = int(cx + dx)
            y = int(cy + dy)
            if 0 <= x < width and 0 <= y < height:
                d = math.sqrt(dx * dx + dy * dy)
                dist_to_ring = abs(d - radius)
                if dist_to_ring < thickness + 1:
                    alpha = clamp(1.0 - max(dist_to_ring - thickness, 0), 0, 1) * (a0 / 255.0)
                    br, bg, bb, ba = pixels[y * width + x]
                    pixels[y * width + x] = (
                        int(br * (1 - alpha) + r0 * alpha),
                        int(bg * (1 - alpha) + g0 * alpha),
                        int(bb * (1 - alpha) + b0 * alpha),
                        255
                    )


def draw_filled_circle(pixels, width, height, cx, cy, radius, color):
    """Draw a filled anti-aliased circle."""
    r0, g0, b0, a0 = color
    r_int = int(radius + 2)
    for dy in range(-r_int, r_int + 1):
        for dx in range(-r_int, r_int + 1):
            x = int(cx + dx)
            y = int(cy + dy)
            if 0 <= x < width and 0 <= y < height:
                d = math.sqrt(dx * dx + dy * dy)
                alpha = clamp(1.0 - (d - radius), 0, 1) * (a0 / 255.0)
                if alpha > 0:
                    br, bg, bb, ba = pixels[y * width + x]
                    pixels[y * width + x] = (
                        int(br * (1 - alpha) + r0 * alpha),
                        int(bg * (1 - alpha) + g0 * alpha),
                        int(bb * (1 - alpha) + b0 * alpha),
                        255
                    )


# --- Rasterize digit glyphs ---
# Each glyph is defined as a list of (x,y,w,h) rectangles in a 5x7 grid.
# Normalized: x,y,w,h in [0..1] relative to a cell of (glyph_w x glyph_h)

GLYPHS = {
    '2': [
        # top horizontal
        (0.1, 0.0, 0.8, 0.15),
        # top-right vertical
        (0.75, 0.05, 0.15, 0.42),
        # middle horizontal
        (0.1, 0.42, 0.8, 0.15),
        # bottom-left vertical
        (0.1, 0.57, 0.15, 0.35),
        # bottom horizontal
        (0.1, 0.85, 0.8, 0.15),
    ],
    '1': [
        # top-right diagonal / vertical
        (0.35, 0.0, 0.15, 1.0),
        # serif top-left
        (0.15, 0.10, 0.35, 0.14),
        # base
        (0.15, 0.86, 0.7, 0.14),
    ],
}


def draw_glyph(pixels, width, height, char, cx, cy, glyph_w, glyph_h, color=(255, 255, 255)):
    """Draw a glyph centered at (cx, cy) with given pixel dimensions."""
    r0, g0, b0 = color
    x0 = cx - glyph_w // 2
    y0 = cy - glyph_h // 2
    rects = GLYPHS.get(char, [])
    aa = 1.5  # anti-alias softness in pixels
    for (rx, ry, rw, rh) in rects:
        # rect in pixel space
        px0 = x0 + rx * glyph_w
        py0 = y0 + ry * glyph_h
        px1 = px0 + rw * glyph_w
        py1 = py0 + rh * glyph_h
        # expand bounding box by aa for smooth edges
        ix0 = max(0, int(px0 - aa))
        ix1 = min(width, int(px1 + aa) + 1)
        iy0 = max(0, int(py0 - aa))
        iy1 = min(height, int(py1 + aa) + 1)
        for y in range(iy0, iy1):
            for x in range(ix0, ix1):
                # coverage: how much of this pixel is inside the rect
                ox = max(0.0, min(px1, x + 1.0) - max(px0, float(x)))
                oy = max(0.0, min(py1, y + 1.0) - max(py0, float(y)))
                alpha = clamp(ox, 0, 1) * clamp(oy, 0, 1)
                if alpha > 0:
                    br, bg, bb, ba = pixels[y * width + x]
                    pixels[y * width + x] = (
                        int(br * (1 - alpha) + r0 * alpha),
                        int(bg * (1 - alpha) + g0 * alpha),
                        int(bb * (1 - alpha) + b0 * alpha),
                        255
                    )


def draw_text_21(pixels, width, height):
    """Draw '21' in large white text in the bottom-right area."""
    glyph_h = 160
    glyph_w = 90
    spacing = 20
    total_w = glyph_w * 2 + spacing

    # center of the "21" text block
    text_cx = int(width * 0.72)
    text_cy = int(height * 0.80)

    draw_glyph(pixels, width, height, '2',
               text_cx - glyph_w // 2 - spacing // 2,
               text_cy, glyph_w, glyph_h)
    draw_glyph(pixels, width, height, '1',
               text_cx + glyph_w // 2 + spacing // 2,
               text_cy, glyph_w, glyph_h)


def draw_corner_pip(pixels, width, height, value, suit_symbol):
    """Draw small card pip in top-left corner (decorative)."""
    # Just four small dots arranged in card-corner style
    dot_r = 12
    margin = 60
    colors = {
        'spade': (255, 255, 255, 200),
    }
    c = colors.get(suit_symbol, (255, 255, 255, 180))
    draw_filled_circle(pixels, width, height, margin, margin, dot_r, c)
    draw_filled_circle(pixels, width, height, width - margin, margin, dot_r, c)
    draw_filled_circle(pixels, width, height, margin, height - margin, dot_r, c)
    draw_filled_circle(pixels, width, height, width - margin, height - margin, dot_r, c)


def add_rounded_corners(pixels, width, height, radius):
    """Make corners transparent (rounded icon)."""
    for y in range(height):
        for x in range(width):
            # check distance to nearest corner
            dx = min(x, width - 1 - x)
            dy = min(y, height - 1 - y)
            if dx < radius and dy < radius:
                d = math.sqrt((dx - radius) ** 2 + (dy - radius) ** 2)
                if d > radius:
                    pixels[y * width + x] = (0, 0, 0, 0)


def main():
    import os
    out_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "Count/Assets.xcassets/AppIcon.appiconset/Icon.png"
    )

    print(f"Generating {SIZE}x{SIZE} AppIcon...")
    pixels = [(0, 0, 0, 255)] * (SIZE * SIZE)

    print("  Drawing background gradient...")
    fill_bg(pixels, SIZE, SIZE)

    print("  Drawing felt border...")
    draw_felt_border(pixels, SIZE, SIZE)

    print("  Drawing spade symbol...")
    spade_cx = SIZE * 0.45
    spade_cy = SIZE * 0.44
    draw_spade(pixels, SIZE, SIZE, spade_cx, spade_cy, 310, color=(255, 255, 255))

    print("  Drawing '21' text...")
    draw_text_21(pixels, SIZE, SIZE)

    print("  Drawing corner pips...")
    draw_corner_pip(pixels, SIZE, SIZE, 1, 'spade')

    print("  Adding rounded corners...")
    add_rounded_corners(pixels, SIZE, SIZE, 180)

    print(f"  Writing PNG to {out_path}...")
    png_data = make_png(SIZE, SIZE, pixels)
    with open(out_path, "wb") as f:
        f.write(png_data)

    print(f"Done. File size: {len(png_data):,} bytes")


if __name__ == "__main__":
    main()
