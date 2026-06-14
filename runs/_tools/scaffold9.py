#!/usr/bin/env python3
"""Orbioom iOS scaffold v9: config boilerplate + on-brand 1024 app icon.

Generates Assets (icon, AccentColor, LaunchBackground), Info.plist, project.yml,
Preview assets. Swift sources are authored separately.

Motifs for the 2026-06-14 morning run:
  dish (Relish/restaurant ranker), controller (Quest/game backlog),
  bowl (Bell/meditation timer), route (Jaunt/trip itinerary),
  meeple (Meeple/board-game logger), grid (Nonet/sudoku)

Usage:
  python3 scaffold9.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif> [extras...]
  extras: photos
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
        "dish":       ("2A1715", "140A08"),
        "controller": ("1C1830", "0C0A18"),
        "bowl":       ("0C2622", "041311"),
        "route":      ("0E2030", "060F18"),
        "meeple":     ("2A1B10", "140C06"),
        "grid":       ("141B30", "080C18"),
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

    if motif == "dish":
        # a location pin whose round head is a dinner plate with fork & knife
        # pin teardrop
        R = S*0.235
        py = cy - S*0.05
        d.ellipse([cx-R, py-R, cx+R, py+R], fill=acc)
        # teardrop point
        d.polygon([(cx-R*0.62, py+R*0.78),(cx+R*0.62, py+R*0.78),(cx, py+R*1.62)], fill=acc)
        # plate (light ring) in pin head
        pr = R*0.66
        d.ellipse([cx-pr, py-pr, cx+pr, py+pr], fill=light)
        d.ellipse([cx-pr*0.7, py-pr*0.7, cx+pr*0.7, py+pr*0.7], outline=(0,0,0,40), width=int(S*0.006))
        # fork (left) and knife (right) over the plate, in accent
        fx = cx - pr*0.30
        d.rounded_rectangle([fx-S*0.012, py-pr*0.5, fx+S*0.012, py+pr*0.55], radius=S*0.01, fill=acc)
        for k in (-1,0,1):
            tx = fx + k*S*0.018
            d.line([(tx, py-pr*0.5),(tx, py-pr*0.18)], fill=acc, width=int(S*0.008))
        kx = cx + pr*0.32
        d.rounded_rectangle([kx-S*0.012, py-pr*0.5, kx+S*0.014, py+pr*0.55], radius=S*0.01, fill=acc)
        d.ellipse([kx-S*0.020, py-pr*0.56, kx+S*0.020, py-pr*0.16], fill=acc)
        # a small star badge bottom-right (ranking)
        sr = S*0.075
        sx, sy = cx+S*0.18, py+S*0.16
        pts = []
        for i in range(10):
            rr = sr if i % 2 == 0 else sr*0.46
            a = math.radians(i*36 - 90)
            pts.append((sx+rr*math.cos(a), sy+rr*math.sin(a)))
        d.polygon(pts, fill=accL(0.45))
    elif motif == "controller":
        # a game controller silhouette: rounded body, d-pad + buttons
        bw, bh = S*0.56, S*0.30
        x0, y0 = cx-bw/2, cy-bh/2
        d.rounded_rectangle([x0, y0, x0+bw, y0+bh], radius=bh*0.42, fill=light)
        # grips bulge
        d.ellipse([x0-S*0.02, y0+bh*0.1, x0+bw*0.34, y0+bh*1.05], fill=light)
        d.ellipse([x0+bw*0.66, y0+bh*0.1, x0+bw+S*0.02, y0+bh*1.05], fill=light)
        # d-pad (left) in accent
        dpx, dpy = cx-bw*0.26, cy
        arm = S*0.045; thick = S*0.030
        d.rounded_rectangle([dpx-thick, dpy-arm, dpx+thick, dpy+arm], radius=S*0.008, fill=acc)
        d.rounded_rectangle([dpx-arm, dpy-thick, dpx+arm, dpy+thick], radius=S*0.008, fill=acc)
        # four face buttons (right)
        btx, bty = cx+bw*0.26, cy
        off = S*0.052; br = S*0.028
        cols = [(232,99,90),(236,191,80),(108,196,150),(110,150,236)]
        for (ddx,ddy),col in zip([(0,-off),(off,0),(0,off),(-off,0)], cols):
            d.ellipse([btx+ddx-br, bty+ddy-br, btx+ddx+br, bty+ddy+br], fill=col+(255,))
        # center accent glow line
        d.line([(cx, y0+bh*0.18),(cx, y0+bh*0.82)], fill=(accent[0],accent[1],accent[2],120), width=int(S*0.006))
    elif motif == "bowl":
        # a singing bowl with concentric sound ripples rising (meditation)
        # ripples
        for i, rad in enumerate([0.40, 0.32, 0.24]):
            a = int(70 - i*18)
            d.arc([cx-S*rad, cy-S*rad-S*0.10, cx+S*rad, cy+S*rad-S*0.10],
                  200, 340, fill=(accent[0],accent[1],accent[2],a), width=int(S*0.012))
        # bowl body (half ellipse)
        bw, bh = S*0.40, S*0.24
        by = cy + S*0.14
        bowl = Image.new("RGBA",(int(bw),int(bh*2)),(0,0,0,0))
        bd = ImageDraw.Draw(bowl)
        bd.ellipse([0,-bh, bw, bh], fill=accL(0.10))
        bowl = bowl.crop((0,int(bh),int(bw),int(bh*2)))
        img.paste(bowl,(int(cx-bw/2),int(by-bh/2)),bowl)
        # bowl rim
        d.ellipse([cx-bw/2, by-bh/2-S*0.012, cx+bw/2, by-bh/2+S*0.012], fill=light)
        # a small mallet dot resting on the rim
        d.ellipse([cx+bw*0.30, by-bh*0.55, cx+bw*0.30+S*0.05, by-bh*0.55+S*0.05], fill=light)
        # central rising dot (breath)
        d.ellipse([cx-S*0.03, cy-S*0.20, cx+S*0.03, cy-S*0.14], fill=accL(0.5))
    elif motif == "route":
        # two map pins joined by a dashed route + a paper plane
        def pin(px, py, r, col):
            d.ellipse([px-r, py-r, px+r, py+r], fill=col)
            d.polygon([(px-r*0.6, py+r*0.7),(px+r*0.6, py+r*0.7),(px, py+r*1.6)], fill=col)
            d.ellipse([px-r*0.34, py-r*0.34, px+r*0.34, py+r*0.34], fill=(12,14,18,255))
        a = (cx-S*0.20, cy+S*0.16)
        b = (cx+S*0.20, cy-S*0.14)
        # dashed curved route
        steps = 24
        for i in range(steps):
            t = i/steps
            # quadratic curve via control point
            ctrl = (cx, cy-S*0.30)
            mt = 1-t
            xx = mt*mt*a[0] + 2*mt*t*ctrl[0] + t*t*b[0]
            yy = mt*mt*a[1] + 2*mt*t*ctrl[1] + t*t*b[1]
            if i % 2 == 0:
                d.ellipse([xx-S*0.010, yy-S*0.010, xx+S*0.010, yy+S*0.010], fill=(245,244,240,220))
        pin(a[0], a[1], S*0.085, accL(0.35))
        pin(b[0], b[1], S*0.095, acc)
        # paper plane near top
        pxc, pyc = cx+S*0.02, cy-S*0.30
        d.polygon([(pxc-S*0.07, pyc-S*0.05),(pxc+S*0.09, pyc-S*0.10),(pxc+S*0.02, pyc+S*0.06)], fill=light)
        d.polygon([(pxc-S*0.07, pyc-S*0.05),(pxc+S*0.02, pyc+S*0.06),(pxc-S*0.01, pyc+S*0.02)], fill=(210,210,205,255))
    elif motif == "meeple":
        # the iconic board-game meeple token + a die
        # meeple body (head + torso + arms + legs)
        mc_x, mc_y = cx-S*0.06, cy
        sc = S*0.30
        col = acc
        # head
        d.ellipse([mc_x-sc*0.26, mc_y-sc*0.78, mc_x+sc*0.26, mc_y-sc*0.26], fill=col)
        # body trapezoid (torso + legs)
        d.polygon([
            (mc_x-sc*0.16, mc_y-sc*0.30),
            (mc_x+sc*0.16, mc_y-sc*0.30),
            (mc_x+sc*0.46, mc_y+sc*0.30),
            (mc_x+sc*0.16, mc_y+sc*0.30),
            (mc_x+sc*0.07, mc_y+sc*0.02),
            (mc_x-sc*0.07, mc_y+sc*0.02),
            (mc_x-sc*0.16, mc_y+sc*0.30),
            (mc_x-sc*0.46, mc_y+sc*0.30),
        ], fill=col)
        # die (top-right), light with accent pips
        dz = S*0.20
        dx, dy = cx+S*0.18, cy-S*0.20
        d.rounded_rectangle([dx-dz/2, dy-dz/2, dx+dz/2, dy+dz/2], radius=dz*0.18, fill=light)
        for (ox,oy) in [(-0.26,-0.26),(0.26,-0.26),(0,0),(-0.26,0.26),(0.26,0.26)]:
            r = dz*0.07
            d.ellipse([dx+ox*dz-r, dy+oy*dz-r, dx+ox*dz+r, dy+oy*dz+r], fill=accL(0.0))
    elif motif == "grid":
        # a sudoku 9x9 grid with a few accent-filled cells + a soft "9"
        g = S*0.52
        x0, y0 = cx-g/2, cy-g/2
        cell = g/9
        # filled accent cells (a pleasing diagonal)
        fills = [(0,0),(4,4),(8,8),(2,6),(6,2),(4,0),(0,4),(8,4),(4,8)]
        for (cxi, cyi) in fills:
            fx, fy = x0+cxi*cell, y0+cyi*cell
            t = 0.12 + ((cxi+cyi) % 5)*0.10
            d.rounded_rectangle([fx+cell*0.10, fy+cell*0.10, fx+cell*0.90, fy+cell*0.90],
                                radius=cell*0.16, fill=accL(t))
        # thin gridlines
        for i in range(10):
            w = int(S*0.012) if i % 3 == 0 else int(S*0.004)
            col = light if i % 3 == 0 else (245,244,240,110)
            d.line([(x0+i*cell, y0),(x0+i*cell, y0+g)], fill=col, width=w)
            d.line([(x0, y0+i*cell),(x0+g, y0+i*cell)], fill=col, width=w)

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
