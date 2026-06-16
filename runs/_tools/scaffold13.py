#!/usr/bin/env python3
"""Orbioom iOS scaffold v13 — boilerplate + on-brand 1024 icons for run 2026-06-16_1215.

Creates per-app: folder tree, project.yml, Info.plist, Assets.xcassets
(AppIcon 1024 PNG + AccentColor + LaunchBackground colorsets), Preview Assets.
Swift sources + README are authored separately. Run from repo root.
"""
import os, math, json
from PIL import Image, ImageDraw

RUN = "runs/2026-06-16_1215-UTC"

def hx(h): return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

# app: (slug, AppName, lower, accentHex, launchLightHex, launchDarkHex, iconTop, iconBot, motif)
APPS = [
    ("01-pursuit","Pursuit","pursuit","4C5BD4","F3F3FB","0C0E1E","1A1F44","0A0C20","pursuit"),
    ("02-deed","Deed","deed","2E8B6B","EFF5F1","081410","123A2C","07140F","house"),
    ("03-lane","Lane","lane","2D7FF9","EFF3FB","0A0E18","12244A","070B16","kanban"),
    ("04-permit","Permit","permit","178A4C","F0F5F1","0A1610","123A24","08160F","wheel"),
    ("05-seek","Seek","seek","E0654E","FBF2EF","1E0C08","4A1B12","200A06","grid"),
    ("06-digit","Digit","digit","F4823C","FFF4EC","1E1108","4A2A12","201006","math"),
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

    if motif=="pursuit":
        # ascending rounded bars (progress) + a goal node with an upward arrow
        bw=S*0.13
        heights=[0.20,0.34,0.50]
        xs=[cx-bw*1.7, cx, cx+bw*1.7]
        cols=[accD(0.10), accL(0.18), A]
        base=cy+S*0.26
        for x,hh,col in zip(xs,heights,cols):
            d.rounded_rectangle([x-bw/2, base-hh*S, x+bw/2, base], radius=bw*0.3, fill=col)
        # goal node above the tallest bar
        gx,gy=xs[2], base-heights[2]*S-S*0.13
        d.ellipse([gx-S*0.075,gy-S*0.075,gx+S*0.075,gy+S*0.075], fill=light)
        # upward arrow climbing across the bars
        pts=[(xs[0],base-heights[0]*S),(xs[1],base-heights[1]*S),(xs[2],base-heights[2]*S)]
        for i in range(len(pts)-1):
            d.line([pts[i],pts[i+1]], fill=light, width=int(S*0.018))
        # arrowhead at goal
        ah=S*0.05
        d.polygon([(gx,gy+S*0.02),(gx-ah,gy+ah+S*0.02),(gx+ah,gy+ah+S*0.02)], fill=light)
    elif motif=="house":
        # rounded house body + roof in accent + door + window + key dot
        bw=S*0.42; bh=S*0.30
        bx0,by0=cx-bw/2, cy-S*0.02
        d.rounded_rectangle([bx0,by0,bx0+bw,by0+bh], radius=S*0.03, fill=light)
        # roof
        d.polygon([(cx-bw*0.62, by0+S*0.01),(cx, cy-S*0.24),(cx+bw*0.62, by0+S*0.01)], fill=A)
        # door
        dw=S*0.10
        d.rounded_rectangle([cx-dw/2, by0+bh-S*0.16, cx+dw/2, by0+bh], radius=S*0.012, fill=accD(0.12))
        # window
        d.rounded_rectangle([bx0+S*0.04, by0+S*0.05, bx0+S*0.13, by0+S*0.14], radius=S*0.012, fill=accL(0.25))
        # key (circle + stem) lower-right accent
        kx,ky=cx+bw*0.30, by0+bh-S*0.07
        d.ellipse([kx-S*0.028,ky-S*0.028,kx+S*0.028,ky+S*0.028], outline=accD(0.2), width=int(S*0.012))
    elif motif=="kanban":
        # three columns, each with stacked cards, one card highlighted in accent
        colw=S*0.20; gap=S*0.045
        total=3*colw+2*gap; x0=cx-total/2
        cardcols=[accL(0.30), accL(0.30), accL(0.30)]
        top0=cy-S*0.26
        for ci in range(3):
            cxx=x0+ci*(colw+gap)
            # column track
            d.rounded_rectangle([cxx, top0, cxx+colw, cy+S*0.30], radius=S*0.02, fill=(255,255,255,28))
            ncards=[3,2,2][ci]
            yy=top0+S*0.03
            for k in range(ncards):
                ch=S*0.085
                col = A if (ci==1 and k==0) else light
                d.rounded_rectangle([cxx+S*0.018, yy, cxx+colw-S*0.018, yy+ch], radius=S*0.014, fill=col)
                yy+=ch+S*0.022
    elif motif=="wheel":
        # steering wheel: outer ring + hub + three spokes (driving / permit)
        R=S*0.30
        d.ellipse([cx-R,cy-R,cx+R,cy+R], outline=A, width=int(S*0.05))
        hub=S*0.075
        d.ellipse([cx-hub,cy-hub,cx+hub,cy+hub], fill=A)
        for ang in [90,210,330]:
            a=math.radians(ang)
            d.line([(cx,cy),(cx+math.cos(a)*R*0.86, cy+math.sin(a)*R*0.86)], fill=A, width=int(S*0.038))
        # subtle inner light ring
        d.ellipse([cx-R*0.55,cy-R*0.55,cx+R*0.55,cy+R*0.55], outline=accL(0.4), width=int(S*0.012))
    elif motif=="grid":
        # 5x5 letter grid, one row highlighted in accent, plus a magnifier
        n=5; cell=S*0.115; gap=S*0.018
        total=n*cell+(n-1)*gap; gx0=cx-total/2; gy0=cy-total/2-S*0.02
        hi_row=2
        for r in range(n):
            for c in range(n):
                x=gx0+c*(cell+gap); y=gy0+r*(cell+gap)
                col = A if r==hi_row else light
                d.rounded_rectangle([x,y,x+cell,y+cell], radius=cell*0.22, fill=col)
        # magnifier over bottom-right
        mx,my=gx0+total+S*0.00, gy0+total+S*0.00
        mr=S*0.10
        d.ellipse([mx-mr,my-mr,mx+mr,my+mr], outline=accD(0.05), width=int(S*0.03))
        d.ellipse([mx-mr,my-mr,mx+mr,my+mr], outline=light, width=int(S*0.012))
        d.line([(mx+mr*0.7,my+mr*0.7),(mx+mr*1.5,my+mr*1.5)], fill=accD(0.05), width=int(S*0.034))
    elif motif=="math":
        # four operator tiles (+ - x /) in a 2x2, playful
        tile=S*0.22; gap=S*0.05
        total=2*tile+gap; x0=cx-total/2; y0=cy-total/2
        cols=[A, accL(0.30), accD(0.12), accL(0.55)]
        positions=[(0,0),(1,0),(0,1),(1,1)]
        ops=["plus","minus","times","div"]
        for (gxi,gyi),op,col in zip(positions,ops,cols):
            tx=x0+gxi*(tile+gap); ty=y0+gyi*(tile+gap)
            d.rounded_rectangle([tx,ty,tx+tile,ty+tile], radius=tile*0.26, fill=col)
            mcx,mcy=tx+tile/2, ty+tile/2; arm=tile*0.26; wgt=int(S*0.022)
            gl=light
            if op=="plus":
                d.line([(mcx-arm,mcy),(mcx+arm,mcy)], fill=gl, width=wgt)
                d.line([(mcx,mcy-arm),(mcx,mcy+arm)], fill=gl, width=wgt)
            elif op=="minus":
                d.line([(mcx-arm,mcy),(mcx+arm,mcy)], fill=gl, width=wgt)
            elif op=="times":
                d.line([(mcx-arm*0.8,mcy-arm*0.8),(mcx+arm*0.8,mcy+arm*0.8)], fill=gl, width=wgt)
                d.line([(mcx-arm*0.8,mcy+arm*0.8),(mcx+arm*0.8,mcy-arm*0.8)], fill=gl, width=wgt)
            elif op=="div":
                d.line([(mcx-arm,mcy),(mcx+arm,mcy)], fill=gl, width=wgt)
                pr=tile*0.05
                d.ellipse([mcx-pr,mcy-arm*0.7-pr,mcx+pr,mcy-arm*0.7+pr], fill=gl)
                d.ellipse([mcx-pr,mcy+arm*0.7-pr,mcx+pr,mcy+arm*0.7+pr], fill=gl)
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
