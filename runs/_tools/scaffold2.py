#!/usr/bin/env python3
"""Orbioom iOS scaffold: shared boilerplate + on-brand 1024 app icon (PIL).

Creates per app:
  Assets.xcassets (AppIcon w/ real 1024 PNG, AccentColor, LaunchBackground, root)
  Preview Content
  Info.plist
  project.yml
  Theme/Brand.swift   (shared Orbioom system)
  Utilities/Haptics.swift

Usage:
  python3 scaffold2.py <app_root_ios_dir> <App> <lower> <accentHexRRGGBB> <motif>
  where <app_root_ios_dir> is the `ios/` folder.
motif in: ring, wave, orb, trend, tree, moon
"""
import os, sys, json, math
from PIL import Image, ImageDraw, ImageFilter

ios_dir, App, lower, hexv, motif = sys.argv[1:6]
app_dir = os.path.join(ios_dir, App)

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

# ---------- colors ----------
def hx(h):
    return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
accent = hx(hexv)

# ---------- icon ----------
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
            # vertical gradient + soft radial glow toward center-top
            t = y / S
            base = lerp(top, bot, t)
            d = math.hypot(x-cx, y-cy) / (S*0.75)
            glow = max(0.0, 1.0 - d)
            g = 0.16 * glow*glow
            px[x,y] = lerp(base, (accent[0],accent[1],accent[2]), g*0.0) if False else (
                int(base[0]+(255-base[0])*g*0.10),
                int(base[1]+(255-base[1])*g*0.10),
                int(base[2]+(255-base[2])*g*0.12),
            )
    d = ImageDraw.Draw(img, "RGBA")
    light = (236,238,243,255)
    silver = (200,205,220,255)
    acc = (accent[0],accent[1],accent[2],255)
    green = hx("5EF0B0")

    def ring(bbox, width, fill, start=0, end=360):
        d.arc(bbox, start, end, fill=fill, width=width)

    if motif == "orb":  # breathwork — concentric breathing orb
        for i,r in enumerate([330, 250, 170]):
            a = 90 - i*22
            d.ellipse([cx-r, cy-r, cx+r, cy+r], outline=(light[0],light[1],light[2],a), width=10)
        d.ellipse([cx-86, cy-86, cx+86, cy+86], fill=(green[0],green[1],green[2],235))
    elif motif == "ring":  # fasting — progress ring with gap (window)
        bb = [cx-250, cy-250, cx+250, cy+250]
        d.arc(bb, -90, 200, fill=silver, width=46)
        d.arc(bb, 200, 270, fill=(green[0],green[1],green[2],255), width=46)
        # knob
        ang = math.radians(200)
        kx, ky = cx+250*math.cos(ang), cy+250*math.sin(ang)
        d.ellipse([kx-30,ky-30,kx+30,ky+30], fill=light)
    elif motif == "wave":  # mood — sine wave
        pts = []
        for i in range(0, 561):
            x = cx-280 + i
            y = cy + 150*math.sin(i/90.0)
            pts.append((x,y))
        d.line(pts, fill=light, width=34, joint="curve")
        ex, ey = cx+280, cy + 150*math.sin(560/90.0)
        d.ellipse([ex-30, ey-30, ex+30, ey+30], fill=(green[0],green[1],green[2],255))
    elif motif == "trend":  # weight — descending trend line + dots
        pts = [(cx-300,cy-170),(cx-160,cy-40),(cx-30,cy-90),(cx+120,cy+60),(cx+290,cy+150)]
        d.line(pts, fill=silver, width=28, joint="curve")
        for i,p in enumerate(pts):
            c = green if i==len(pts)-1 else light
            d.ellipse([p[0]-26,p[1]-26,p[0]+26,p[1]+26], fill=(c[0],c[1],c[2],255))
    elif motif == "tree":  # focus — stylized tree
        # trunk
        d.rounded_rectangle([cx-26, cy+60, cx+26, cy+300], radius=20, fill=silver)
        # canopy circles
        for (ox,oy,r,c) in [(-110,-40,150,light),(110,-40,150,light),(0,-150,170,light),(0,-20,160,(green[0],green[1],green[2],255))]:
            d.ellipse([cx+ox-r, cy+oy-r, cx+ox+r, cy+oy+r], fill=c)
    elif motif == "moon":  # cycle — crescent
        d.ellipse([cx-240, cy-240, cx+240, cy+240], fill=light)
        d.ellipse([cx-130, cy-270, cx+330, cy+210], fill=(int((top[0]+bot[0])/2),int((top[1]+bot[1])/2),int((top[2]+bot[2])/2),255))
        # small accent dot (ovulation)
        d.ellipse([cx-210, cy+150, cx-150, cy+210], fill=(green[0],green[1],green[2],255))

    img = img.filter(ImageFilter.GaussianBlur(0.4))
    img = img.convert("RGBA")
    img.save(path, "PNG")

# ---------- asset catalog ----------
def colorset(name, light, dark):
    def comp(h):
        return {"red": f"0x{h[0:2]}", "green": f"0x{h[2:4]}", "blue": f"0x{h[4:6]}", "alpha": "1.000"}
    obj = {"colors": [
        {"idiom":"universal","color":{"color-space":"srgb","components":comp(light)}},
        {"idiom":"universal","appearances":[{"appearance":"luminosity","value":"dark"}],
         "color":{"color-space":"srgb","components":comp(dark)}},
    ], "info":{"author":"xcode","version":1}}
    write(os.path.join(app_dir,"Assets.xcassets",name+".colorset","Contents.json"), json.dumps(obj, indent=2))

write(os.path.join(app_dir,"Assets.xcassets","Contents.json"), json.dumps({"info":{"author":"xcode","version":1}}, indent=2))
write(os.path.join(app_dir,"Assets.xcassets","AppIcon.appiconset","Contents.json"),
      json.dumps({"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
                  "info":{"author":"xcode","version":1}}, indent=2))
make_icon(os.path.join(app_dir,"Assets.xcassets","AppIcon.appiconset","icon-1024.png"))
colorset("AccentColor", hexv, "F2F3F8")
colorset("LaunchBackground", "EDEEF3", "14151B")
write(os.path.join(app_dir,"Preview Content","Preview Assets.xcassets","Contents.json"),
      json.dumps({"info":{"author":"xcode","version":1}}, indent=2))

# ---------- Info.plist ----------
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

# ---------- project.yml ----------
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
'''
write(os.path.join(ios_dir,"project.yml"), proj)

print(f"scaffolded {App} ({motif}) accent #{hexv}")
