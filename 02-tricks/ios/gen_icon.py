#!/usr/bin/env python3
import struct, zlib, math, os

def write_png(path, pixels, w, h):
    def chunk(tag, data):
        c = tag + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    raw = b''.join(b'\x00' + bytes(p for px in row for p in px) for row in pixels)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b'IDAT', zlib.compress(raw, 6)))
        f.write(chunk(b'IEND', b''))

size = 1024
pixels = [[[0,0,0] for _ in range(size)] for _ in range(size)]
cx, cy = size//2, size//2

for y in range(size):
    for x in range(size):
        t = y / size
        pixels[y][x] = [int(20+10*t), int(80+20*t), int(40+10*t)]

def draw_spade(pixels, cx, cy, r, color):
    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            lx, ly = dx + r*0.4, dy + r*0.15
            rx2, ry2 = dx - r*0.4, dy + r*0.15
            tx, ty = dx, dy - r*0.1
            in_left = lx*lx + ly*ly < (r*0.5)**2
            in_right = rx2*rx2 + ry2*ry2 < (r*0.5)**2
            in_top = tx*tx + ty*ty < (r*0.58)**2
            in_stem = (abs(dx) < r*0.18 and dy > r*0.3 and dy < r*0.75)
            in_base = (abs(dx) < r*0.42 and dy > r*0.65 and dy < r*0.8)
            if (in_left or in_right or in_top) and dy < r*0.5:
                pixels[y][x] = color
            elif in_stem or in_base:
                pixels[y][x] = color

draw_spade(pixels, cx, cy, 380, [220, 220, 210])
os.makedirs('Tricks/Assets.xcassets/AppIcon.appiconset', exist_ok=True)
write_png('Tricks/Assets.xcassets/AppIcon.appiconset/Icon.png', pixels, size, size)
print("Icon written")
