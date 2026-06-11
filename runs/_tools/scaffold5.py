#!/usr/bin/env python3
"""Orbioom iOS scaffold v5: shared config boilerplate + on-brand 1024 app icon.

Motifs for the 2026-06-11_2255 run:
  prompter (teleprompter), gauge (decibel meter), doc (scanner),
  horizon (FIRE planner), party (charades), lock (password vault)

Usage:
  python3 scaffold5.py <ios_dir> <App> <lower> <accentHexRRGGBB> <motif> [plist_extra] [orientation]
    plist_extra: comma-separated of mic,camera,faceid,photos  (or "-")
    orientation: "all" to allow landscape on iPhone (default portrait)
"""
import os, sys, json, math
from PIL import Image, ImageDraw, ImageFilter

ios_dir, App, lower, hexv, motif = sys.argv[1:6]
plist_extra = sys.argv[6] if len(sys.argv) > 6 else "-"
orientation = sys.argv[7] if len(sys.argv) > 7 else "portrait"
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

    if motif == "prompter":  # teleprompter — scrolling script lines, luminous focus band
        d.rounded_rectangle([cx-300, cy-300, cx+300, cy+320], radius=56, fill=(light[0],light[1],light[2],26), outline=silver, width=10)
        # focus band
        d.rounded_rectangle([cx-300, cy-66, cx+300, cy+66], radius=20, fill=(acc[0],acc[1],acc[2],60))
        rows = [(-240,170,90),(-180,260,90),(-120,210,90),(0,280,255),(110,230,90),(170,150,90),(230,260,90)]
        for (oy, w, alpha) in rows:
            col = acc if alpha == 255 else (silver[0],silver[1],silver[2],alpha)
            wd = 34 if alpha == 255 else 26
            d.rounded_rectangle([cx-w, cy+oy-wd/2, cx+w, cy+oy+wd/2], radius=wd//2, fill=col)
        # play wedge at right of focus band
        d.polygon([(cx+318, cy-44),(cx+318, cy+44),(cx+396, cy)], fill=acc)
    elif motif == "gauge":  # decibel meter — semicircular loudness gauge with needle + sound arcs
        # outer gauge arc
        d.arc([cx-310, cy-260, cx+310, cy+360], 180, 360, fill=silver, width=26)
        # colored zones (safe→loud)
        d.arc([cx-262, cy-212, cx+262, cy+312], 180, 252, fill=gr, width=46)
        d.arc([cx-262, cy-212, cx+262, cy+312], 252, 308, fill=(255,205,110,255), width=46)
        d.arc([cx-262, cy-212, cx+262, cy+312], 308, 360, fill=(255,118,118,255), width=46)
        # ticks
        for k in range(7):
            a = math.radians(180 + k*30)
            x0 = cx + 286*math.cos(a); y0 = cy+50 + 286*math.sin(a)
            x1 = cx + 322*math.cos(a); y1 = cy+50 + 322*math.sin(a)
            d.line([(x0,y0),(x1,y1)], fill=(silver[0],silver[1],silver[2],170), width=12)
        # needle at ~70%
        ang = math.radians(180 + 0.66*180)
        nx = cx + 240*math.cos(ang); ny = cy+50 + 240*math.sin(ang)
        d.line([(cx, cy+50),(nx, ny)], fill=acc, width=22)
        d.ellipse([cx-34, cy+16, cx+34, cy+84], fill=acc)
        d.ellipse([cx-14, cy+36, cx+14, cy+64], fill=(20,24,30,255))
    elif motif == "doc":  # scanner — page with text lines and a luminous scan beam
        d.rounded_rectangle([cx-220, cy-290, cx+220, cy+300], radius=36, fill=light)
        # folded corner
        d.polygon([(cx+220, cy-290),(cx+220, cy-170),(cx+100, cy-290)], fill=(silver[0],silver[1],silver[2],255))
        d.polygon([(cx+100, cy-290),(cx+220, cy-170),(cx+100, cy-170)], fill=(160,166,184,255))
        # text lines
        for k, w in enumerate([250, 300, 280, 180, 300, 260, 140]):
            yy = cy - 180 + k*64
            d.rounded_rectangle([cx-160, yy, cx-160+w*0.9, yy+26], radius=13, fill=(70,76,94,255))
        # luminous scan beam crossing the page
        d.rectangle([cx-280, cy-26, cx+280, cy+26], fill=(acc[0],acc[1],acc[2],90))
        d.rectangle([cx-280, cy-6, cx+280, cy+6], fill=acc)
        # beam end caps
        d.ellipse([cx-306, cy-22, cx-262, cy+22], fill=acc)
        d.ellipse([cx+262, cy-22, cx+306, cy+22], fill=acc)
    elif motif == "horizon":  # FIRE — sun over horizon + compounding growth curve
        # horizon line
        d.line([(cx-330, cy+150),(cx+330, cy+150)], fill=silver, width=14)
        # rising sun (half above horizon)
        d.pieslice([cx-150, cy-10, cx+150, cy+290], 180, 360, fill=(255,205,110,255))
        d.rectangle([cx-160, cy+140, cx+160, cy+300], fill=(0,0,0,0))
        # growth curve sweeping up across the sun
        pts = []
        for k in range(61):
            t = k/60
            x = cx - 320 + 640*t
            y = cy + 140 - 360*(math.pow(1.075, t*24)-1)/ (math.pow(1.075,24)-1)
            pts.append((x, y))
        d.line(pts, fill=acc, width=26, joint="curve")
        # end dot + small milestone dots
        d.ellipse([pts[-1][0]-30, pts[-1][1]-30, pts[-1][0]+30, pts[-1][1]+30], fill=acc)
        for f in (0.35, 0.62, 0.84):
            p = pts[int(f*60)]
            d.ellipse([p[0]-16, p[1]-16, p[0]+16, p[1]+16], fill=light)
    elif motif == "party":  # charades — tilted card with star burst + motion arcs
        ang = math.radians(-12)
        def rot(px_, py_):
            dx, dy = px_-cx, py_-cy
            return (cx+dx*math.cos(ang)-dy*math.sin(ang), cy+dx*math.sin(ang)+dy*math.cos(ang))
        corners = [rot(cx-270, cy-180), rot(cx+270, cy-180), rot(cx+270, cy+180), rot(cx-270, cy+180)]
        d.polygon(corners, fill=light)
        # word bar on card
        b0 = rot(cx-170, cy-30); b1 = rot(cx+170, cy+30)
        d.rounded_rectangle([min(b0[0],b1[0]), min(b0[1],b1[1]), max(b0[0],b1[0]), max(b0[1],b1[1])], radius=28, fill=acc)
        # tilt arcs above and below (motion)
        d.arc([cx-360, cy-380, cx+360, cy+340], 230, 290, fill=(silver[0],silver[1],silver[2],190), width=18)
        d.arc([cx-420, cy-440, cx+420, cy+400], 235, 285, fill=(silver[0],silver[1],silver[2],110), width=14)
        # star burst (correct!)
        sx, sy = cx+250, cy-240
        for a in range(8):
            r = 86 if a % 2 == 0 else 44
            aa = math.radians(a*45)
            x1 = sx + r*math.cos(aa); y1 = sy + r*math.sin(aa)
            d.line([(sx,sy),(x1,y1)], fill=gr, width=20)
        d.ellipse([sx-26, sy-26, sx+26, sy+26], fill=gr)
    elif motif == "lock":  # vault — padlock with luminous keyhole + hasp
        # shackle
        d.arc([cx-150, cy-300, cx+150, cy+0], 180, 360, fill=silver, width=56)
        d.line([(cx-150, cy-150),(cx-150, cy-40)], fill=silver, width=56)
        d.line([(cx+150, cy-150),(cx+150, cy-40)], fill=silver, width=56)
        # body
        d.rounded_rectangle([cx-230, cy-60, cx+230, cy+310], radius=52, fill=light)
        # keyhole
        d.ellipse([cx-58, cy+30, cx+58, cy+146], fill=acc)
        d.polygon([(cx-34, cy+120),(cx+34, cy+120),(cx+18, cy+250),(cx-18, cy+250)], fill=acc)
        # subtle rivets
        for (ox, oy) in [(-180, -10),(180, -10),(-180, 260),(180, 260)]:
            d.ellipse([cx+ox-14, cy+oy-14, cx+ox+14, cy+oy+14], fill=(silver[0],silver[1],silver[2],150))
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

# AccentColor: accent in light, slightly lifted in dark
colorset("AccentColor", hexv, hexv)
colorset("LaunchBackground", "EDEEF3", "14151B")
write(os.path.join(app_dir,"Preview Content","Preview Assets.xcassets","Contents.json"),
      json.dumps({"info":{"author":"xcode","version":1}}, indent=2))

extra_keys = ""
if "mic" in plist_extra:
    extra_keys += "\t<key>NSMicrophoneUsageDescription</key>\n\t<string>%s uses the microphone to measure ambient sound levels. Audio is analyzed live on this device and never recorded or stored.</string>\n" % App
if "camera" in plist_extra:
    extra_keys += "\t<key>NSCameraUsageDescription</key>\n\t<string>%s uses the camera to scan paper documents. Scans stay on this device.</string>\n" % App
if "faceid" in plist_extra:
    extra_keys += "\t<key>NSFaceIDUsageDescription</key>\n\t<string>%s uses Face ID to unlock your vault quickly without typing your master passcode.</string>\n" % App
if "speech" in plist_extra:
    extra_keys += "\t<key>NSSpeechRecognitionUsageDescription</key>\n\t<string>%s transcribes recordings on this device.</string>\n" % App

if orientation == "all":
    iphone_orients = "\t<key>UISupportedInterfaceOrientations</key>\n\t<array>\n\t\t<string>UIInterfaceOrientationPortrait</string>\n\t\t<string>UIInterfaceOrientationLandscapeLeft</string>\n\t\t<string>UIInterfaceOrientationLandscapeRight</string>\n\t</array>"
else:
    iphone_orients = "\t<key>UISupportedInterfaceOrientations</key>\n\t<array>\n\t\t<string>UIInterfaceOrientationPortrait</string>\n\t</array>"

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
{extra_keys}\t<key>UIApplicationSceneManifest</key>
\t<dict>
\t\t<key>UIApplicationSupportsMultipleScenes</key>
\t\t<true/>
\t</dict>
\t<key>UILaunchScreen</key>
\t<dict>
\t\t<key>UIColorName</key>
\t\t<string>LaunchBackground</string>
\t</dict>
{iphone_orients}
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
