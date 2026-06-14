#!/usr/bin/env python3
"""Orbioom iOS scaffold v11: config boilerplate + on-brand 1024 app icon.

Generates Assets (icon, AccentColor, LaunchBackground), Info.plist, project.yml,
Preview assets. Swift sources are authored separately.

Motifs for the 2026-06-14 evening run:
  drop (Lancet/glucose+diabetes manager), skillet (Skillet/pantry->recipe matcher),
  envelope (Allot/zero-based budget), clef (Clef/sight-reading trainer),
  sunrise (Daybreak/routine builder+runner), blocks (Cobble/block puzzle game)

Usage:
  python3 scaffold11.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif> [extras...]
  extras: photos  faceid  camera
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

def make_icon(path):
    S = 2048
    img = Image.new("RGB", (S, S), (0,0,0))
    px = img.load()
    bgs = {
        "drop":     ("2A1218", "120608"),
        "skillet":  ("271811", "120A06"),
        "envelope": ("0F241D", "061310"),
        "clef":     ("181333", "08061A"),
        "sunrise":  ("2B1D10", "140C06"),
        "blocks":   ("101A30", "070C18"),
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

    def accL(t):
        c = lerp(accent, (255,255,255), t)
        return (c[0], c[1], c[2], 255)
    def accD(t):
        c = lerp(accent, (0,0,0), t)
        return (c[0], c[1], c[2], 255)

    if motif == "drop":
        # a teardrop (blood/glucose) with a highlight, over a faint trend line
        # faint trend polyline behind
        pts = []
        for i in range(7):
            t = i/6.0
            xx = cx - S*0.26 + t*S*0.52
            yy = cy + S*0.20 + math.sin(t*6.0)*S*0.05
            pts.append((xx, yy))
        d.line(pts, fill=(accent[0],accent[1],accent[2],90), width=int(S*0.012), joint="curve")
        # teardrop: circle bottom + triangle top
        r = S*0.18
        dy = S*0.04
        d.ellipse([cx-r, cy-r+dy, cx+r, cy+r+dy], fill=acc)
        d.polygon([(cx, cy-r*2.0+dy),(cx-r*0.86, cy+dy*0.2),(cx+r*0.86, cy+dy*0.2)], fill=acc)
        # specular highlight
        hr = r*0.34
        d.ellipse([cx-r*0.46-hr, cy-r*0.18-hr+dy, cx-r*0.46+hr, cy-r*0.18+hr+dy], fill=accL(0.45))
        # small plus (medical) in light at center-bottom
        pw = S*0.022; pl = S*0.07
        d.rounded_rectangle([cx-pw, cy+dy-pl, cx+pw, cy+dy+pl], radius=pw*0.6, fill=light)
        d.rounded_rectangle([cx-pl, cy+dy-pw, cx+pl, cy+dy+pw], radius=pw*0.6, fill=light)
    elif motif == "skillet":
        # a frying pan (circle + handle) with a few ingredient dots
        R = S*0.215
        # handle
        hw = S*0.07
        d.rounded_rectangle([cx+R*0.78, cy-hw/2, cx+R*0.78+S*0.30, cy+hw/2], radius=hw/2, fill=accD(0.1))
        # pan body
        d.ellipse([cx-R, cy-R, cx+R, cy+R], fill=accD(0.05))
        d.ellipse([cx-R, cy-R, cx+R, cy+R], outline=accL(0.2), width=int(S*0.016))
        # cooking surface
        ir = R*0.82
        d.ellipse([cx-ir, cy-ir, cx+ir, cy+ir], fill=acc)
        # ingredient dots
        for (ox, oy, rr, col) in [(-0.30,-0.12,0.075,light),(0.10,-0.22,0.055,accL(0.5)),
                                  (0.22,0.16,0.07,light),(-0.12,0.26,0.05,accL(0.55)),
                                  (-0.02,0.02,0.06,accL(0.6))]:
            d.ellipse([cx+ox*R-rr*R, cy+oy*R-rr*R, cx+ox*R+rr*R, cy+oy*R+rr*R], fill=col)
        # gloss arc
        d.arc([cx-ir*0.78, cy-ir*0.78, cx+ir*0.78, cy+ir*0.78], 200, 250, fill=(255,255,255,40), width=int(S*0.012))
    elif motif == "envelope":
        # an envelope with an open flap + a coin tucked in (budget allocated)
        ew, eh = S*0.50, S*0.34
        x0, y0 = cx-ew/2, cy-eh/2
        d.rounded_rectangle([x0, y0, x0+ew, y0+eh], radius=S*0.03, fill=acc)
        # inner pocket lines
        d.line([(x0+S*0.01, y0+eh-S*0.01),(cx, cy+S*0.01),(x0+ew-S*0.01, y0+eh-S*0.01)],
               fill=accD(0.18), width=int(S*0.012), joint="curve")
        # open flap (triangle pointing up)
        d.polygon([(x0, y0),(cx, y0-eh*0.42),(x0+ew, y0)], fill=accL(0.12))
        d.polygon([(x0, y0),(cx, y0-eh*0.42),(x0+ew, y0)], outline=accL(0.3), width=int(S*0.008))
        # coin rising out
        cr = S*0.085
        ccy = y0 - eh*0.10
        d.ellipse([cx-cr, ccy-cr, cx+cr, ccy+cr], fill=light)
        d.ellipse([cx-cr, ccy-cr, cx+cr, ccy+cr], outline=accD(0.05), width=int(S*0.008))
        # a currency-ish mark on coin
        mw = cr*0.18; ml = cr*0.62
        d.rounded_rectangle([cx-mw, ccy-ml, cx+mw, ccy+ml], radius=mw*0.6, fill=accD(0.05))
    elif motif == "clef":
        # a 5-line staff with a stylized note + accent note head
        sw = S*0.52
        x0 = cx - sw/2
        for i in range(5):
            yy = cy - S*0.13 + i*S*0.065
            d.line([(x0, yy),(x0+sw, yy)], fill=(light[0],light[1],light[2],210), width=int(S*0.008))
        # note stem
        nx = cx + S*0.06
        nhy = cy + S*0.085
        d.rounded_rectangle([nx+S*0.075, nhy-S*0.28, nx+S*0.092, nhy], radius=S*0.006, fill=light)
        # note head (accent, tilted ellipse approx)
        hr = S*0.072
        d.ellipse([nx-hr, nhy-hr*0.78, nx+hr, nhy+hr*0.78], fill=acc)
        d.ellipse([nx-hr, nhy-hr*0.78, nx+hr, nhy+hr*0.78], outline=accL(0.3), width=int(S*0.006))
        # flag
        d.polygon([(nx+S*0.092, nhy-S*0.28),(nx+S*0.092+S*0.085, nhy-S*0.21),
                   (nx+S*0.092, nhy-S*0.14)], fill=accL(0.25))
        # a small second note head left
        h2 = S*0.05
        n2x, n2y = cx - S*0.16, cy + S*0.02
        d.ellipse([n2x-h2, n2y-h2*0.78, n2x+h2, n2y+h2*0.78], fill=accL(0.35))
    elif motif == "sunrise":
        # a sun rising over a horizon with rays (morning/evening routine)
        horizon = cy + S*0.10
        sr = S*0.15
        scy = horizon - S*0.01
        # rays
        for i in range(9):
            ang = math.pi*(0.08 + i*(0.84/8))
            x1 = cx + math.cos(ang)*sr*1.35
            y1 = scy - math.sin(ang)*sr*1.35
            x2 = cx + math.cos(ang)*sr*1.85
            y2 = scy - math.sin(ang)*sr*1.85
            d.line([(x1,y1),(x2,y2)], fill=accL(0.2), width=int(S*0.016))
        # sun disc (upper half above horizon, clipped by drawing then horizon block)
        d.ellipse([cx-sr, scy-sr, cx+sr, scy+sr], fill=acc)
        d.ellipse([cx-sr*0.66, scy-sr*0.66, cx+sr*0.66, scy+sr*0.66], fill=accL(0.25))
        # horizon band masks lower half + ground
        d.rectangle([0, horizon, S, S], fill=lerp(accent,(0,0,0),0.62)+(255,) if False else accD(0.55))
        d.rectangle([0, horizon, S, horizon+int(S*0.012)], fill=accL(0.3))
        # three routine dots on the ground (steps)
        for i,ox in enumerate([-0.18,0.0,0.18]):
            rr = S*0.026
            d.ellipse([cx+ox*S-rr, horizon+S*0.12-rr, cx+ox*S+rr, horizon+S*0.12+rr],
                      fill=light if i==0 else accL(0.35))
    elif motif == "blocks":
        # a grid with filled blocks forming an L-piece + line (block puzzle)
        g = S*0.50
        x0, y0 = cx-g/2, cy-g/2
        n = 5
        cell = g/n
        # grid background cells
        for r in range(n):
            for c in range(n):
                fx, fy = x0+c*cell, y0+r*cell
                d.rounded_rectangle([fx+S*0.004, fy+S*0.004, fx+cell-S*0.004, fy+cell-S*0.004],
                                    radius=S*0.012, fill=(255,255,255,16))
        # filled accent blocks (an L-piece + a couple)
        filled = {(1,1),(2,1),(3,1),(3,2),(0,3),(1,3)}
        light_blocks = {(3,3),(4,3)}
        def block(r,c,col):
            fx, fy = x0+c*cell, y0+r*cell
            d.rounded_rectangle([fx+S*0.006, fy+S*0.006, fx+cell-S*0.006, fy+cell-S*0.006],
                                radius=S*0.016, fill=col)
            d.rounded_rectangle([fx+S*0.018, fy+S*0.018, fx+cell-S*0.018, fy+cell*0.42],
                                radius=S*0.012, fill=(255,255,255,40))
        for (r,c) in filled:
            block(r,c,acc)
        for (r,c) in light_blocks:
            block(r,c,accL(0.4))

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
	<string>Saved cards and exports are written to your photo library only when you tap Save. Nothing is uploaded.</string>"""
if "camera" in extras:
    plist_extra += """
	<key>NSCameraUsageDescription</key>
	<string>The camera is used only when you choose to capture a photo. Nothing is uploaded or stored without your action.</string>"""
if "faceid" in extras:
    plist_extra += """
	<key>NSFaceIDUsageDescription</key>
	<string>Face ID unlocks your private data on this device. Your data never leaves your phone.</string>"""

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
