#!/usr/bin/env python3
"""Orbioom iOS scaffold v8: config boilerplate + on-brand 1024 app icon.

Generates Assets (icon, AccentColor, LaunchBackground), Info.plist, project.yml,
Preview assets. Swift sources are authored separately.

Motifs for the 2026-06-13 evening run:
  aperture (Lumen/photo editor), steps (Cascade/debt payoff),
  capsule (Cadence/medication), growth (Plumb/net worth),
  spark (Savant/trivia), frames (Montage/story maker)

Usage:
  python3 scaffold8.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif> [extras...]
  extras: photos
"""
import os, sys, json, math, random
from PIL import Image, ImageDraw

ios_dir, App, lower, hexv, motif = sys.argv[1:6]
extras = sys.argv[6:]
app_dir = os.path.join(ios_dir, App)

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

def hx(h):
    return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
accent = hx(hexv)

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(3))

def make_icon(path):
    S = 2048
    img = Image.new("RGB", (S, S), (0,0,0))
    px = img.load()
    bgs = {
        "aperture": ("1B2026", "0C0E12"),
        "steps":    ("0E2A24", "06140F"),
        "capsule":  ("0E2630", "061319"),
        "growth":   ("141A33", "080B1A"),
        "spark":    ("241A3A", "120C1F"),
        "frames":   ("2A1426", "150A14"),
    }
    top, bot = (hx(x) for x in bgs.get(motif, ("23262F", "121419")))
    for y in range(S):
        row = lerp(top, bot, y / S)
        for x in range(S):
            px[x, y] = row
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = S*0.5, S*0.5
    acc = (accent[0], accent[1], accent[2], 255)
    light = (245, 244, 240, 255)
    ink = (22, 24, 30, 255)

    def accL(t):  # accent lightened toward white
        c = lerp(accent, (255,255,255), t)
        return (c[0], c[1], c[2], 255)

    if motif == "aperture":
        # camera aperture: 6 rotated blades around a central opening + color swatch
        R = S*0.30
        n = 6
        for i in range(n):
            a0 = math.radians(i * 360/n)
            # blade as a triangle pointing toward center, colored as spectrum
            hue = i / n
            cols = [(232,99,60),(236,167,61),(108,196,120),(74,165,200),(96,120,236),(176,96,210)]
            col = cols[i % len(cols)] + (255,)
            p1 = (cx + R*math.cos(a0), cy + R*math.sin(a0))
            a1 = a0 + math.radians(360/n)
            p2 = (cx + R*math.cos(a1), cy + R*math.sin(a1))
            inner = S*0.085
            i1 = (cx + inner*math.cos(a0+math.radians(28)), cy + inner*math.sin(a0+math.radians(28)))
            d.polygon([p1, p2, i1], fill=col)
        # outer ring
        d.ellipse([cx-R-S*0.03, cy-R-S*0.03, cx+R+S*0.03, cy+R+S*0.03], outline=light, width=int(S*0.018))
        # central opening
        d.ellipse([cx-S*0.085, cy-S*0.085, cx+S*0.085, cy+S*0.085], fill=(12,14,18,255))
        d.ellipse([cx-S*0.05, cy-S*0.05, cx+S*0.05, cy+S*0.05], fill=accL(0.2))
    elif motif == "steps":
        # descending staircase of bars down to a flag (debt -> zero)
        bw = S*0.13
        gap = S*0.018
        x0 = cx - (bw*4 + gap*3)/2
        heights = [0.46, 0.35, 0.25, 0.15]
        baseY = cy + S*0.24
        for i, hh in enumerate(heights):
            x = x0 + i*(bw+gap)
            top_ = baseY - S*hh
            col = accL(0.10 + i*0.16)
            d.rounded_rectangle([x, top_, x+bw, baseY], radius=bw*0.16, fill=col)
        # checkered finish flag at the bottom of the last (lowest) step
        fx = x0 + 3*(bw+gap) + bw*0.5
        fy = baseY - S*heights[3] - S*0.16
        d.rectangle([fx, fy, fx+S*0.012, baseY], fill=light)  # pole
        flag = S*0.10
        d.polygon([(fx+S*0.012, fy), (fx+S*0.012+flag, fy+flag*0.32), (fx+S*0.012, fy+flag*0.64)], fill=acc)
        # downward arrow overlay
        ax = cx - S*0.0
        ay0 = cy - S*0.30
        d.line([(x0+bw*0.5, baseY - S*heights[0] - S*0.05),
                (x0+3*(bw+gap)+bw*0.5, baseY - S*heights[3] - S*0.05)],
               fill=(255,255,255,210), width=int(S*0.012))
    elif motif == "capsule":
        # a medicine capsule split diagonally: accent half + light half, with a soft clock tick
        cw, ch = S*0.52, S*0.235
        x0, y0 = cx-cw/2, cy-ch/2
        cap = Image.new("RGBA", (int(cw), int(ch)), (0,0,0,0))
        cd = ImageDraw.Draw(cap)
        cd.rounded_rectangle([0,0,cw-1,ch-1], radius=ch/2, fill=light)
        cd.rounded_rectangle([0,0,cw/2,ch-1], radius=ch/2, fill=acc)
        cd.rectangle([cw/2-ch/2, 0, cw/2, ch-1], fill=acc)
        # seam
        cd.line([cw/2, 0, cw/2, ch], fill=(0,0,0,40), width=int(S*0.006))
        cap = cap.rotate(-28, expand=True, resample=Image.BICUBIC)
        img.paste(cap, (int(cx-cap.width/2), int(cy-cap.height/2)), cap)
        # small sparkle dots on the light half (granules)
        for (gx, gy) in [(0.60,0.40),(0.66,0.52),(0.58,0.56)]:
            d.ellipse([S*gx, S*gy, S*gx+S*0.022, S*gy+S*0.022], fill=accL(0.25))
        # tick ring (schedule) top-right
        rr = S*0.10
        rx, ry = cx+S*0.20, cy-S*0.22
        d.ellipse([rx-rr, ry-rr, rx+rr, ry+rr], outline=light, width=int(S*0.016))
        d.line([rx, ry, rx, ry-rr*0.6], fill=light, width=int(S*0.013))
        d.line([rx, ry, rx+rr*0.45, ry], fill=light, width=int(S*0.013))
    elif motif == "growth":
        # rising area chart (net worth) with plumb-line gridlines + gold curve
        x0, y0 = cx-S*0.30, cy+S*0.26
        w, h = S*0.60, S*0.46
        # gridlines
        for i in range(1,4):
            yy = y0 - h*i/4
            d.line([x0, yy, x0+w, yy], fill=(255,255,255,28), width=int(S*0.004))
        pts = [0.04, 0.10, 0.08, 0.20, 0.30, 0.28, 0.40, 0.52]
        n = len(pts)
        poly = [(x0, y0)]
        for i, p in enumerate(pts):
            poly.append((x0 + w*i/(n-1), y0 - h*p))
        poly.append((x0+w, y0))
        d.polygon(poly, fill=(accent[0], accent[1], accent[2], 90))
        # curve line on top
        line = [(x0 + w*i/(n-1), y0 - h*pts[i]) for i in range(n)]
        d.line(line, fill=acc, width=int(S*0.020), joint="curve")
        for (lx, ly) in [line[-1]]:
            d.ellipse([lx-S*0.022, ly-S*0.022, lx+S*0.022, ly+S*0.022], fill=light)
        # up arrow head at the end
        ex, ey = line[-1]
        d.polygon([(ex+S*0.0, ey-S*0.07), (ex-S*0.04, ey-S*0.02), (ex+S*0.04, ey-S*0.02)], fill=acc)
    elif motif == "spark":
        # quiz lightbulb: glowing bulb with a question-mark filament + rays
        br = S*0.17
        bx, by = cx, cy - S*0.04
        # rays
        for i in range(8):
            a = math.radians(i*45 - 90)
            r0 = br*1.35; r1 = br*1.75
            d.line([(bx+r0*math.cos(a), by+r0*math.sin(a)),
                    (bx+r1*math.cos(a), by+r1*math.sin(a))],
                   fill=accL(0.2), width=int(S*0.014))
        # bulb glass
        d.ellipse([bx-br, by-br, bx+br, by+br], fill=accL(0.05))
        d.ellipse([bx-br, by-br, bx+br, by+br], outline=light, width=int(S*0.012))
        # base
        baseW = br*0.9
        d.rounded_rectangle([bx-baseW/2, by+br*0.78, bx+baseW/2, by+br*1.5], radius=S*0.02, fill=light)
        d.line([bx-baseW/2, by+br*1.12, bx+baseW/2, by+br*1.12], fill=(0,0,0,60), width=int(S*0.008))
        d.line([bx-baseW/2, by+br*1.30, bx+baseW/2, by+br*1.30], fill=(0,0,0,60), width=int(S*0.008))
        # question mark filament
        qr = br*0.5
        d.arc([bx-qr, by-qr*1.1, bx+qr, by+qr*0.5], 160, 380, fill=ink, width=int(S*0.026))
        d.line([bx+qr*0.16, by+qr*0.18, bx+qr*0.16, by+qr*0.55], fill=ink, width=int(S*0.026))
        d.ellipse([bx+qr*0.02, by+qr*0.78, bx+qr*0.30, by+qr*1.06], fill=ink)
    elif motif == "frames":
        # overlapping story/photo frames forming a collage + play ring
        def frame(fx, fy, w, h, ang, fill, inner):
            t = Image.new("RGBA", (int(w*1.4), int(h*1.4)), (0,0,0,0))
            td = ImageDraw.Draw(t)
            ox, oy = w*0.2, h*0.2
            td.rounded_rectangle([ox, oy, ox+w, oy+h], radius=w*0.10, fill=fill)
            td.rounded_rectangle([ox+w*0.08, oy+h*0.08, ox+w*0.92, oy+h*0.92], radius=w*0.07, fill=inner)
            t = t.rotate(ang, expand=True, resample=Image.BICUBIC)
            img.paste(t, (int(fx-t.width/2), int(fy-t.height/2)), t)
        frame(cx-S*0.085, cy-S*0.02, S*0.34, S*0.40, 11, (244,240,236,235), (108,120,200,255))
        frame(cx+S*0.085, cy+S*0.04, S*0.34, S*0.40, -8, light, (accent[0],accent[1],accent[2],255))
        # little "sun + mountain" inside the front frame
        fx, fy = cx+S*0.085, cy+S*0.04
        d.ellipse([fx-S*0.02, fy-S*0.10, fx+S*0.04, fy-S*0.04], fill=light)
        d.polygon([(fx-S*0.11, fy+S*0.12),(fx-S*0.03, fy-S*0.01),(fx+S*0.05, fy+S*0.12)], fill=(255,255,255,210))
        # play ring badge bottom-right (story)
        rr = S*0.085
        rx, ry = cx+S*0.20, cy+S*0.21
        d.ellipse([rx-rr, ry-rr, rx+rr, ry+rr], fill=accL(0.0))
        d.ellipse([rx-rr, ry-rr, rx+rr, ry+rr], outline=light, width=int(S*0.014))
        d.polygon([(rx-rr*0.28, ry-rr*0.4),(rx-rr*0.28, ry+rr*0.4),(rx+rr*0.42, ry)], fill=light)

    img = img.resize((1024,1024), Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")

assets = os.path.join(app_dir, "Assets.xcassets")
make_icon(os.path.join(assets, "AppIcon.appiconset", "icon-1024.png"))
write(os.path.join(assets, "AppIcon.appiconset", "Contents.json"), json.dumps({
    "images": [{"filename": "icon-1024.png", "idiom": "universal",
                "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1}}, indent=2))
write(os.path.join(assets, "Contents.json"), json.dumps(
    {"info": {"author": "xcode", "version": 1}}, indent=2))

def comp(c):
    return {"red": "0x%02X" % c[0], "green": "0x%02X" % c[1], "blue": "0x%02X" % c[2], "alpha": "1.000"}
write(os.path.join(assets, "AccentColor.colorset", "Contents.json"), json.dumps({
    "colors": [
        {"color": {"color-space": "srgb", "components": comp(accent)}, "idiom": "universal"},
    ],
    "info": {"author": "xcode", "version": 1}}, indent=2))

launch_light = hx("F6F4EE")
launch_dark = hx("0D0F13")
write(os.path.join(assets, "LaunchBackground.colorset", "Contents.json"), json.dumps({
    "colors": [
        {"color": {"color-space": "srgb", "components": comp(launch_light)}, "idiom": "universal"},
        {"appearances": [{"appearance": "luminosity", "value": "dark"}],
         "color": {"color-space": "srgb", "components": comp(launch_dark)}, "idiom": "universal"},
    ],
    "info": {"author": "xcode", "version": 1}}, indent=2))

write(os.path.join(app_dir, "Preview Content", "Preview Assets.xcassets", "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

plist_extra = ""
if "photos" in extras:
    plist_extra += """
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>Saved edits and exports are written to your photo library only when you tap Save. Nothing is uploaded.</string>"""

write(os.path.join(app_dir, "Info.plist"), """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>%s</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>%s
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
	</dict>
	<key>UILaunchScreen</key>
	<dict>
		<key>UIColorName</key>
		<string>LaunchBackground</string>
	</dict>
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>arm64</string>
	</array>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>
""" % (App, plist_extra))

write(os.path.join(ios_dir, "project.yml"), """name: %s
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  %s:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - %s
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.%s
        INFOPLIST_FILE: %s/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        DEVELOPMENT_ASSET_PATHS: "\\"%s/Preview Content\\""
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
""" % (App, App, App, lower, App, App))

print("scaffolded", App)
