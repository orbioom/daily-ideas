#!/usr/bin/env python3
"""Orbioom iOS scaffold v3: shared boilerplate + on-brand 1024 app icon (PIL).

Same contract as scaffold2.py, with motifs for the 2026-06-10 run:
  barbell, speech, astro, hearts, bone, clear

Usage:
  python3 scaffold3.py <app_root_ios_dir> <App> <lower> <accentHexRRGGBB> <motif>
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
    cx, cy = S*0.5, S*0.42
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
    green = hx("5EF0B0")
    gr = (green[0],green[1],green[2],255)

    if motif == "barbell":  # strength programs — loaded barbell, last plate luminous
        # bar
        d.line([(cx-380, cy),(cx+380, cy)], fill=silver, width=36)
        # collars
        d.rounded_rectangle([cx-250, cy-40, cx-210, cy+40], radius=14, fill=silver)
        d.rounded_rectangle([cx+210, cy-40, cx+250, cy+40], radius=14, fill=silver)
        # plates (inner big -> outer small), left mirrored right; outermost right luminous
        for (off, hh, c) in [(190, 220, light), (130, 170, silver)]:
            d.rounded_rectangle([cx-off-54, cy-hh, cx-off, cy+hh], radius=22, fill=c)
            d.rounded_rectangle([cx+off, cy-hh, cx+off+54, cy+hh], radius=22, fill=c)
        d.rounded_rectangle([cx-310, cy-130, cx-260, cy+130], radius=20, fill=silver)
        d.rounded_rectangle([cx+260, cy-130, cx+310, cy+130], radius=20, fill=gr)
    elif motif == "speech":  # vocabulary — two speech bubbles, reply luminous
        # main bubble
        d.rounded_rectangle([cx-320, cy-260, cx+120, cy+20], radius=70, fill=light)
        d.polygon([(cx-220, cy+10),(cx-120, cy+10),(cx-220, cy+120)], fill=light)
        # text lines inside
        for k in range(2):
            yy = cy-190 + k*70
            d.line([(cx-250, yy),(cx+40, yy)], fill=(42,46,58,200), width=22)
        d.line([(cx-250, cy-50),(cx-90, cy-50)], fill=(42,46,58,200), width=22)
        # reply bubble (luminous)
        d.rounded_rectangle([cx-20, cy+60, cx+330, cy+290], radius=60, fill=gr)
        d.polygon([(cx+200, cy+280),(cx+290, cy+280),(cx+290, cy+380)], fill=gr)
        d.line([(cx+50, cy+135),(cx+260, cy+135)], fill=(20,24,30,210), width=20)
        d.line([(cx+50, cy+210),(cx+190, cy+210)], fill=(20,24,30,210), width=20)
    elif motif == "astro":  # birth chart — chart wheel with planet marks, one luminous
        bb = [cx-300, cy-300, cx+300, cy+300]
        d.ellipse(bb, outline=light, width=22)
        d.ellipse([cx-210, cy-210, cx+210, cy+210], outline=(silver[0],silver[1],silver[2],170), width=10)
        # 12 house spokes between rings
        for k in range(12):
            a = math.radians(k*30)
            x1 = cx + 210*math.cos(a); y1 = cy + 210*math.sin(a)
            x2 = cx + 295*math.cos(a); y2 = cy + 295*math.sin(a)
            d.line([(x1,y1),(x2,y2)], fill=(silver[0],silver[1],silver[2],150), width=8)
        # ascendant axis
        d.line([(cx-300, cy),(cx+300, cy)], fill=(light[0],light[1],light[2],110), width=8)
        # planets on inner field + aspect lines
        pts = []
        for (ang, r) in [(205, 150), (300, 120), (35, 160), (120, 110)]:
            a = math.radians(ang)
            pts.append((cx + r*math.cos(a), cy + r*math.sin(a)))
        for i in range(len(pts)):
            for j in range(i+1, len(pts)):
                d.line([pts[i], pts[j]], fill=(silver[0],silver[1],silver[2],110), width=6)
        for i, p in enumerate(pts):
            c = gr if i == 0 else light
            rr = 34 if i == 0 else 26
            d.ellipse([p[0]-rr, p[1]-rr, p[0]+rr, p[1]+rr], fill=c)
    elif motif == "hearts":  # couples — two interlocking hearts, one luminous outline
        def heart(ox, oy, s, **kw):
            # two lobes + point
            pth = []
            for t in [i/100.0*2*math.pi for i in range(101)]:
                hx_ = 16*math.sin(t)**3
                hy_ = 13*math.cos(t) - 5*math.cos(2*t) - 2*math.cos(3*t) - math.cos(4*t)
                pth.append((ox + hx_*s, oy - hy_*s))
            return pth
        d.polygon(heart(cx-110, cy-20, 13), fill=light)
        pts = heart(cx+120, cy+60, 13)
        d.line(pts + [pts[0]], fill=gr, width=30, joint="curve")
    elif motif == "bone":  # dog training — bone with a luminous clicker dot
        # shaft
        d.rounded_rectangle([cx-180, cy-52, cx+180, cy+52], radius=40, fill=light)
        # knobs
        for (ox, oy) in [(-180,-58),(-180,58),(180,-58),(180,58)]:
            d.ellipse([cx+ox-78, cy+oy-78, cx+ox+78, cy+oy+78], fill=light)
        # luminous clicker dot below-right
        d.ellipse([cx+170, cy+170, cx+290, cy+290], fill=gr)
        d.arc([cx+130, cy+130, cx+330, cy+330], 200, 340, fill=(green[0],green[1],green[2],150), width=14)
    elif motif == "clear":  # CBT — cloud parting before a luminous sun
        # sun (luminous) upper right, partly behind cloud
        d.ellipse([cx+10, cy-250, cx+250, cy-10], fill=gr)
        for k in range(7):
            a = math.radians(-95 + k*38)
            sx0 = cx+130 + 150*math.cos(a); sy0 = cy-130 + 150*math.sin(a)
            sx1 = cx+130 + 210*math.cos(a); sy1 = cy-130 + 210*math.sin(a)
            d.line([(sx0,sy0),(sx1,sy1)], fill=(green[0],green[1],green[2],220), width=18)
        # cloud (light) lower left, overlapping sun
        d.ellipse([cx-330, cy-60, cx-90, cy+180], fill=light)
        d.ellipse([cx-200, cy-150, cx+40, cy+90], fill=light)
        d.ellipse([cx-120, cy-40, cx+160, cy+180], fill=light)
        d.rounded_rectangle([cx-300, cy+40, cx+120, cy+180], radius=60, fill=light)

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
