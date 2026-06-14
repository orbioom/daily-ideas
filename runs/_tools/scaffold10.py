#!/usr/bin/env python3
"""Orbioom iOS scaffold v10: config boilerplate + on-brand 1024 app icon.

Generates Assets (icon, AccentColor, LaunchBackground), Info.plist, project.yml,
Preview assets. Swift sources are authored separately.

Motifs for the 2026-06-14 midday run:
  anime (Senpai/anime+manga tracker), bottle (Sillage/fragrance wardrobe),
  knight (Rook/chess tactics), shield (Tessera/TOTP authenticator),
  crossword (Across/daily mini crossword), vinyl (Crate/vinyl collection)

Usage:
  python3 scaffold10.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif> [extras...]
  extras: photos  faceid
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
        "anime":     ("241433", "0E0717"),
        "bottle":    ("2A2012", "120C05"),
        "knight":    ("13241E", "07120E"),
        "shield":    ("141A33", "070A18"),
        "crossword": ("1C2330", "0A0E15"),
        "vinyl":     ("2A1810", "120906"),
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
    def accD(t):  # accent darkened toward black
        c = lerp(accent, (0,0,0), t)
        return (c[0], c[1], c[2], 255)

    if motif == "anime":
        # a rounded screen/card with a bold play triangle + a sparkle (streaming + star rating)
        cw, ch = S*0.52, S*0.40
        x0, y0 = cx-cw/2, cy-ch/2 - S*0.02
        d.rounded_rectangle([x0, y0, x0+cw, y0+ch], radius=S*0.06, fill=light)
        d.rounded_rectangle([x0, y0, x0+cw, y0+ch], radius=S*0.06, outline=accL(0.2), width=int(S*0.012))
        # play triangle in accent
        tr = S*0.11
        d.polygon([(cx-tr*0.7, cy-tr-S*0.02),(cx-tr*0.7, cy+tr-S*0.02),(cx+tr*0.95, cy-S*0.02)], fill=acc)
        # four-point sparkle top-right
        def sparkle(sx, sy, r, col):
            d.polygon([(sx, sy-r),(sx+r*0.28, sy-r*0.28),(sx+r, sy),(sx+r*0.28, sy+r*0.28),
                       (sx, sy+r),(sx-r*0.28, sy+r*0.28),(sx-r, sy),(sx-r*0.28, sy-r*0.28)], fill=col)
        sparkle(cx+S*0.20, cy-S*0.27, S*0.075, accL(0.4))
        sparkle(cx-S*0.225, cy+S*0.255, S*0.045, accL(0.55))
    elif motif == "bottle":
        # a faceted perfume flacon with a cap and a rising scent trail (sillage)
        # scent trail (wavy dashed) rising from the neck
        for i in range(7):
            t = i/7.0
            yy = cy - S*0.14 - t*S*0.28
            xx = cx + math.sin(t*6.28)*S*0.05
            a = int(150*(1-t))
            r = S*0.018*(1-0.4*t)
            d.ellipse([xx-r, yy-r, xx+r, yy+r], fill=(accent[0],accent[1],accent[2],a))
        # bottle body (rounded-square flacon)
        bw, bh = S*0.34, S*0.34
        bx, by = cx-bw/2, cy-S*0.02
        d.rounded_rectangle([bx, by, bx+bw, by+bh], radius=S*0.05, fill=acc)
        # glass highlight
        d.rounded_rectangle([bx+bw*0.16, by+bh*0.12, bx+bw*0.40, by+bh*0.78], radius=S*0.03, fill=accL(0.35))
        # neck + cap
        nw = bw*0.34
        d.rectangle([cx-nw/2, by-S*0.05, cx+nw/2, by+S*0.01], fill=accD(0.15))
        d.rounded_rectangle([cx-nw*0.72, by-S*0.13, cx+nw*0.72, by-S*0.045], radius=S*0.018, fill=light)
        # a small label band
        d.rounded_rectangle([bx+bw*0.20, by+bh*0.52, bx+bw*0.80, by+bh*0.74], radius=S*0.014, fill=light)
    elif motif == "knight":
        # a chess knight silhouette on a roundel + a small board corner
        # roundel
        R = S*0.255
        d.ellipse([cx-R, cy-R, cx+R, cy+R], fill=accD(0.10))
        d.ellipse([cx-R, cy-R, cx+R, cy+R], outline=accL(0.25), width=int(S*0.012))
        # stylized knight (horse head) as a polygon, in light
        k = S*0.018
        pts = [
            (cx-2*k, cy+9*k),   # base left
            (cx-2*k, cy+5*k),
            (cx-5*k, cy+2*k),
            (cx-6*k, cy-3*k),   # chest
            (cx-3*k, cy-3*k),
            (cx-4*k, cy-7*k),   # snout up
            (cx-1*k, cy-9*k),
            (cx+2*k, cy-10*k),  # ears/forelock
            (cx+1*k, cy-7*k),
            (cx+5*k, cy-6*k),   # mane back
            (cx+6*k, cy-1*k),
            (cx+5*k, cy+4*k),
            (cx+6*k, cy+9*k),   # base right
        ]
        d.polygon(pts, fill=light)
        # eye
        d.ellipse([cx-3.2*k, cy-5.0*k, cx-1.8*k, cy-3.6*k], fill=accD(0.2))
        # base plinth
        d.rounded_rectangle([cx-7*k, cy+8.4*k, cx+7*k, cy+10.4*k], radius=k, fill=light)
    elif motif == "shield":
        # a security shield with a keyhole + a rotating dashed countdown ring (TOTP)
        # dashed ring around
        rr = S*0.27
        for i in range(28):
            a0 = i*(360/28)
            if i % 2 == 0:
                d.arc([cx-rr, cy-rr, cx+rr, cy+rr], a0, a0+ (360/28)*0.6,
                      fill=(accent[0],accent[1],accent[2],200), width=int(S*0.018))
        # shield body
        sw, sh = S*0.30, S*0.34
        topy = cy - sh*0.52
        pts = [
            (cx-sw/2, topy+sh*0.10),
            (cx, topy-sh*0.04),
            (cx+sw/2, topy+sh*0.10),
            (cx+sw/2, topy+sh*0.55),
            (cx, topy+sh*1.02),
            (cx-sw/2, topy+sh*0.55),
        ]
        d.polygon(pts, fill=acc)
        # inner shield highlight
        d.polygon([(cx-sw*0.34, topy+sh*0.18),(cx, topy+sh*0.06),(cx, topy+sh*0.82)], fill=accL(0.22))
        # keyhole in light
        kr = S*0.045
        d.ellipse([cx-kr, cy-kr-S*0.02, cx+kr, cy+kr-S*0.02], fill=light)
        d.polygon([(cx-kr*0.6, cy-S*0.005),(cx+kr*0.6, cy-S*0.005),(cx+kr*0.95, cy+S*0.075),(cx-kr*0.95, cy+S*0.075)], fill=light)
    elif motif == "crossword":
        # a crossword grid (some black cells) with two letters + numbers
        g = S*0.52
        x0, y0 = cx-g/2, cy-g/2
        n = 5
        cell = g/n
        black = {(0,1),(1,3),(2,0),(3,2),(3,4),(4,1)}
        for r in range(n):
            for c in range(n):
                fx, fy = x0+c*cell, y0+r*cell
                if (r,c) in black:
                    d.rectangle([fx, fy, fx+cell, fy+cell], fill=ink)
                else:
                    d.rectangle([fx, fy, fx+cell, fy+cell], fill=light)
        # accent-filled letters cells
        for (r,c) in [(0,0),(2,2),(4,4)]:
            fx, fy = x0+c*cell, y0+r*cell
            d.rectangle([fx, fy, fx+cell, fy+cell], fill=accL(0.05))
        # gridlines
        for i in range(n+1):
            w = int(S*0.006)
            d.line([(x0+i*cell, y0),(x0+i*cell, y0+g)], fill=(40,44,52,180), width=w)
            d.line([(x0, y0+i*cell),(x0+g, y0+i*cell)], fill=(40,44,52,180), width=w)
        # outer frame
        d.rectangle([x0, y0, x0+g, y0+g], outline=ink, width=int(S*0.014))
    elif motif == "vinyl":
        # a vinyl record disc with grooves, accent label, center hole + a light highlight
        R = S*0.27
        d.ellipse([cx-R, cy-R, cx+R, cy+R], fill=(18,18,20,255))
        # grooves
        for i in range(6):
            gr = R*(0.94 - i*0.085)
            d.ellipse([cx-gr, cy-gr, cx+gr, cy+gr], outline=(70,70,74,180), width=int(S*0.004))
        # specular highlight sweep
        d.pieslice([cx-R, cy-R, cx+R, cy+R], 205, 250, fill=(255,255,255,28))
        # accent label
        lr = R*0.36
        d.ellipse([cx-lr, cy-lr, cx+lr, cy+lr], fill=acc)
        d.ellipse([cx-lr, cy-lr, cx+lr, cy+lr], outline=accL(0.25), width=int(S*0.006))
        # center spindle hole
        hr = S*0.016
        d.ellipse([cx-hr, cy-hr, cx+hr, cy+hr], fill=(18,18,20,255))

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
	<string>The camera is used only to scan QR codes you point it at. Nothing is uploaded or stored without your action.</string>"""
if "faceid" in extras:
    plist_extra += """
	<key>NSFaceIDUsageDescription</key>
	<string>Face ID unlocks your private vault on this device. Your data never leaves your phone.</string>"""

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
