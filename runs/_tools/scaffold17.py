#!/usr/bin/env python3
"""Orbioom iOS scaffold v17 — boilerplate + on-brand 1024 icons for run 2026-06-17_1806.

Creates per-app: folder tree, project.yml, Info.plist, Assets.xcassets
(AppIcon 1024 PNG + AccentColor + LaunchBackground colorsets), Preview Assets.
Swift sources + README are authored separately. Run from repo root.
"""
import os, math, json
from PIL import Image, ImageDraw

RUN = "runs/2026-06-17_1806-UTC"

def hx(h): return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

# (slug, AppName, lower, accentHex, launchLightHex, launchDarkHex, iconTopHex, iconBotHex, motif)
APPS = [
    ("01-mural","Mural","mural","7C5CFF","F1EEFB","0B0A18","3A2A78","120A24","mural"),
    ("02-sigma","Sigma","sigma","F2A33C","F4F2EE","121212","2A2A2E","0C0C0E","calc"),
    ("03-thump","Thump","thump","FF3D7F","F6EEF2","120810","6E1038","1C0610","pads"),
    ("04-caliper","Caliper","caliper","1FB6A6","EAF6F5","06140F","0E5A52","04140F","tape"),
    ("05-trace","Trace","trace","FF8A4C","FFF3EA","1A0E06","C24E14","2A1206","pencil"),
    ("06-tangle","Tangle","tangle","2BB673","EAF6EF","07140D","135C3C","05140D","grid"),
]

def colorset(hexv, dark=None):
    def comp(h):
        r,g,b = hx(h)
        return {"color-space":"srgb","components":{"red":f"0x{r:02X}","green":f"0x{g:02X}","blue":f"0x{b:02X}","alpha":"1.000"}}
    colors=[{"color":comp(hexv),"idiom":"universal"}]
    if dark:
        colors.append({"appearances":[{"appearance":"luminosity","value":"dark"}],"color":comp(dark),"idiom":"universal"})
    return {"colors":colors,"info":{"author":"xcode","version":1}}

def draw_icon(motif, accentHex, topHex, botHex, path):
    S=1024
    img=Image.new("RGB",(S,S),(0,0,0)); px=img.load()
    top,bot=hx(topHex),hx(botHex)
    for y in range(S):
        row=lerp(top,bot,y/S)
        for x in range(S): px[x,y]=row
    d=ImageDraw.Draw(img,"RGBA")
    acc=hx(accentHex); A=(acc[0],acc[1],acc[2],255)
    light=(245,244,240,255); cx,cy=S*0.5,S*0.5
    def accL(t):
        c=lerp(acc,(255,255,255),t); return (c[0],c[1],c[2],255)
    def accD(t):
        c=lerp(acc,(0,0,0),t); return (c[0],c[1],c[2],255)

    if motif=="mural":
        # an overlapping set of color swatches inside a frame (wallpaper studio)
        # frame
        d.rounded_rectangle([cx-S*0.30, cy-S*0.30, cx+S*0.30, cy+S*0.30], radius=S*0.05, outline=light, width=int(S*0.018))
        # gradient hill landscape inside
        sw=[(accL(0.55),0.0),(accL(0.25),0.10),(A,0.20),(accD(0.20),0.30)]
        for i,(col,off) in enumerate(sw):
            yy=cy-S*0.10+S*off
            d.ellipse([cx-S*0.42+S*off, yy, cx+S*0.42-S*off, cy+S*0.55], fill=col)
        # sun
        d.ellipse([cx+S*0.07, cy-S*0.22, cx+S*0.07+S*0.13, cy-S*0.22+S*0.13], fill=light)
    elif motif=="calc":
        # a calculator keypad: grid of rounded keys + an accent equals/operator key
        gx0,gy0=cx-S*0.26, cy-S*0.24
        cell=S*0.135; pad=S*0.022
        for r in range(4):
            for c in range(4):
                x0=gx0+c*(cell+pad); y0=gy0+r*(cell+pad)
                isAcc = (c==3)
                fill = A if isAcc else accL(0.18) if (r+c)%2==0 else accL(0.30)
                d.rounded_rectangle([x0,y0,x0+cell,y0+cell], radius=S*0.022, fill=fill)
        # a sigma-like result glyph (top key row 0 leftmost) overlaid
        d.line([(gx0+S*0.02, gy0+S*0.02),(gx0+cell-S*0.02, gy0+S*0.02)], fill=light, width=int(S*0.012))
    elif motif=="pads":
        # 4x2 drum pad grid with one lit pad + sound wave (beat maker)
        gx0,gy0=cx-S*0.30, cy-S*0.18
        cw=S*0.135; ch=S*0.135; pad=S*0.028
        lit={(0,1),(2,0),(3,1)}
        for r in range(2):
            for c in range(4):
                x0=gx0+c*(cw+pad); y0=gy0+r*(ch+pad)
                on=(c,r) in lit
                fill = A if on else accD(0.30)
                d.rounded_rectangle([x0,y0,x0+cw,y0+ch], radius=S*0.02, fill=fill)
                if on:
                    d.rounded_rectangle([x0+S*0.012,y0+S*0.012,x0+cw-S*0.012,y0+ch-S*0.012], radius=S*0.016, outline=light, width=int(S*0.008))
    elif motif=="tape":
        # a flexible measuring tape curve with tick marks (body measurement)
        pts=[]
        for k in range(0,101):
            t=k/100.0
            x=cx-S*0.34+t*S*0.68
            y=cy+math.sin(t*math.pi*1.4-0.4)*S*0.12
            pts.append((x,y))
        # tape body (thick band)
        d.line(pts, fill=A, width=int(S*0.075), joint="curve")
        d.line(pts, fill=accL(0.30), width=int(S*0.030), joint="curve")
        # tick marks along
        for k in range(4,100,8):
            t=k/100.0
            x=cx-S*0.34+t*S*0.68
            y=cy+math.sin(t*math.pi*1.4-0.4)*S*0.12
            d.line([(x, y-S*0.030),(x, y+S*0.030)], fill=light, width=int(S*0.008))
    elif motif=="pencil":
        # a chunky pencil tracing a dotted letter 'A' (kids tracing)
        # dotted A guide
        d.line([(cx-S*0.14, cy+S*0.20),(cx, cy-S*0.22)], fill=accL(0.45), width=int(S*0.030))
        d.line([(cx, cy-S*0.22),(cx+S*0.14, cy+S*0.20)], fill=accL(0.45), width=int(S*0.030))
        d.line([(cx-S*0.07, cy+S*0.02),(cx+S*0.07, cy+S*0.02)], fill=accL(0.45), width=int(S*0.026))
        # pencil (diagonal) over it
        px0,py0=cx-S*0.02, cy-S*0.26; px1,py1=cx+S*0.26, cy+S*0.02
        # body
        d.line([(px0,py0),(px1,py1)], fill=A, width=int(S*0.07))
        # tip
        d.polygon([(px0,py0),(px0-S*0.05,py0-S*0.01),(px0-S*0.01,py0-S*0.05)], fill=light)
    elif motif=="grid":
        # a small crossword/word grid with letters (word puzzle)
        gx0,gy0=cx-S*0.24, cy-S*0.24
        cell=S*0.16; pad=S*0.012
        filled={(0,0),(1,0),(2,0),(1,1),(1,2),(0,2),(2,2)}
        for r in range(3):
            for c in range(3):
                x0=gx0+c*(cell+pad); y0=gy0+r*(cell+pad)
                if (c,r) in filled:
                    d.rounded_rectangle([x0,y0,x0+cell,y0+cell], radius=S*0.018, fill=accL(0.18))
                    # letter dot
                    d.ellipse([x0+cell*0.38, y0+cell*0.38, x0+cell*0.62, y0+cell*0.62], fill=A)
        # connecting underline (a discovered word)
        d.line([(gx0, gy0+cell*0.5),(gx0+2*(cell+pad)+cell, gy0+cell*0.5)], fill=light, width=int(S*0.012))

    img.save(path,"PNG")

PLIST = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDevelopmentRegion</key><string>en</string>
\t<key>CFBundleDisplayName</key><string>{name}</string>
\t<key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
\t<key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
\t<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
\t<key>CFBundleName</key><string>$(PRODUCT_NAME)</string>
\t<key>CFBundlePackageType</key><string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
\t<key>CFBundleShortVersionString</key><string>$(MARKETING_VERSION)</string>
\t<key>CFBundleVersion</key><string>$(CURRENT_PROJECT_VERSION)</string>
\t<key>LSRequiresIPhoneOS</key><true/>
\t<key>UIApplicationSceneManifest</key>
\t<dict><key>UIApplicationSupportsMultipleScenes</key><false/></dict>
\t<key>UILaunchScreen</key>
\t<dict><key>UIColorName</key><string>LaunchBackground</string></dict>
\t<key>UIRequiredDeviceCapabilities</key><array><string>arm64</string></array>
\t<key>UISupportedInterfaceOrientations</key>
\t<array><string>UIInterfaceOrientationPortrait</string></array>
\t<key>UISupportedInterfaceOrientations~ipad</key>
\t<array>
\t\t<string>UIInterfaceOrientationPortrait</string>
\t\t<string>UIInterfaceOrientationPortraitUpsideDown</string>
\t\t<string>UIInterfaceOrientationLandscapeLeft</string>
\t\t<string>UIInterfaceOrientationLandscapeRight</string>
\t</array>
</dict>
</plist>
"""

PROJ = """name: {name}
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  {name}:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - {name}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.{lower}
        INFOPLIST_FILE: {name}/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        DEVELOPMENT_ASSET_PATHS: "\\"{name}/Preview Content\\""
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
"""

def wj(path, obj):
    with open(path,"w") as f: json.dump(obj,f,indent=2)

def main():
    for slug,name,lower,acc,ll,ld,it,ib,motif in APPS:
        base=f"{RUN}/{slug}/ios"
        appsrc=f"{base}/{name}/{name}"
        for sub in ["Models","Engine","Views","Views/Onboarding","Views/Settings","Views/Components","Views/Paywall","Persistence","Theme","Utilities"]:
            os.makedirs(f"{appsrc}/{sub}", exist_ok=True)
        os.makedirs(f"{appsrc}/Assets.xcassets/AppIcon.appiconset", exist_ok=True)
        os.makedirs(f"{appsrc}/Assets.xcassets/AccentColor.colorset", exist_ok=True)
        os.makedirs(f"{appsrc}/Assets.xcassets/LaunchBackground.colorset", exist_ok=True)
        os.makedirs(f"{base}/{name}/Preview Content/Preview Assets.xcassets", exist_ok=True)
        # project.yml
        with open(f"{base}/project.yml","w") as f: f.write(PROJ.format(name=name,lower=lower))
        # Info.plist
        with open(f"{base}/{name}/Info.plist","w") as f: f.write(PLIST.format(name=name))
        # assets
        wj(f"{appsrc}/Assets.xcassets/Contents.json", {"info":{"author":"xcode","version":1}})
        wj(f"{appsrc}/Assets.xcassets/AccentColor.colorset/Contents.json", colorset(acc))
        wj(f"{appsrc}/Assets.xcassets/LaunchBackground.colorset/Contents.json", colorset(ll, ld))
        wj(f"{appsrc}/Assets.xcassets/AppIcon.appiconset/Contents.json", {
            "images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
            "info":{"author":"xcode","version":1}})
        wj(f"{base}/{name}/Preview Content/Preview Assets.xcassets/Contents.json", {"info":{"author":"xcode","version":1}})
        draw_icon(motif, acc, it, ib, f"{appsrc}/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
        print(f"  scaffolded {slug} ({name})")

if __name__=="__main__":
    main()
    print("done.")
