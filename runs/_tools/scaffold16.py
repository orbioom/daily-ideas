#!/usr/bin/env python3
"""Orbioom iOS scaffold v16 — boilerplate + on-brand 1024 icons for run 2026-06-17_1209.

Creates per-app: folder tree, project.yml, Info.plist, Assets.xcassets
(AppIcon 1024 PNG + AccentColor + LaunchBackground colorsets), Preview Assets.
Swift sources + README are authored separately. Run from repo root.
"""
import os, math, json
from PIL import Image, ImageDraw

RUN = "runs/2026-06-17_1209-UTC"

def hx(h): return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

# app: (slug, AppName, lower, accentHex, launchLightHex, launchDarkHex, iconTop, iconBot, motif)
APPS = [
    ("01-ascend","Ascend","ascend","E07B39","FBF3EC","140D07","7A3A12","1A0D05","barbell"),
    ("02-wake","Wake","wake","1FA2C4","EAF6F9","06121A","0E4A66","04141F","swim"),
    ("03-nest","Nest","nest","2FA66B","EDF7F0","08130D","15623E","05160D","coins"),
    ("04-sear","Sear","sear","E2542B","FCF1EC","160A06","6E2410","1C0904","flame"),
    ("05-upkeep","Upkeep","upkeep","2E8B8B","EAF4F4","07120F","134A4A","041413","home"),
    ("06-verbo","Verbo","verbo","6357D8","EFEEFB","0B0A18","2A2470","08071A","verb"),
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

    if motif=="barbell":
        # a horizontal barbell with plates, plus an up-chevron above (progression)
        bar_y=cy+S*0.04
        bw=int(S*0.045)
        # bar
        d.line([(cx-S*0.30, bar_y),(cx+S*0.30, bar_y)], fill=accL(0.35), width=bw)
        # plates (pairs), inner bigger
        plates=[(0.18,0.20),(0.245,0.15)]   # (x-offset fraction, half-height fraction)
        for off,hh in plates:
            for sgn in (-1,1):
                xc=cx+sgn*S*off
                pw=S*0.05
                d.rounded_rectangle([xc-pw/2, bar_y-S*hh, xc+pw/2, bar_y+S*hh], radius=S*0.018, fill=A)
        # collars
        for sgn in (-1,1):
            xc=cx+sgn*S*0.145
            d.rounded_rectangle([xc-S*0.018, bar_y-S*0.06, xc+S*0.018, bar_y+S*0.06], radius=S*0.01, fill=accD(0.25))
        # up chevron (ascending progression)
        chy=cy-S*0.20; chw=S*0.13
        d.line([(cx-chw, chy+S*0.06),(cx, chy-S*0.06),(cx+chw, chy+S*0.06)], fill=light, width=int(S*0.030), joint="curve")
        d.line([(cx-chw, chy+S*0.16),(cx, chy+S*0.04),(cx+chw, chy+S*0.16)], fill=accL(0.5), width=int(S*0.026), joint="curve")
    elif motif=="swim":
        # three flowing water-lane waves + a swimmer head/arm stroke
        for i,yy in enumerate([cy-S*0.02, cy+S*0.10, cy+S*0.22]):
            pts=[]
            for k in range(0,101):
                t=k/100.0
                x=cx-S*0.34+t*S*0.68
                y=yy+math.sin(t*math.pi*3.0)*S*0.035
                pts.append((x,y))
            col = A if i==0 else (accL(0.25) if i==1 else accL(0.45))
            d.line(pts, fill=col, width=int(S*0.030), joint="curve")
        # swimmer: head + curved arm stroke above top wave
        hx0,hy0=cx-S*0.12, cy-S*0.18
        hr=S*0.052
        d.ellipse([hx0-hr,hy0-hr,hx0+hr,hy0+hr], fill=light)
        # arm arc reaching forward
        d.arc([hx0-S*0.02, hy0-S*0.10, hx0+S*0.30, hy0+S*0.14], start=200, end=350, fill=light, width=int(S*0.030))
    elif motif=="coins":
        # a stack of three coins + an upward growth arrow (savings goal)
        cw=S*0.30; ch=S*0.06
        ys=[cy+S*0.16, cy+S*0.05, cy-S*0.06]
        fills=[accD(0.22), accD(0.05), A]
        for yy,fl in zip(ys,fills):
            d.ellipse([cx-cw/2, yy-ch, cx+cw/2, yy+ch], fill=fl)
            d.ellipse([cx-cw/2, yy-ch-S*0.018, cx+cw/2, yy+ch-S*0.018], fill=accL(0.18))
        # currency tick on top coin
        d.line([(cx, cy-S*0.06-S*0.035),(cx, cy-S*0.06+S*0.035)], fill=light, width=int(S*0.012))
        # upward arrow rising from the stack
        ax=cx+S*0.0; aytop=cy-S*0.24
        d.line([(cx, cy-S*0.10),(cx, aytop)], fill=light, width=int(S*0.026))
        d.line([(cx-S*0.07, aytop+S*0.07),(cx, aytop),(cx+S*0.07, aytop+S*0.07)], fill=light, width=int(S*0.026), joint="curve")
    elif motif=="flame":
        # a stylized flame over grill-grate lines (BBQ / smoking)
        # grate lines at the bottom
        for gx in [cx-S*0.18, cx-S*0.06, cx+S*0.06, cx+S*0.18]:
            d.line([(gx, cy+S*0.16),(gx, cy+S*0.30)], fill=accL(0.35), width=int(S*0.020))
        d.line([(cx-S*0.24, cy+S*0.30),(cx+S*0.24, cy+S*0.30)], fill=accL(0.35), width=int(S*0.022))
        # outer flame (teardrop-ish polygon)
        outer=[(cx, cy-S*0.30),(cx+S*0.16, cy-S*0.06),(cx+S*0.17, cy+S*0.10),
               (cx+S*0.06, cy+S*0.18),(cx-S*0.06, cy+S*0.18),(cx-S*0.17, cy+S*0.10),
               (cx-S*0.16, cy-S*0.06)]
        d.polygon(outer, fill=A)
        # inner flame
        inner=[(cx, cy-S*0.14),(cx+S*0.09, cy+S*0.02),(cx+S*0.085, cy+S*0.12),
               (cx, cy+S*0.155),(cx-S*0.085, cy+S*0.12),(cx-S*0.09, cy+S*0.02)]
        d.polygon(inner, fill=light)
    elif motif=="home":
        # a house outline with a wrench inside (home upkeep)
        bw=S*0.40; bh=S*0.24
        bx0,by0=cx-bw/2, cy-S*0.02
        # roof
        d.polygon([(cx-bw*0.60, by0+S*0.01),(cx, cy-S*0.24),(cx+bw*0.60, by0+S*0.01)], fill=A)
        # body
        d.rounded_rectangle([bx0,by0,bx0+bw,by0+bh], radius=S*0.02, fill=accL(0.25))
        # wrench inside: handle + open head
        wx0,wy0=cx-S*0.10, cy+S*0.16
        wx1,wy1=cx+S*0.08, cy-S*0.00
        d.line([(wx0,wy0),(wx1,wy1)], fill=light, width=int(S*0.040))
        # wrench head (ring)
        hr=S*0.055
        d.ellipse([wx1-hr, wy1-hr, wx1+hr, wy1+hr], fill=light)
        bgc=lerp(top,bot,0.35)
        d.ellipse([wx1-hr*0.5, wy1-hr*0.5, wx1+hr*0.5, wy1+hr*0.5], fill=(accL(0.25)[0],accL(0.25)[1],accL(0.25)[2],255))
        # handle end knob
        d.ellipse([wx0-S*0.026, wy0-S*0.026, wx0+S*0.026, wy0+S*0.026], fill=light)
    elif motif=="verb":
        # a rounded card showing a conjugation table: header bar + rows, with a tilde/accent
        cw,ch=S*0.42,S*0.46
        d.rounded_rectangle([cx-cw/2,cy-ch/2,cx+cw/2,cy+ch/2], radius=S*0.04, fill=accD(0.12))
        # header bar (accent)
        d.rounded_rectangle([cx-cw/2,cy-ch/2,cx+cw/2,cy-ch/2+S*0.10], radius=S*0.04, fill=A)
        # square off bottom of header
        d.rectangle([cx-cw/2,cy-ch/2+S*0.06,cx+cw/2,cy-ch/2+S*0.10], fill=A)
        # a tilde on the header
        ty=cy-ch/2+S*0.05
        d.arc([cx-S*0.06, ty-S*0.03, cx-S*0.00, ty+S*0.03], start=180, end=360, fill=light, width=int(S*0.014))
        d.arc([cx-S*0.00, ty-S*0.03, cx+S*0.06, ty+S*0.03], start=0, end=180, fill=light, width=int(S*0.014))
        # conjugation rows
        for i in range(4):
            ry=cy-ch/2+S*0.155+i*S*0.075
            d.rounded_rectangle([cx-cw/2+S*0.05, ry, cx-S*0.02, ry+S*0.028], radius=S*0.012, fill=accL(0.45))
            d.rounded_rectangle([cx+S*0.02, ry, cx+cw/2-S*0.05, ry+S*0.028], radius=S*0.012, fill=light)
    img.save(path,"PNG")

PROJECT_YML = """name: {App}
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
        DEVELOPMENT_ASSET_PATHS: "\\"{App}/Preview Content\\""
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
"""

INFO_PLIST = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDevelopmentRegion</key><string>en</string>
\t<key>CFBundleDisplayName</key><string>{App}</string>
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

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path,"w") as f: f.write(content)

def wj(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path,"w") as f: json.dump(obj,f,indent=2)

for slug,App,lower,acc,ll,ld,it,ib,motif in APPS:
    base=f"{RUN}/{slug}/ios"
    src=f"{base}/{App}/{App}"            # swift sources dir
    assets=f"{src}/Assets.xcassets"
    w(f"{base}/project.yml", PROJECT_YML.format(App=App, lower=lower))
    w(f"{base}/{App}/Info.plist", INFO_PLIST.format(App=App))
    wj(f"{assets}/Contents.json", {"info":{"author":"xcode","version":1}})
    wj(f"{assets}/AppIcon.appiconset/Contents.json",
       {"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
        "info":{"author":"xcode","version":1}})
    wj(f"{assets}/AccentColor.colorset/Contents.json", colorset(acc))
    wj(f"{assets}/LaunchBackground.colorset/Contents.json", colorset(ll, ld))
    wj(f"{base}/{App}/Preview Content/Preview Assets.xcassets/Contents.json",
       {"info":{"author":"xcode","version":1}})
    draw_icon(motif, acc, it, ib, f"{assets}/AppIcon.appiconset/icon-1024.png")
    print(f"scaffolded {slug} ({App})")
print("done")
