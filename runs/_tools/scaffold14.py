#!/usr/bin/env python3
"""Orbioom iOS scaffold v14 — boilerplate + on-brand 1024 icons for run 2026-06-17_0012.

Creates per-app: folder tree, project.yml, Info.plist, Assets.xcassets
(AppIcon 1024 PNG + AccentColor + LaunchBackground colorsets), Preview Assets.
Swift sources + README are authored separately. Run from repo root.
"""
import os, math, json
from PIL import Image, ImageDraw

RUN = "runs/2026-06-17_0012-UTC"

def hx(h): return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

# app: (slug, AppName, lower, accentHex, launchLightHex, launchDarkHex, iconTop, iconBot, motif)
APPS = [
    ("01-spindle","Spindle","spindle","1F9E6E","EEF6F1","08130E","0C3A2A","06170F","cards"),
    ("02-conduit","Conduit","conduit","3D7BF7","EEF2FB","090C18","13224A","070A16","flow"),
    ("03-stub","Stub","stub","2E9E5B","EEF6F0","081410","0E3A24","06150E","check"),
    ("04-recur","Recur","recur","7C5CF0","F1EEFB","0C0A18","271446","0B0820","recur"),
    ("05-parcel","Parcel","parcel","C9863A","FAF3EA","18110A","452C12","1E1208","estate"),
    ("06-fuel","Fuel","fuel","EF6A38","FFF2EC","1C0E08","4A2110","200C06","macro"),
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

    if motif=="cards":
        # two overlapping rounded playing cards, front one bears a spade pip
        cw,ch=S*0.34,S*0.46
        # back card, rotated-ish (offset)
        bx,by=cx-S*0.16, cy-S*0.20
        d.rounded_rectangle([bx-cw/2,by-ch/2,bx+cw/2,by+ch/2], radius=S*0.04, fill=accL(0.55))
        # front card
        fx,fy=cx+S*0.08, cy+S*0.02
        d.rounded_rectangle([fx-cw/2,fy-ch/2,fx+cw/2,fy+ch/2], radius=S*0.04, fill=light)
        # spade pip centered on front card
        spx,spy=fx, fy-S*0.02
        r=S*0.085
        # two lobes + center => spade body via circles + triangle
        d.ellipse([spx-r,spy-r*0.2,spx-r*0.05,spy+r*1.0], fill=accD(0.05))
        d.ellipse([spx+r*0.05,spy-r*0.2,spx+r,spy+r*1.0], fill=accD(0.05))
        d.polygon([(spx-r,spy+r*0.55),(spx+r,spy+r*0.55),(spx,spy-r*0.95)], fill=accD(0.05))
        # stem
        d.polygon([(spx-r*0.42,spy+r*1.5),(spx+r*0.42,spy+r*1.5),(spx+r*0.12,spy+r*0.6),(spx-r*0.12,spy+r*0.6)], fill=accD(0.05))
    elif motif=="flow":
        # colored endpoint dots joined by an L-shaped pipe path on an implied grid
        cols=[A, accL(0.45), accD(0.10)]
        dotr=S*0.052
        pipe=int(S*0.052)
        # path 1: top-left dot -> elbow -> right dot (accent)
        p1a=(cx-S*0.26, cy-S*0.24); p1b=(cx-S*0.26, cy+S*0.06); p1c=(cx+S*0.24, cy+S*0.06)
        d.line([p1a,p1b,p1c], fill=A, width=pipe, joint="curve")
        d.ellipse([p1a[0]-dotr,p1a[1]-dotr,p1a[0]+dotr,p1a[1]+dotr], fill=A)
        d.ellipse([p1c[0]-dotr,p1c[1]-dotr,p1c[0]+dotr,p1c[1]+dotr], fill=A)
        # path 2: lower path light
        p2a=(cx-S*0.02, cy-S*0.26); p2b=(cx-S*0.02, cy+S*0.26);
        d.line([p2a,p2b], fill=light, width=pipe)
        d.ellipse([p2a[0]-dotr,p2a[1]-dotr,p2a[0]+dotr,p2a[1]+dotr], fill=light)
        d.ellipse([p2b[0]-dotr,p2b[1]-dotr,p2b[0]+dotr,p2b[1]+dotr], fill=light)
        # path 3: short accentL elbow bottom-right
        p3a=(cx+S*0.24, cy-S*0.24); p3b=(cx+S*0.24, cy-S*0.06)
        d.line([p3a,p3b], fill=accL(0.5), width=pipe)
        d.ellipse([p3a[0]-dotr,p3a[1]-dotr,p3a[0]+dotr,p3a[1]+dotr], fill=accL(0.5))
        d.ellipse([p3b[0]-dotr,p3b[1]-dotr,p3b[0]+dotr,p3b[1]+dotr], fill=accL(0.5))
    elif motif=="check":
        # a paycheck / receipt card with a $ and stub lines
        cw,ch=S*0.50,S*0.34
        x0,y0=cx-cw/2, cy-ch/2
        d.rounded_rectangle([x0,y0,x0+cw,y0+ch], radius=S*0.03, fill=light)
        # left stub band in accent
        d.rounded_rectangle([x0,y0,x0+cw*0.30,y0+ch], radius=S*0.03, fill=A)
        d.rectangle([x0+cw*0.22,y0,x0+cw*0.30,y0+ch], fill=A)
        # dollar sign on stub
        dcx,dcy=x0+cw*0.15, cy
        d.text  # noop guard
        # draw $ as a vertical bar + S-ish using two arcs
        bw=int(S*0.012)
        d.line([(dcx,dcy-S*0.075),(dcx,dcy+S*0.075)], fill=light, width=bw)
        d.arc([dcx-S*0.045,dcy-S*0.07,dcx+S*0.045,dcy-S*0.005], start=300, end=170, fill=light, width=bw)
        d.arc([dcx-S*0.045,dcy+S*0.005,dcx+S*0.045,dcy+S*0.07], start=120, end=350, fill=light, width=bw)
        # amount lines on the right
        lx=x0+cw*0.36
        for i,wfrac in enumerate([0.52,0.40,0.30]):
            yy=y0+ch*0.30+i*ch*0.22
            d.rounded_rectangle([lx,yy,lx+cw*wfrac,yy+S*0.028], radius=S*0.012, fill=accL(0.35) if i==0 else (accL(0.7)))
    elif motif=="recur":
        # two circular recurring arrows around a central card/badge
        R=S*0.27
        wdt=int(S*0.05)
        d.arc([cx-R,cy-R,cx+R,cy+R], start=20, end=200, fill=A, width=wdt)
        d.arc([cx-R,cy-R,cx+R,cy+R], start=200, end=380, fill=accL(0.4), width=wdt)
        # arrowheads
        import math as _m
        for ang,col in [(200,A),(20,accL(0.4))]:
            a=_m.radians(ang)
            ex,ey=cx+_m.cos(a)*R, cy+_m.sin(a)*R
            ta=a+_m.pi/2
            s=S*0.045
            d.polygon([(ex+_m.cos(ta)*s,ey+_m.sin(ta)*s),
                       (ex-_m.cos(ta)*s,ey-_m.sin(ta)*s),
                       (ex+_m.cos(a)*s*1.4,ey+_m.sin(a)*s*1.4)], fill=col)
        # center card
        cw,chh=S*0.22,S*0.15
        d.rounded_rectangle([cx-cw/2,cy-chh/2,cx+cw/2,cy+chh/2], radius=S*0.02, fill=light)
        d.rounded_rectangle([cx-cw/2,cy-chh/2,cx+cw/2,cy-chh/2+S*0.035], radius=S*0.012, fill=accD(0.05))
    elif motif=="estate":
        # house with a graduation/checkmark badge => real-estate exam
        bw=S*0.40; bh=S*0.26
        bx0,by0=cx-bw/2, cy-S*0.00
        d.rounded_rectangle([bx0,by0,bx0+bw,by0+bh], radius=S*0.025, fill=light)
        d.polygon([(cx-bw*0.60, by0+S*0.005),(cx, cy-S*0.22),(cx+bw*0.60, by0+S*0.005)], fill=A)
        # door
        dw=S*0.095
        d.rounded_rectangle([cx-dw/2, by0+bh-S*0.13, cx+dw/2, by0+bh], radius=S*0.01, fill=accD(0.10))
        # check badge circle lower-right
        bxc,byc=cx+bw*0.42, by0+bh*0.55
        br=S*0.085
        d.ellipse([bxc-br,byc-br,bxc+br,byc+br], fill=A)
        d.line([(bxc-br*0.45,byc),(bxc-br*0.05,byc+br*0.42),(bxc+br*0.55,byc-br*0.4)], fill=light, width=int(S*0.018), joint="curve")
    elif motif=="macro":
        # macro ring (donut) split into 3 arcs (protein/carbs/fat) + flame center
        R=S*0.27; r=S*0.15
        wdt=int(R-r)
        mid=(R+r)/2
        segs=[(0,150,A),(150,260,accL(0.45)),(260,360,accD(0.12))]
        for s,e,col in segs:
            d.arc([cx-mid,cy-mid,cx+mid,cy+mid], start=s, end=e, fill=col, width=wdt)
        # small gaps drawn by background color overlays
        bgc=lerp(hx(topHex),hx(botHex),0.5)
        for ang in [150,260,360]:
            a=math.radians(ang)
            gx,gy=cx+math.cos(a)*mid, cy+math.sin(a)*mid
            d.ellipse([gx-S*0.018,gy-S*0.018,gx+S*0.018,gy+S*0.018], fill=(bgc[0],bgc[1],bgc[2],255))
        # flame in the center
        fr=S*0.085
        d.polygon([(cx,cy-fr*1.6),(cx+fr*0.9,cy+fr*0.2),(cx+fr*0.5,cy+fr*1.1),(cx-fr*0.5,cy+fr*1.1),(cx-fr*0.9,cy+fr*0.2)], fill=light)
        d.ellipse([cx-fr*0.5,cy-fr*0.1,cx+fr*0.5,cy+fr*0.9], fill=accL(0.2))
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
