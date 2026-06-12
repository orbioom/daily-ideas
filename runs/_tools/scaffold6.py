#!/usr/bin/env python3
"""Orbioom iOS scaffold v6: config boilerplate + on-brand 1024 app icon.

Generates Assets (icon, AccentColor, LaunchBackground), Info.plist, project.yml,
Preview assets. Swift sources are authored separately.

Motifs for the 2026-06-12 run:
  footsteps (Tread/steps), controller (Checkpoint/game backlog),
  spark (Beckon/manifestation 369), cup (Crema/espresso dial-in),
  moon (Reverie/dream journal), apron (Apron/tip tracker)

Usage:
  python3 scaffold6.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif> [extras...]
  extras: motion mic location bgaudio
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
        "footsteps": ("0E3B2E", "06231A"),
        "controller": ("2A1B45", "150C24"),
        "spark":     ("241A40", "120C22"),
        "cup":       ("3A2417", "201009"),
        "moon":      ("1B2150", "0B0E26"),
        "apron":     ("0E3B36", "06211E"),
    }
    top, bot = (hx(x) for x in bgs.get(motif, ("23262F", "121419")))
    for y in range(S):
        row = lerp(top, bot, y / S)
        for x in range(S):
            px[x, y] = row
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = S*0.5, S*0.5
    acc = (accent[0], accent[1], accent[2], 255)
    light = (245, 247, 252, 255)
    ink = (28, 30, 40, 255)

    if motif == "footsteps":
        # two stylized footprints ascending, with a goal ring behind
        ring_r = S*0.30
        d.arc([cx-ring_r, cy-ring_r, cx+ring_r, cy+ring_r], start=130, end=410,
              fill=(acc[0],acc[1],acc[2],150), width=46)
        def foot(fx, fy, col, scale=1.0, rot=0):
            layer = Image.new("RGBA", (S, S), (0,0,0,0))
            ld = ImageDraw.Draw(layer)
            w, h = S*0.115*scale, S*0.20*scale
            # heel/ball as a rounded sole
            ld.ellipse([fx-w*0.5, fy-h*0.5, fx+w*0.5, fy+h*0.5], fill=col)
            ld.ellipse([fx-w*0.62, fy-h*0.62, fx+w*0.30, fy-h*0.05], fill=col)
            # toes
            for i,(ox,oy,rr) in enumerate([(-0.42,-0.78,0.20),(-0.12,-0.92,0.18),(0.16,-0.92,0.16),(0.40,-0.84,0.14),(0.58,-0.70,0.12)]):
                ld.ellipse([fx+ox*w-rr*w*0.5, fy+oy*h-rr*w*0.5, fx+ox*w+rr*w*0.5, fy+oy*h+rr*w*0.5], fill=col)
            layer = layer.rotate(rot, center=(fx,fy), resample=Image.BICUBIC)
            img.paste(layer, (0,0), layer)
        foot(S*0.40, S*0.62, light, 1.0, 14)
        foot(S*0.585, S*0.45, acc, 1.0, 14)
    elif motif == "controller":
        # game controller silhouette
        body = Image.new("RGBA", (S, S), (0,0,0,0))
        bd = ImageDraw.Draw(body)
        w, h = S*0.56, S*0.30
        x0, y0 = cx - w*0.5, cy - h*0.4
        bd.rounded_rectangle([x0, y0, x0+w, y0+h], radius=int(h*0.5), fill=light)
        # grips
        bd.ellipse([x0-S*0.02, y0+h*0.25, x0+S*0.20, y0+h+S*0.14], fill=light)
        bd.ellipse([x0+w-S*0.20, y0+h*0.25, x0+w+S*0.02, y0+h+S*0.14], fill=light)
        img.paste(body, (0,0), body)
        # d-pad (accent)
        dx, dy, t = x0+w*0.26, y0+h*0.52, S*0.028
        d.rounded_rectangle([dx-t*2.4, dy-t, dx+t*2.4, dy+t], radius=12, fill=acc)
        d.rounded_rectangle([dx-t, dy-t*2.4, dx+t, dy+t*2.4], radius=12, fill=acc)
        # buttons
        br = S*0.030
        for ox,oy in [(0.0,-0.052),(0.052,0.0),(0.0,0.052),(-0.052,0.0)]:
            bxx, byy = x0+w*0.74+ox*S, dy+oy*S
            d.ellipse([bxx-br,byy-br,bxx+br,byy+br], fill=acc)
    elif motif == "spark":
        # radiant 4-point star / spark of manifestation with orbiting dots
        def sparkle(sx, sy, R, col):
            pts = []
            for k in range(8):
                ang = math.radians(k*45)
                rr = R if k % 2 == 0 else R*0.30
                pts.append((sx+rr*math.cos(ang), sy+rr*math.sin(ang)))
            d.polygon(pts, fill=col)
        sparkle(cx, cy, S*0.235, acc)
        sparkle(cx, cy, S*0.10, light)
        for (ox,oy,rr,al) in [(-0.31,-0.24,0.030,235),(0.32,-0.28,0.022,200),(0.28,0.30,0.026,210),(-0.30,0.30,0.018,180)]:
            dx2, dy2 = cx+ox*S, cy+oy*S
            d.ellipse([dx2-rr*S,dy2-rr*S,dx2+rr*S,dy2+rr*S], fill=(247,232,180,al))
        # faint orbit ring
        orb=S*0.345
        d.arc([cx-orb,cy-orb,cx+orb,cy+orb], start=0, end=360, fill=(acc[0],acc[1],acc[2],70), width=14)
    elif motif == "cup":
        # espresso cup with crema crescent and rising steam
        # saucer
        d.ellipse([cx-S*0.30, S*0.70, cx+S*0.30, S*0.80], fill=(235,228,214,255))
        # cup body
        cw, ch = S*0.40, S*0.30
        x0, y0 = cx-cw*0.5, S*0.40
        d.rounded_rectangle([x0, y0, x0+cw, y0+ch], radius=40, fill=light)
        d.rounded_rectangle([x0+8, y0+8, x0+cw-8, y0+ch-8], radius=34, fill=(238,232,222,255))
        # crema (accent) ellipse near the top rim
        d.ellipse([x0+24, y0+18, x0+cw-24, y0+18+S*0.085], fill=acc)
        d.ellipse([x0+44, y0+24, x0+cw-44, y0+24+S*0.055], fill=lerp(accent,(255,255,255),0.28)+(255,))
        # handle
        d.arc([x0+cw-30, y0+30, x0+cw+S*0.13, y0+ch-20], start=300, end=70, fill=light, width=40)
        # steam
        for sx in (cx-S*0.06, cx+S*0.06):
            pts=[]
            for k in range(0,41):
                t=k/40
                pts.append((sx+math.sin(t*math.pi*2)*S*0.022, S*0.38 - t*S*0.16))
            d.line(pts, fill=(235,228,214,150), width=18, joint="curve")
    elif motif == "moon":
        # crescent moon cradling stars (dream)
        mx, my, r = cx+S*0.04, cy-S*0.02, S*0.245
        d.ellipse([mx-r, my-r, mx+r, my+r], fill=acc)
        bx, by = mx + r*0.55, my - r*0.30
        d.ellipse([bx-r*0.96, by-r*0.96, bx+r*0.96, by+r*0.96], fill=lerp(hx("1B2150"),hx("0B0E26"),0.40)+(255,))
        def star(sx, sy, R, col):
            pts=[]
            for k in range(8):
                ang=math.radians(k*45 - 90)
                rr=R if k%2==0 else R*0.4
                pts.append((sx+rr*math.cos(ang), sy+rr*math.sin(ang)))
            d.polygon(pts, fill=col)
        star(cx-S*0.20, cy-S*0.18, S*0.045, light)
        star(cx-S*0.27, cy+S*0.10, S*0.030, (236,232,255,235))
        star(cx-S*0.10, cy+S*0.26, S*0.024, (236,232,255,210))
    elif motif == "apron":
        # apron silhouette with a coin (tipped earnings)
        ap = Image.new("RGBA", (S, S), (0,0,0,0))
        ad = ImageDraw.Draw(ap)
        # bib
        ad.rounded_rectangle([cx-S*0.13, S*0.26, cx+S*0.13, S*0.44], radius=30, fill=light)
        # skirt (trapezoid via polygon, rounded-ish)
        ad.polygon([(cx-S*0.13,S*0.42),(cx+S*0.13,S*0.42),(cx+S*0.225,S*0.78),(cx-S*0.225,S*0.78)], fill=light)
        ad.rounded_rectangle([cx-S*0.225, S*0.74, cx+S*0.225, S*0.80], radius=24, fill=light)
        # neck strap + ties
        ad.arc([cx-S*0.12, S*0.16, cx+S*0.12, S*0.34], start=200, end=340, fill=light, width=30)
        ad.line([(cx-S*0.13,S*0.30),(cx-S*0.27,S*0.40)], fill=light, width=30)
        ad.line([(cx+S*0.13,S*0.30),(cx+S*0.27,S*0.40)], fill=light, width=30)
        img.paste(ap, (0,0), ap)
        # coin with $ over the pocket
        cr=S*0.105
        ccx, ccy = cx, S*0.575
        d.ellipse([ccx-cr,ccy-cr,ccx+cr,ccy+cr], fill=acc)
        d.ellipse([ccx-cr*0.78,ccy-cr*0.78,ccx+cr*0.78,ccy+cr*0.78], fill=lerp(accent,(0,0,0),0.12)+(255,))
        d.line([(ccx, ccy-cr*0.55),(ccx, ccy+cr*0.55)], fill=light, width=26)
        d.arc([ccx-cr*0.42, ccy-cr*0.52, ccx+cr*0.42, ccy-cr*0.02], start=20, end=210, fill=light, width=22)
        d.arc([ccx-cr*0.42, ccy+cr*0.02, ccx+cr*0.42, ccy+cr*0.52], start=200, end=30, fill=light, width=22)
    img = img.resize((1024, 1024), Image.LANCZOS).convert("RGBA")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")

assets = os.path.join(app_dir, "Assets.xcassets")
make_icon(os.path.join(assets, "AppIcon.appiconset", "icon-1024.png"))
write(os.path.join(assets, "AppIcon.appiconset", "Contents.json"), json.dumps({
    "images": [{"filename": "icon-1024.png", "idiom": "universal",
                "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1}}, indent=2))
write(os.path.join(assets, "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

def color_json(rgb_light, rgb_dark):
    def comp(rgb):
        return {"color-space": "srgb", "components": {
            "red": f"{rgb[0]/255:.3f}", "green": f"{rgb[1]/255:.3f}",
            "blue": f"{rgb[2]/255:.3f}", "alpha": "1.000"}}
    return json.dumps({
        "colors": [
            {"color": comp(rgb_light), "idiom": "universal"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}],
             "color": comp(rgb_dark), "idiom": "universal"},
        ],
        "info": {"author": "xcode", "version": 1}}, indent=2)

write(os.path.join(assets, "AccentColor.colorset", "Contents.json"),
      color_json(accent, lerp(accent, (255,255,255), 0.12)))

launch_bgs = {
    "footsteps": ((244, 249, 246), (8, 26, 21)),
    "controller": ((247, 245, 251), (18, 12, 30)),
    "spark":     ((248, 246, 252), (16, 12, 32)),
    "cup":       ((250, 246, 240), (24, 16, 11)),
    "moon":      ((245, 247, 252), (10, 13, 33)),
    "apron":     ((244, 250, 248), (8, 28, 25)),
}
lb = launch_bgs.get(motif, ((250,250,250), (15,16,20)))
write(os.path.join(assets, "LaunchBackground.colorset", "Contents.json"),
      color_json(*lb))

write(os.path.join(app_dir, "Preview Content", "Preview Assets.xcassets", "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

extra_keys = ""
if "motion" in extras:
    extra_keys += """	<key>NSMotionUsageDescription</key>
	<string>%s reads your step count and walking distance from the on-device motion sensor. This data stays on your iPhone.</string>
""" % App
if "mic" in extras:
    extra_keys += """	<key>NSMicrophoneUsageDescription</key>
	<string>%s uses the microphone to analyze sound on your device. Audio is processed locally and never uploaded.</string>
""" % App
if "location" in extras:
    extra_keys += """	<key>NSLocationWhenInUseUsageDescription</key>
	<string>%s uses your location while you record a trip to measure the distance driven. Location is used only during an active trip and never uploaded.</string>
""" % App
if "bgaudio" in extras:
    extra_keys += """	<key>UIBackgroundModes</key>
	<array>
		<string>audio</string>
	</array>
"""

write(os.path.join(app_dir, "Info.plist"), """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>%(App)s</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>%(App)s</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
%(extra)s	<key>UILaunchScreen</key>
	<dict>
		<key>UIColorName</key>
		<string>LaunchBackground</string>
	</dict>
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>armv7</string>
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
""" % {"App": App, "extra": extra_keys})

write(os.path.join(ios_dir, "project.yml"), """name: %(App)s
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  %(App)s:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - %(App)s
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.%(lower)s
        INFOPLIST_FILE: %(App)s/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        DEVELOPMENT_ASSET_PATHS: "\\"%(App)s/Preview Content\\""
""" % {"App": App, "lower": lower})

print(f"scaffolded {App} ({motif})")
