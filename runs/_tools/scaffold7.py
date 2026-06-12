#!/usr/bin/env python3
"""Orbioom iOS scaffold v7: config boilerplate + on-brand 1024 app icon.

Generates Assets (icon, AccentColor, LaunchBackground), Info.plist, project.yml,
Preview assets. Swift sources are authored separately.

Motifs for the 2026-06-12 evening run:
  cards (Palace/solitaire), arch (Mihrab/prayer times), qr (Glyph/QR studio),
  tag (Moniker/baby names), doc (Vitae/resume), rota (Rota/shift calendar)

Usage:
  python3 scaffold7.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif> [extras...]
  extras: camera motion
"""
import os, sys, json, math
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

def rounded(d, box, rad, fill):
    d.rounded_rectangle(box, radius=rad, fill=fill)

def make_icon(path):
    S = 2048
    img = Image.new("RGB", (S, S), (0,0,0))
    px = img.load()
    bgs = {
        "cards": ("0F3D2B", "06ttt"),
        "arch":  ("141B3F", "090D24"),
        "qr":    ("17191F", "0B0C10"),
        "tag":   ("3D2438", "1F0F1D"),
        "doc":   ("28251E", "14120D"),
        "rota":  ("1E2733", "0E141C"),
    }
    bgs["cards"] = ("0F3D2B", "062418")
    top, bot = (hx(x) for x in bgs.get(motif, ("23262F", "121419")))
    for y in range(S):
        row = lerp(top, bot, y / S)
        for x in range(S):
            px[x, y] = row
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = S*0.5, S*0.5
    acc = (accent[0], accent[1], accent[2], 255)
    light = (246, 244, 236, 255)
    ink = (26, 28, 36, 255)

    if motif == "cards":
        # fanned trio of cards with an ace of spades front card
        def card(cx_, cy_, w, h, ang, fill, outline=None):
            c = Image.new("RGBA", (int(w), int(h)), (0,0,0,0))
            cd = ImageDraw.Draw(c)
            cd.rounded_rectangle([0,0,w-1,h-1], radius=w*0.12, fill=fill)
            c = c.rotate(ang, expand=True, resample=Image.BICUBIC)
            img.paste(c, (int(cx_-c.width/2), int(cy_-c.height/2)), c)
        w, h = S*0.40, S*0.56
        card(cx-S*0.10, cy+S*0.02, w, h, 14, (214, 178, 94, 255))
        card(cx+S*0.10, cy+S*0.02, w, h, -7, (240, 233, 215, 70))
        card(cx, cy, w, h, 3, light)
        # spade on the front card
        sx, sy = cx - S*0.012, cy - S*0.045
        r = S*0.082
        d.ellipse([sx-r-r*0.62, sy-r*0.30, sx-r+r*0.62, sy-r*0.30+2*r*0.62], fill=ink)
        d.ellipse([sx+r-r*0.62, sy-r*0.30, sx+r+r*0.62, sy-r*0.30+2*r*0.62], fill=ink)
        d.polygon([(sx, sy-r*1.45), (sx-r*1.18, sy+r*0.18), (sx+r*1.18, sy+r*0.18)], fill=ink)
        d.polygon([(sx-r*0.34, sy+r*0.1), (sx+r*0.34, sy+r*0.1), (sx+r*0.5, sy+r*1.5), (sx-r*0.5, sy+r*1.5)], fill=ink)
        # corner pips
        d.ellipse([cx-w*0.40, cy-h*0.42, cx-w*0.40+S*0.035, cy-h*0.42+S*0.035], fill=acc)
        d.ellipse([cx+w*0.40-S*0.035, cy+h*0.42-S*0.035, cx+w*0.40, cy+h*0.42], fill=acc)
    elif motif == "arch":
        # mihrab arch (pointed horseshoe) with crescent + minaret star field
        aw, ah = S*0.52, S*0.62
        x0, y0 = cx-aw/2, cy-ah/2 + S*0.04
        # arch frame
        d.rounded_rectangle([x0-S*0.035, y0-S*0.035, x0+aw+S*0.035, y0+ah+S*0.06], radius=S*0.05, fill=(232, 222, 196, 28))
        # arch shape: rectangle + pointed top via two arcs
        d.rectangle([x0, y0+ah*0.32, x0+aw, y0+ah], fill=acc)
        d.pieslice([x0-aw*0.50, y0-ah*0.16, x0+aw*0.96, y0+ah*0.80], 270, 360, fill=acc)
        d.pieslice([x0+aw*0.04, y0-ah*0.16, x0+aw*1.50, y0+ah*0.80], 180, 270, fill=acc)
        # inner glow arch
        g = (lerp(accent,(255,255,255),0.35)) + (255,)
        ix0, iy0, iw, ih = x0+aw*0.10, y0+ah*0.12, aw*0.80, ah*0.88
        d.rectangle([ix0, iy0+ih*0.30, ix0+iw, iy0+ih], fill=g)
        d.pieslice([ix0-iw*0.50, iy0-ih*0.16, ix0+iw*0.96, iy0+ih*0.78], 270, 360, fill=g)
        d.pieslice([ix0+iw*0.04, iy0-ih*0.16, ix0+iw*1.50, iy0+ih*0.78], 180, 270, fill=g)
        # crescent inside
        mr = S*0.105
        mcx, mcy = cx, cy+S*0.10
        d.ellipse([mcx-mr, mcy-mr, mcx+mr, mcy+mr], fill=(20, 26, 60, 255))
        d.ellipse([mcx-mr+mr*0.62, mcy-mr-mr*0.18, mcx+mr+mr*0.62, mcy+mr-mr*0.18], fill=g)
        d.ellipse([mcx-mr*0.9+mr*0.62, mcy-mr*0.9-mr*0.18, mcx+mr*0.55+mr*0.62, mcy+mr*0.62-mr*0.18], fill=(20, 26, 60, 255))
        # stars
        for (sx, sy, sr) in [(0.20,0.16,0.012),(0.80,0.13,0.009),(0.69,0.24,0.007),(0.27,0.27,0.007),(0.5,0.09,0.010)]:
            d.ellipse([S*sx-S*sr, S*sy-S*sr, S*sx+S*sr, S*sy+S*sr], fill=(240,236,210,230))
    elif motif == "qr":
        # stylized QR with three finder squares and scan beam
        cell = S*0.052
        ox, oy = cx - cell*6.5, cy - cell*6.5
        def finder(fx, fy):
            d.rounded_rectangle([fx, fy, fx+cell*4, fy+cell*4], radius=cell*0.9, fill=light)
            d.rounded_rectangle([fx+cell*0.95, fy+cell*0.95, fx+cell*3.05, fy+cell*3.05], radius=cell*0.55, fill=(11,12,16,255))
            d.rounded_rectangle([fx+cell*1.5, fy+cell*1.5, fx+cell*2.5, fy+cell*2.5], radius=cell*0.3, fill=acc)
        finder(ox, oy)
        finder(ox+cell*9, oy)
        finder(ox, oy+cell*9)
        import random
        rnd = random.Random(7)
        for gy in range(13):
            for gx in range(13):
                if (gx < 5 and gy < 5) or (gx > 7 and gy < 5) or (gx < 5 and gy > 7):
                    continue
                if rnd.random() < 0.46:
                    x_, y_ = ox+gx*cell, oy+gy*cell
                    d.rounded_rectangle([x_+cell*0.12, y_+cell*0.12, x_+cell*0.88, y_+cell*0.88], radius=cell*0.22, fill=light)
        # accent beam
        d.rounded_rectangle([ox-cell*1.4, cy-cell*0.30, ox+cell*14.4, cy+cell*0.30], radius=cell*0.3, fill=(accent[0],accent[1],accent[2],150))
    elif motif == "tag":
        # two overlapping name tags forming a heart-ish pairing
        def tagshape(tx, ty, w, h, ang, fill):
            t = Image.new("RGBA", (int(w*1.3), int(h*1.3)), (0,0,0,0))
            td = ImageDraw.Draw(t)
            td.rounded_rectangle([w*0.15, h*0.15, w*1.05, h*0.95], radius=h*0.18, fill=fill)
            td.ellipse([w*0.24, h*0.45, w*0.36, h*0.45+w*0.12], fill=(0,0,0,90))
            t = t.rotate(ang, expand=True, resample=Image.BICUBIC)
            img.paste(t, (int(tx-t.width/2), int(ty-t.height/2)), t)
        tagshape(cx-S*0.07, cy-S*0.07, S*0.52, S*0.30, 18, (244, 240, 230, 235))
        tagshape(cx+S*0.07, cy+S*0.09, S*0.52, S*0.30, -9, acc)
        # heart where they overlap
        hr = S*0.075
        hx_, hy_ = cx+S*0.10, cy+S*0.075
        d.ellipse([hx_-hr, hy_-hr*0.7, hx_, hy_+hr*0.3], fill=light)
        d.ellipse([hx_, hy_-hr*0.7, hx_+hr, hy_+hr*0.3], fill=light)
        d.polygon([(hx_-hr*0.93, hy_+hr*0.02), (hx_+hr*0.93, hy_+hr*0.02), (hx_, hy_+hr*1.15)], fill=light)
    elif motif == "doc":
        # resume sheet with accent header bar and lines
        w, h = S*0.46, S*0.60
        x0, y0 = cx-w/2, cy-h/2
        d.rounded_rectangle([x0+S*0.025, y0+S*0.03, x0+w+S*0.025, y0+h+S*0.03], radius=S*0.035, fill=(0,0,0,90))
        d.rounded_rectangle([x0, y0, x0+w, y0+h], radius=S*0.035, fill=light)
        d.rounded_rectangle([x0, y0, x0+w, y0+h*0.18], radius=S*0.035, fill=acc)
        d.rectangle([x0, y0+h*0.10, x0+w, y0+h*0.18], fill=acc)
        # avatar circle + name lines
        d.ellipse([x0+w*0.07, y0+h*0.045, x0+w*0.07+h*0.09, y0+h*0.045+h*0.09], fill=light)
        d.rounded_rectangle([x0+w*0.30, y0+h*0.06, x0+w*0.78, y0+h*0.085], radius=S*0.006, fill=(255,255,255,235))
        d.rounded_rectangle([x0+w*0.30, y0+h*0.105, x0+w*0.62, y0+h*0.125], radius=S*0.005, fill=(255,255,255,170))
        ys = y0+h*0.26
        for i, frac in enumerate([0.86, 0.74, 0.80, 0.55, 0.0, 0.82, 0.68, 0.76, 0.45]):
            if frac == 0.0:
                ys += h*0.045
                d.rounded_rectangle([x0+w*0.07, ys, x0+w*0.35, ys+h*0.022], radius=S*0.005, fill=acc)
            else:
                d.rounded_rectangle([x0+w*0.07, ys, x0+w*(0.07+frac*0.86), ys+h*0.018], radius=S*0.004, fill=(60,62,72,200))
            ys += h*0.055
    elif motif == "rota":
        # calendar grid with colored shift chips + clock badge
        w, h = S*0.56, S*0.50
        x0, y0 = cx-w/2, cy-h/2 - S*0.02
        d.rounded_rectangle([x0, y0, x0+w, y0+h], radius=S*0.04, fill=light)
        d.rounded_rectangle([x0, y0, x0+w, y0+h*0.16], radius=S*0.04, fill=ink)
        d.rectangle([x0, y0+h*0.08, x0+w, y0+h*0.16], fill=ink)
        cols, rows = 5, 3
        cw, ch = w/cols, (h*0.84)/rows
        chips = {
            (0,0): acc, (1,0): acc, (2,0): (90, 150, 240, 255), (4,0): (90, 150, 240, 255),
            (1,1): (90, 150, 240, 255), (3,1): acc, (4,1): acc,
            (0,2): acc, (2,2): (90, 150, 240, 255), (3,2): (90, 150, 240, 255),
        }
        for r in range(rows):
            for c in range(cols):
                px0 = x0 + c*cw + cw*0.12
                py0 = y0 + h*0.16 + r*ch + ch*0.14
                fill = chips.get((c,r))
                if fill:
                    d.rounded_rectangle([px0, py0, px0+cw*0.76, py0+ch*0.72], radius=S*0.012, fill=fill)
                else:
                    d.rounded_rectangle([px0, py0, px0+cw*0.76, py0+ch*0.72], radius=S*0.012, outline=(160,160,168,160), width=int(S*0.004))
        # clock badge
        br = S*0.115
        bx, by = x0+w-S*0.01, y0+h-S*0.01
        d.ellipse([bx-br, by-br, bx+br, by+br], fill=ink)
        d.ellipse([bx-br*0.82, by-br*0.82, bx+br*0.82, by+br*0.82], fill=light)
        d.line([bx, by, bx, by-br*0.55], fill=ink, width=int(S*0.014))
        d.line([bx, by, bx+br*0.42, by+br*0.18], fill=ink, width=int(S*0.014))
        d.ellipse([bx-S*0.012, by-S*0.012, bx+S*0.012, by+S*0.012], fill=acc)

    img = img.resize((1024, 1024), Image.LANCZOS)
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
launch_dark = hx("101216")
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
if "camera" in extras:
    plist_extra += """
	<key>NSCameraUsageDescription</key>
	<string>The camera is used to scan QR codes. Frames are processed on this device only and are never uploaded.</string>"""
if "motion" in extras:
    plist_extra += """
	<key>NSMotionUsageDescription</key>
	<string>Motion sensors power the live compass so the dial can point toward the qibla.</string>"""

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
