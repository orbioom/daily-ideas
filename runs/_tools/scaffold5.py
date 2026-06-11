#!/usr/bin/env python3
"""Orbioom iOS scaffold v5: config boilerplate + on-brand 1024 app icon.

Generates Assets (icon, AccentColor, LaunchBackground), Info.plist, project.yml,
Preview assets. Swift sources are authored separately.

Motifs for the 2026-06-11_2253 run:
  moonwave (snore), ladder (job tracker), mic (speech coach),
  tag (reseller), hearts (baby names), horizon (FIRE planner)

Usage:
  python3 scaffold5.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif> [extras...]
  extras: mic speech bgaudio
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

# ---- Icon (drawn at 2048, LANCZOS-downscaled to 1024 for antialiasing) ----
def make_icon(path):
    S = 2048
    img = Image.new("RGB", (S, S), (0,0,0))
    px = img.load()
    # per-motif background gradient
    bgs = {
        "moonwave": ("1A2240", "0C101F"),
        "ladder":   ("F4F1E8", "E4DFD0"),
        "mic":      ("241B33", "120D1C"),
        "tag":      ("FFF4E4", "F4DFC2"),
        "hearts":   ("FFEFF3", "FBD9E3"),
        "horizon":  ("0F3A44", "081E24"),
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
    ink = (32, 36, 48, 255)

    if motif == "moonwave":
        # crescent moon upper-left, soft sound waves lower-right
        mx, my, r = S*0.40, S*0.36, S*0.205
        d.ellipse([mx-r, my-r, mx+r, my+r], fill=(247, 222, 165, 255))
        # bite to make crescent (use bg color)
        bx, by = mx + r*0.52, my - r*0.42
        d.ellipse([bx-r*0.92, by-r*0.92, bx+r*0.92, by+r*0.92], fill=lerp(top,bot,0.30)+ (255,))
        # three breathing arcs
        for i, (rr, w, al) in enumerate([(S*0.30, 44, 235), (S*0.40, 36, 165), (S*0.50, 30, 100)]):
            box = [S*0.62-rr, S*0.66-rr, S*0.62+rr, S*0.66+rr]
            d.arc(box, start=295, end=55, fill=(acc[0],acc[1],acc[2],al), width=w)
        # zzz dots
        for i in range(3):
            zr = 26 - i*5
            zx, zy = S*0.70 + i*S*0.055, S*0.30 - i*S*0.055
            d.ellipse([zx-zr, zy-zr, zx+zr, zy+zr], fill=(247,222,165,200-50*i))
    elif motif == "ladder":
        # ascending stair-steps with a flag on top — the climb to an offer
        d.rounded_rectangle([S*0.16, S*0.16, S*0.84, S*0.84], radius=80, fill=(255,255,255,90))
        steps = 4
        x0, y0 = S*0.22, S*0.78
        sw, sh = S*0.14, S*0.14
        for i in range(steps):
            d.rounded_rectangle(
                [x0 + i*sw, y0 - (i+1)*sh, x0 + (i+1)*sw + (S*0.02 if i==steps-1 else 0), y0],
                radius=24, fill=(acc[0],acc[1],acc[2],255) if i==steps-1 else ink)
        # flag pole + pennant on the top step
        fx = x0 + steps*sw - sw*0.30
        ftop = y0 - steps*sh - S*0.16
        d.line([(fx, y0 - steps*sh), (fx, ftop)], fill=ink, width=26)
        d.polygon([(fx+13, ftop), (fx+13+S*0.13, ftop+S*0.045), (fx+13, ftop+S*0.09)], fill=acc)
    elif motif == "mic":
        # spotlight cone + microphone
        d.polygon([(cx, S*0.06), (S*0.10, S*0.96), (S*0.90, S*0.96)], fill=(255,255,255,26))
        body_w, body_h = S*0.155, S*0.23
        bx0, by0 = cx-body_w, S*0.30
        d.rounded_rectangle([bx0, by0, cx+body_w, by0+body_h*1.7], radius=int(body_w), fill=light)
        # grill lines
        for i in range(3):
            yy = by0 + 60 + i*78
            d.line([(bx0+44, yy), (cx+body_w-44, yy)], fill=(170,176,192,255), width=22)
        # cradle arc + stem + base
        ar = body_w*1.55
        d.arc([cx-ar, by0+body_h*0.62, cx+ar, by0+body_h*0.62+2*ar], start=20, end=160,
              fill=acc, width=56)
        d.line([(cx, by0+body_h*0.62+2*ar - 30), (cx, S*0.82)], fill=acc, width=56)
        d.line([(cx-S*0.11, S*0.82), (cx+S*0.11, S*0.82)], fill=acc, width=56)
    elif motif == "tag":
        # rotated price tag with an upward profit arrow
        tag = Image.new("RGBA", (S, S), (0,0,0,0))
        td = ImageDraw.Draw(tag)
        w, h = S*0.52, S*0.34
        x0, y0 = cx - w*0.42, cy - h*0.5
        td.rounded_rectangle([x0, y0, x0+w, y0+h], radius=60, fill=acc)
        td.polygon([(x0, y0), (x0 - h*0.42, y0 + h*0.5), (x0, y0+h)], fill=acc)
        td.ellipse([x0 - h*0.16 - 38, cy - 38, x0 - h*0.16 + 38, cy + 38], fill=lerp(hx("FFF4E4"),hx("F4DFC2"),0.5)+(255,))
        tag = tag.rotate(18, center=(cx, cy), resample=Image.BICUBIC)
        img.paste(tag, (0,0), tag)
        # profit arrow over the tag
        pts = [(S*0.33, S*0.66), (S*0.47, S*0.52), (S*0.56, S*0.60), (S*0.72, S*0.40)]
        d.line(pts, fill=(255,255,255,255), width=52, joint="curve")
        d.polygon([(S*0.72+70, S*0.40-26), (S*0.72-10, S*0.40-110), (S*0.62, S*0.40+8)], fill=(255,255,255,255))
    elif motif == "hearts":
        # two overlapping hearts — partner A and partner B agreeing
        def heart(dd, hx_, hy, s, col):
            dd.polygon([(hx_, hy + s*1.02), (hx_-s, hy + s*0.18), (hx_+s, hy + s*0.18)], fill=col)
            dd.ellipse([hx_-s, hy-s*0.42, hx_, hy+s*0.58], fill=col)
            dd.ellipse([hx_, hy-s*0.42, hx_+s, hy+s*0.58], fill=col)
        layer = Image.new("RGBA", (S, S), (0,0,0,0))
        ld = ImageDraw.Draw(layer)
        heart(ld, S*0.40, S*0.40, S*0.185, (126, 168, 245, 235))
        layer2 = Image.new("RGBA", (S, S), (0,0,0,0))
        ld2 = ImageDraw.Draw(layer2)
        heart(ld2, S*0.585, S*0.475, S*0.185, (acc[0], acc[1], acc[2], 235))
        img.paste(layer, (0,0), layer)
        img.paste(layer2, (0,0), layer2)
        # sparkle where they overlap
        sx, sy, sr = S*0.495, S*0.43, S*0.030
        for ang in range(4):
            a = math.radians(ang*90)
            d.line([(sx - sr*2.6*math.cos(a), sy - sr*2.6*math.sin(a)),
                    (sx + sr*2.6*math.cos(a), sy + sr*2.6*math.sin(a))], fill=(255,255,255,240), width=30)
        d.ellipse([sx-sr, sy-sr, sx+sr, sy+sr], fill=(255,255,255,255))
    elif motif == "horizon":
        # sun over the sea, gentle swell line — coasting to FI
        d.ellipse([cx-S*0.16, S*0.30-S*0.16, cx+S*0.16, S*0.30+S*0.16], fill=(250, 215, 130, 255))
        # sea
        d.rectangle([0, S*0.55, S, S], fill=(13, 60, 70, 255))
        # reflected shimmer
        for i in range(4):
            ww = S*0.20 - i*S*0.035
            d.line([(cx-ww, S*0.60 + i*S*0.07), (cx+ww, S*0.60 + i*S*0.07)],
                   fill=(250, 215, 130, 170-35*i), width=34)
        # swell curve in accent
        pts = []
        for k in range(0, 101):
            x = S*k/100
            y = S*0.55 + math.sin(k/100*math.pi*2)*S*0.018
            pts.append((x, y))
        d.line(pts, fill=acc, width=44, joint="curve")
    img = img.resize((1024, 1024), Image.LANCZOS)
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
    "moonwave": ((250, 250, 252), (12, 16, 31)),
    "ladder":   ((247, 244, 235), (20, 21, 26)),
    "mic":      ((250, 249, 252), (18, 13, 28)),
    "tag":      ((255, 248, 238), (24, 19, 14)),
    "hearts":   ((255, 247, 249), (26, 18, 22)),
    "horizon":  ((246, 251, 250), (8, 24, 28)),
}
lb = launch_bgs.get(motif, ((250,250,250), (15,16,20)))
write(os.path.join(assets, "LaunchBackground.colorset", "Contents.json"),
      color_json(*lb))

write(os.path.join(app_dir, "Preview Content", "Preview Assets.xcassets", "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

# ---- Info.plist ----
extra_keys = ""
if "mic" in extras:
    extra_keys += """	<key>NSMicrophoneUsageDescription</key>
	<string>%s uses the microphone to analyze sound levels on your device. Audio is processed locally and never uploaded.</string>
""" % App
if "speech" in extras:
    extra_keys += """	<key>NSSpeechRecognitionUsageDescription</key>
	<string>%s transcribes your practice speeches on this device so it can count filler words and measure pace. Nothing leaves your iPhone.</string>
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

# ---- project.yml ----
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
