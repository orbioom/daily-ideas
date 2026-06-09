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
    elif motif == "check":  # habit — calendar grid of completion squares, last one lit green
        cols, rows = 4, 4
        gap = 40; cell = 150
        gw = cols*cell + (cols-1)*gap
        ox = cx - gw/2; oy = cy - (rows*cell + (rows-1)*gap)/2
        lit = {(0,0),(1,0),(2,0),(0,1),(2,1),(3,1),(1,2),(2,2),(0,3),(1,3),(2,3),(3,3)}
        for r in range(rows):
            for c in range(cols):
                x0 = ox + c*(cell+gap); y0 = oy + r*(cell+gap)
                last = (c==cols-1 and r==rows-1)
                if last:
                    fill = (green[0],green[1],green[2],255)
                elif (c,r) in lit:
                    fill = light
                else:
                    fill = (light[0],light[1],light[2],55)
                d.rounded_rectangle([x0,y0,x0+cell,y0+cell], radius=34, fill=fill)
    elif motif == "dawn":  # sobriety — rising sun over horizon with rays
        horizon = cy + 150
        d.ellipse([cx-150, horizon-150, cx+150, horizon+150], fill=(green[0],green[1],green[2],255))
        for k in range(8):
            a = math.radians(180 + k*(180/7))
            x1 = cx + 200*math.cos(a); y1 = horizon + 200*math.sin(a)
            x2 = cx + 300*math.cos(a); y2 = horizon + 300*math.sin(a)
            d.line([(x1,y1),(x2,y2)], fill=light, width=22)
        d.rectangle([0, horizon, S, S], fill=(top[0],top[1],top[2],255))
        d.line([(cx-360,horizon),(cx+360,horizon)], fill=silver, width=16)
    elif motif == "leaf":  # plant — single leaf with central vein + water drop
        pts = []
        for i in range(0,101):
            t = i/100.0
            w = 230*math.sin(math.pi*t)
            y = cy-300 + t*600
            pts.append((cx-w, y))
        for i in range(100,-1,-1):
            t = i/100.0
            w = 230*math.sin(math.pi*t)
            y = cy-300 + t*600
            pts.append((cx+w, y))
        d.polygon(pts, fill=(green[0],green[1],green[2],255))
        d.line([(cx,cy-280),(cx,cy+280)], fill=(light[0],light[1],light[2],230), width=14)
        for s in range(1,5):
            yy = cy-280 + s*110
            d.line([(cx,yy),(cx+70, yy-50)], fill=(light[0],light[1],light[2],180), width=9)
            d.line([(cx,yy),(cx-70, yy-50)], fill=(light[0],light[1],light[2],180), width=9)
    elif motif == "drop":  # baby — soft droplet/teardrop with highlight
        d.ellipse([cx-200, cy-100, cx+200, cy+300], fill=light)
        d.polygon([(cx,cy-320),(cx-150,cy+60),(cx+150,cy+60)], fill=light)
        d.ellipse([cx-150, cy-30, cx+250, cy+370], fill=(top[0],top[1],top[2],0))
        d.ellipse([cx+40, cy+90, cx+130, cy+180], fill=(green[0],green[1],green[2],255))
    elif motif == "night":  # sleep — crescent moon + stars
        d.ellipse([cx-230, cy-230, cx+230, cy+230], fill=light)
        d.ellipse([cx-90, cy-280, cx+330, cy+180], fill=(top[0],top[1],top[2],255))
        for (sx,sy,sr) in [(cx-300,cy-200,18),(cx-240,cy+220,12),(cx+250,cy+250,16),(cx+300,cy-120,10)]:
            d.ellipse([sx-sr,sy-sr,sx+sr,sy+sr], fill=(green[0],green[1],green[2],255))
    elif motif == "book":  # journal — open book with a ribbon bookmark
        # two facing pages with a spine gap
        d.polygon([(cx,cy-210),(cx-330,cy-150),(cx-330,cy+240),(cx,cy+200)], fill=light)
        d.polygon([(cx,cy-210),(cx+330,cy-150),(cx+330,cy+240),(cx,cy+200)], fill=silver)
        d.line([(cx,cy-205),(cx,cy+200)], fill=(top[0],top[1],top[2],255), width=12)
        for k in range(1,5):  # text lines on left page
            yy = cy-110 + k*64
            d.line([(cx-280,yy),(cx-40,yy-26)], fill=(top[0],top[1],top[2],150), width=12)
        # green ribbon bookmark
        d.polygon([(cx+150,cy-180),(cx+200,cy-180),(cx+175,cy+90),(cx+150,cy+50),(cx+200,cy+50)],
                  fill=(green[0],green[1],green[2],255))
    elif motif == "pin":  # travel — map pin (teardrop) with hole + dashed path
        d.ellipse([cx-160, cy-260, cx+160, cy+60], fill=light)
        d.polygon([(cx-150,cy-30),(cx+150,cy-30),(cx,cy+250)], fill=light)
        d.ellipse([cx-70, cy-170, cx+70, cy-30], fill=(top[0],top[1],top[2],255))
        d.ellipse([cx-34, cy-134, cx+34, cy-66], fill=(green[0],green[1],green[2],255))
        for k in range(5):  # dashed path curving away
            ang = math.radians(20 + k*16)
            bx = cx + 120 + k*46
            by = cy + 200 - k*8
            d.ellipse([bx-12,by-12,bx+12,by+12], fill=(silver[0],silver[1],silver[2],200))
    elif motif == "clock":  # time tracker — clock face with hands, green tick
        bb = [cx-250, cy-250, cx+250, cy+250]
        d.ellipse(bb, outline=light, width=34)
        for k in range(12):
            a = math.radians(k*30)
            x1 = cx + 200*math.cos(a); y1 = cy + 200*math.sin(a)
            x2 = cx + 230*math.cos(a); y2 = cy + 230*math.sin(a)
            d.line([(x1,y1),(x2,y2)], fill=(silver[0],silver[1],silver[2],220), width=12)
        d.line([(cx,cy),(cx, cy-150)], fill=light, width=24)  # minute
        d.line([(cx,cy),(cx+110, cy+40)], fill=(green[0],green[1],green[2],255), width=24)  # hour
        d.ellipse([cx-22,cy-22,cx+22,cy+22], fill=light)
    elif motif == "hanger":  # wardrobe — clothes hanger
        # hook
        d.arc([cx-50, cy-260, cx+50, cy-160], 200, 360, fill=silver, width=22)
        d.line([(cx,cy-160),(cx,cy-90)], fill=silver, width=22)
        # triangle bar
        d.line([(cx,cy-90),(cx-300,cy+90)], fill=light, width=34, joint="curve")
        d.line([(cx,cy-90),(cx+300,cy+90)], fill=light, width=34, joint="curve")
        d.line([(cx-300,cy+90),(cx+300,cy+90)], fill=(green[0],green[1],green[2],255), width=34)
    elif motif == "pan":  # recipe — frying pan from above with handle
        d.ellipse([cx-250, cy-250, cx+250, cy+250], outline=light, width=40)
        d.ellipse([cx-180, cy-180, cx+180, cy+180], fill=(top[0],top[1],top[2],255))
        # handle to the upper-right
        d.line([(cx+200,cy-200),(cx+360,cy-360)], fill=silver, width=46)
        # three "ingredients" dots inside
        for (ox,oy,c) in [(-70,-30,light),(70,-50,silver),(0,70,(green[0],green[1],green[2],255))]:
            d.ellipse([cx+ox-44, cy+oy-44, cx+ox+44, cy+oy+44], fill=c)
    elif motif == "board":  # day planner — vertical timeline rail with stacked blocks
        railx = cx - 250
        d.line([(railx, cy-300),(railx, cy+300)], fill=(silver[0],silver[1],silver[2],220), width=10)
        blocks = [(-260, 150, light), (-70, 110, silver), (70, 170, (green[0],green[1],green[2],255))]
        for (oy, h, c) in blocks:
            y0 = cy + oy
            d.ellipse([railx-26, y0+h/2-26, railx+26, y0+h/2+26], fill=c)
            d.rounded_rectangle([railx+70, y0, railx+520, y0+h], radius=34, fill=c)
    elif motif == "bump":  # pregnancy — mother curve with a baby orbit dot
        d.arc([cx-300, cy-300, cx+300, cy+300], 40, 320, fill=light, width=34)
        d.ellipse([cx-150, cy-30, cx+230, cy+350], outline=silver, width=30)
        d.ellipse([cx+20, cy+90, cx+150, cy+220], fill=(green[0],green[1],green[2],255))
    elif motif == "gauge":  # car — speedometer arc with needle
        bb = [cx-260, cy-260, cx+260, cy+260]
        d.arc(bb, 150, 390, fill=silver, width=40)
        d.arc(bb, 150, 250, fill=light, width=40)
        d.arc(bb, 250, 300, fill=(green[0],green[1],green[2],255), width=40)
        ang = math.radians(285)
        d.line([(cx, cy),(cx+230*math.cos(ang), cy+230*math.sin(ang))], fill=light, width=22)
        d.ellipse([cx-30, cy-30, cx+30, cy+30], fill=light)
    elif motif == "rings":  # wedding — two interlocking bands, one luminous green
        d.ellipse([cx-300, cy-130, cx-20, cy+150], outline=light, width=40)
        d.ellipse([cx+20, cy-130, cx+300, cy+150], outline=(green[0],green[1],green[2],255), width=40)
        d.ellipse([cx-150, cy-300, cx-90, cy-240], fill=(light[0],light[1],light[2],255))
    elif motif == "stretch":  # mobility — a limber bending limb with joints + motion arc
        d.line([(cx-230,cy+250),(cx-120,cy-30)], fill=light, width=40, joint="curve")
        d.line([(cx-120,cy-30),(cx+220,cy-180)], fill=light, width=40, joint="curve")
        for (px_,py_,c) in [(cx-230,cy+250,silver),(cx-120,cy-30,(green[0],green[1],green[2],255)),(cx+220,cy-180,light)]:
            d.ellipse([px_-44,py_-44,px_+44,py_+44], fill=c)
        d.arc([cx-60, cy-180, cx+300, cy+120], 200, 320, fill=(silver[0],silver[1],silver[2],180), width=16)
    elif motif == "paw":  # pet — paw print, one toe luminous
        d.ellipse([cx-150, cy-30, cx+150, cy+250], fill=light)  # main pad
        for (ox,oy,c) in [(-180,-120,light),(-60,-220,light),(70,-220,(green[0],green[1],green[2],255)),(190,-120,light)]:
            d.ellipse([cx+ox-70, cy+oy-70, cx+ox+70, cy+oy+70], fill=c)
    elif motif == "target":  # savings goal — concentric target, center luminous
        for i,r in enumerate([300, 210, 120]):
            col = light if i % 2 == 0 else silver
            d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=col, width=36)
        d.ellipse([cx-56,cy-56,cx+56,cy+56], fill=(green[0],green[1],green[2],255))
    elif motif == "candle":  # trading — candlesticks with wicks
        for (ox, top_off, h, c) in [(-260,-40,200,silver),(-90,-150,250,(green[0],green[1],green[2],255)),(90,10,150,light),(250,-90,210,silver)]:
            bx = cx + ox
            d.line([(bx, cy+top_off-70),(bx, cy+top_off+h+70)], fill=c, width=14)
            d.rounded_rectangle([bx-46, cy+top_off, bx+46, cy+top_off+h], radius=16, fill=c)
    elif motif == "sprout":  # chores/kids — a seedling with reward star
        d.line([(cx, cy+260),(cx, cy-40)], fill=silver, width=30)
        d.ellipse([cx-230, cy-30, cx-10, cy+150], fill=(green[0],green[1],green[2],255))
        d.ellipse([cx+10, cy-90, cx+230, cy+90], fill=light)
        sx, sy, sr = cx, cy-160, 84
        d.polygon([(sx,sy-sr),(sx+sr*0.32,sy-sr*0.32),(sx+sr,sy),(sx+sr*0.32,sy+sr*0.32),
                   (sx,sy+sr),(sx-sr*0.32,sy+sr*0.32),(sx-sr,sy),(sx-sr*0.32,sy-sr*0.32)], fill=light)
    elif motif == "people":  # personal CRM — overlapping people, centre luminous
        for (ox, c) in [(-150, silver),(150, light),(0, (green[0],green[1],green[2],255))]:
            hx_ = cx+ox; hy = cy-110
            d.pieslice([hx_-150, hy+40, hx_+150, hy+360], 180, 360, fill=c)
            d.ellipse([hx_-80, hy-80, hx_+80, hy+80], fill=c)
    elif motif == "flame":  # challenge — a rising flame with an inner luminous core
        outer = [(cx, cy-320),(cx+190, cy-60),(cx+150, cy+170),(cx, cy+300),
                 (cx-150, cy+170),(cx-190, cy-60)]
        d.polygon(outer, fill=light)
        inner = [(cx, cy-150),(cx+110, cy+40),(cx+70, cy+190),(cx, cy+250),
                 (cx-70, cy+190),(cx-110, cy+40)]
        d.polygon(inner, fill=(green[0],green[1],green[2],255))
    elif motif == "gift":  # gifting — a wrapped present with bow + ribbon
        d.rounded_rectangle([cx-250, cy-110, cx+250, cy+270], radius=30, fill=light)
        d.rectangle([cx-40, cy-110, cx+40, cy+270], fill=(green[0],green[1],green[2],255))  # vertical ribbon
        d.rectangle([cx-250, cy+50, cx+250, cy+130], fill=(green[0],green[1],green[2],255))  # horizontal ribbon
        # bow loops
        d.ellipse([cx-150, cy-230, cx-10, cy-90], outline=(green[0],green[1],green[2],255), width=34)
        d.ellipse([cx+10, cy-230, cx+150, cy-90], outline=(green[0],green[1],green[2],255), width=34)
        d.ellipse([cx-34, cy-170, cx+34, cy-102], fill=silver)
    elif motif == "cube":  # home inventory — isometric box/cube, one face luminous
        # top face
        d.polygon([(cx, cy-260),(cx+260, cy-110),(cx, cy+40),(cx-260, cy-110)], fill=light)
        # left face
        d.polygon([(cx-260, cy-110),(cx, cy+40),(cx, cy+320),(cx-260, cy+170)], fill=silver)
        # right face (luminous)
        d.polygon([(cx+260, cy-110),(cx, cy+40),(cx, cy+320),(cx+260, cy+170)],
                  fill=(green[0],green[1],green[2],255))
        d.line([(cx, cy+40),(cx, cy+320)], fill=(top[0],top[1],top[2],180), width=8)

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
