#!/usr/bin/env python3
"""Orbioom iOS scaffold v4: shared config boilerplate + on-brand 1024 app icon.

Generates Assets (icon, AccentColor, LaunchBackground), Info.plist, project.yml,
Preview assets. Swift sources are authored separately.

Motifs for the 2026-06-10_1812 run:
  rays (affirmations), bloom (gratitude), basket (grocery),
  sweep (photo cleaner), grid (sudoku), fork (tuner)

Usage:
  python3 scaffold4.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif>
"""
import os, sys, json, math
from PIL import Image, ImageDraw, ImageFilter

ios_dir, App, lower, hexv, motif = sys.argv[1:6]
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
    S = 1024
    img = Image.new("RGB", (S, S), (0,0,0))
    px = img.load()
    top = hx("2A2E3A"); bot = hx("16171D")
    cx, cy = S*0.5, S*0.46
    for y in range(S):
        for x in range(S):
            t = y / S
            base = lerp(top, bot, t)
            dd = math.hypot(x-cx, y-cy) / (S*0.75)
            glow = max(0.0, 1.0 - dd)
            g = 0.16 * glow*glow
            px[x,y] = (
                int(base[0]+(255-base[0])*g*0.10),
                int(base[1]+(255-base[1])*g*0.10),
                int(base[2]+(255-base[2])*g*0.12),
            )
    d = ImageDraw.Draw(img, "RGBA")
    light = (236,238,243,255)
    silver = (200,205,220,255)
    acc = (accent[0],accent[1],accent[2],255)
    green = hx("5EF0B0")
    gr = (green[0],green[1],green[2],255)

    if motif == "rays":  # affirmations — a luminous rising sun with calm rays
        r = 150
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=acc)
        for k in range(16):
            a = math.radians(k*22.5)
            x0 = cx + (r+40)*math.cos(a); y0 = cy + (r+40)*math.sin(a)
            x1 = cx + (r+150)*math.cos(a); y1 = cy + (r+150)*math.sin(a)
            w = 26 if k % 2 == 0 else 12
            col = (acc[0],acc[1],acc[2],235) if k % 2 == 0 else (silver[0],silver[1],silver[2],150)
            d.line([(x0,y0),(x1,y1)], fill=col, width=w)
        # inner highlight
        d.ellipse([cx-r+30, cy-r+24, cx+r-70, cy+r-90], fill=(255,255,255,40))
    elif motif == "bloom":  # gratitude — an open flower / thankful bloom, one petal luminous
        for k in range(6):
            a = math.radians(k*60 - 90)
            ox = cx + 120*math.cos(a); oy = cy + 120*math.sin(a)
            col = gr if k == 0 else light
            d.ellipse([ox-110, oy-150, ox+110, oy+150], fill=(col[0],col[1],col[2], 235))
        d.ellipse([cx-90, cy-90, cx+90, cy+90], fill=acc)
        d.ellipse([cx-44, cy-44, cx+44, cy+44], fill=(255,255,255,150))
    elif motif == "basket":  # grocery — a shopping basket with a luminous check
        # basket body (trapezoid)
        d.polygon([(cx-230, cy-40),(cx+230, cy-40),(cx+180, cy+230),(cx-180, cy+230)], fill=light)
        # weave lines
        for k in range(4):
            yy = cy + 10 + k*55
            d.line([(cx-212+k*8, yy),(cx+212-k*8, yy)], fill=(42,46,58,90), width=10)
        for k in range(5):
            xx = cx - 160 + k*80
            d.line([(xx, cy-40),(xx*0.82+cx*0.18, cy+220)], fill=(42,46,58,70), width=8)
        # handle
        d.arc([cx-150, cy-220, cx+150, cy+30], 180, 360, fill=silver, width=30)
        # luminous check badge
        d.ellipse([cx+90, cy-250, cx+250, cy-90], fill=gr)
        d.line([(cx+128, cy-170),(cx+158, cy-138)], fill=(20,24,30,255), width=22)
        d.line([(cx+158, cy-138),(cx+216, cy-206)], fill=(20,24,30,255), width=22)
    elif motif == "sweep":  # photo cleaner — a stack of photos, top one swiping away with sparkle
        # back card
        d.rounded_rectangle([cx-200, cy-150, cx+170, cy+220], radius=40, fill=(silver[0],silver[1],silver[2],150))
        # mid card
        d.rounded_rectangle([cx-220, cy-180, cx+150, cy+190], radius=40, fill=(light[0],light[1],light[2],200))
        # top card tilted (drawn as rotated rectangle via polygon)
        ang = math.radians(-16)
        def rot(px_, py_):
            dx, dy = px_-cx, py_-cy
            return (cx+dx*math.cos(ang)-dy*math.sin(ang), cy+dx*math.sin(ang)+dy*math.cos(ang))
        corners = [rot(cx-240, cy-200), rot(cx+130, cy-200), rot(cx+130, cy+170), rot(cx-240, cy+170)]
        d.polygon(corners, fill=light)
        # little mountain + sun motif inside top card
        c0 = corners
        midx = (c0[0][0]+c0[2][0])/2; midy=(c0[0][1]+c0[2][1])/2
        d.ellipse([midx-120, midy-70, midx-40, midy+10], fill=acc)
        d.polygon([(midx-140, midy+120),(midx-40, midy-10),(midx+60, midy+120)], fill=(120,128,150,255))
        # luminous sparkle (cleaned)
        sx, sy = cx+210, cy-200
        for a in [0, 90, 45, 135]:
            r = 70 if a % 90 == 0 else 40
            x0 = sx + r*math.cos(math.radians(a)); y0 = sy + r*math.sin(math.radians(a))
            x1 = sx - r*math.cos(math.radians(a)); y1 = sy - r*math.sin(math.radians(a))
            d.line([(x0,y0),(x1,y1)], fill=gr, width=16 if a%90==0 else 10)
    elif motif == "grid":  # sudoku — 9x9 grid, bold 3x3 blocks, one luminous solved cell
        L = 600
        x0 = cx - L/2; y0 = cy - L/2
        cell = L/9
        # luminous filled cell (a "solved" cell)
        gxr, gyr = 4, 4
        d.rounded_rectangle([x0+gxr*cell+6, y0+gyr*cell+6, x0+(gxr+1)*cell-6, y0+(gyr+1)*cell-6], radius=10, fill=acc)
        # a couple of light filled cells
        for (cxi, cyi) in [(1,2),(6,1),(2,7),(7,6)]:
            d.rounded_rectangle([x0+cxi*cell+10, y0+cyi*cell+10, x0+(cxi+1)*cell-10, y0+(cyi+1)*cell-10], radius=8, fill=(silver[0],silver[1],silver[2],120))
        for k in range(10):
            w = 18 if k % 3 == 0 else 6
            col = light if k % 3 == 0 else (silver[0],silver[1],silver[2],150)
            d.line([(x0+k*cell, y0),(x0+k*cell, y0+L)], fill=col, width=w)
            d.line([(x0, y0+k*cell),(x0+L, y0+k*cell)], fill=col, width=w)
    elif motif == "fork":  # tuner — tuning fork with a luminous needle/cents arc
        # fork stem
        d.rounded_rectangle([cx-26, cy+60, cx+26, cy+250], radius=20, fill=light)
        # fork base
        d.ellipse([cx-50, cy+220, cx+50, cy+300], fill=light)
        # two tines
        d.rounded_rectangle([cx-130, cy-250, cx-78, cy+90], radius=26, fill=light)
        d.rounded_rectangle([cx+78, cy-250, cx+130, cy+90], radius=26, fill=light)
        d.rounded_rectangle([cx-130, cy+40, cx+130, cy+92], radius=26, fill=light)
        # luminous tuning arc above
        d.arc([cx-260, cy-360, cx+260, cy+160], 200, 340, fill=(silver[0],silver[1],silver[2],150), width=14)
        d.arc([cx-260, cy-360, cx+260, cy+160], 262, 278, fill=gr, width=22)
        # needle pointing to center (in tune)
        d.line([(cx, cy+40),(cx, cy-150)], fill=acc, width=14)
        d.ellipse([cx-20, cy+24, cx+20, cy+64], fill=acc)
    else:
        d.ellipse([cx-160, cy-160, cx+160, cy+160], outline=light, width=24)

    img = img.filter(ImageFilter.GaussianBlur(0.4))
    img = img.convert("RGBA")
    img.save(path, "PNG")

write(os.path.join(app_dir,"Assets.xcassets","Contents.json"), json.dumps({"info":{"author":"xcode","version":1}}, indent=2))
write(os.path.join(app_dir,"Assets.xcassets","AppIcon.appiconset","Contents.json"),
      json.dumps({"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
                  "info":{"author":"xcode","version":1}}, indent=2))
make_icon(os.path.join(app_dir,"Assets.xcassets","AppIcon.appiconset","icon-1024.png"))

def colorset(name, light, dark):
    def comp(h):
        return {"red": f"0x{h[0:2]}", "green": f"0x{h[2:4]}", "blue": f"0x{h[4:6]}", "alpha": "1.000"}
    obj = {"colors": [
        {"idiom":"universal","color":{"color-space":"srgb","components":comp(light)}},
        {"idiom":"universal","appearances":[{"appearance":"luminosity","value":"dark"}],
         "color":{"color-space":"srgb","components":comp(dark)}},
    ], "info":{"author":"xcode","version":1}}
    write(os.path.join(app_dir,"Assets.xcassets",name+".colorset","Contents.json"), json.dumps(obj, indent=2))

colorset("AccentColor", hexv, "F2F3F8")
colorset("LaunchBackground", "EDEEF3", "14151B")
write(os.path.join(app_dir,"Preview Content","Preview Assets.xcassets","Contents.json"),
      json.dumps({"info":{"author":"xcode","version":1}}, indent=2))

info = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDevelopmentRegion</key>
\t<string>$(DEVELOPMENT_LANGUAGE)</string>
\t<key>CFBundleDisplayName</key>
\t<string>{App}</string>
\t<key>CFBundleExecutable</key>
\t<string>$(EXECUTABLE_NAME)</string>
\t<key>CFBundleIdentifier</key>
\t<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
\t<key>CFBundleInfoDictionaryVersion</key>
\t<string>6.0</string>
\t<key>CFBundleName</key>
\t<string>$(PRODUCT_NAME)</string>
\t<key>CFBundlePackageType</key>
\t<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
\t<key>CFBundleShortVersionString</key>
\t<string>$(MARKETING_VERSION)</string>
\t<key>CFBundleVersion</key>
\t<string>$(CURRENT_PROJECT_VERSION)</string>
\t<key>LSRequiresIPhoneOS</key>
\t<true/>
\t<key>UIApplicationSceneManifest</key>
\t<dict>
\t\t<key>UIApplicationSupportsMultipleScenes</key>
\t\t<true/>
\t</dict>
\t<key>UILaunchScreen</key>
\t<dict>
\t\t<key>UIColorName</key>
\t\t<string>LaunchBackground</string>
\t</dict>
\t<key>UISupportedInterfaceOrientations</key>
\t<array>
\t\t<string>UIInterfaceOrientationPortrait</string>
\t</array>
\t<key>UISupportedInterfaceOrientations~ipad</key>
\t<array>
\t\t<string>UIInterfaceOrientationPortrait</string>
\t\t<string>UIInterfaceOrientationPortraitUpsideDown</string>
\t\t<string>UIInterfaceOrientationLandscapeLeft</string>
\t\t<string>UIInterfaceOrientationLandscapeRight</string>
\t</array>
</dict>
</plist>
'''
write(os.path.join(app_dir,"Info.plist"), info)

proj = f'''name: {App}
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  {App}:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - {App}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.{lower}
        INFOPLIST_FILE: {App}/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        DEVELOPMENT_ASSET_PATHS: "\\"{App}/Preview Content\\""
'''
write(os.path.join(ios_dir,"project.yml"), proj)
print(f"scaffolded {App} ({motif}) accent #{hexv}")
