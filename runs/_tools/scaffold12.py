#!/usr/bin/env python3
"""Orbioom iOS scaffold v12 — boilerplate + on-brand 1024 icons for run 2026-06-16_0613.

Creates per-app: folder tree, project.yml, Info.plist, Assets.xcassets
(AppIcon 1024 PNG + AccentColor + LaunchBackground colorsets), Preview Assets.
Swift sources + README are authored separately. Run from repo root.
"""
import os, math, json
from PIL import Image, ImageDraw

RUN = "runs/2026-06-16_0613-UTC"

def hx(h): return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

# app: (slug, AppName, lower, accentHex, launchLightHex, launchDarkHex, iconTop, iconBot, motif)
APPS = [
    ("01-glint","Glint","glint","8B5CF6","F6F2FF","140A28","2A1A52","120628","gems"),
    ("02-pip","Pip","pip","18A558","F1F6F0","0B1A12","123A24","071A10","dice"),
    ("03-furlong","Furlong","furlong","1F7A4D","F2F5F3","0A1A12","123A28","08160F","road"),
    ("04-hark","Hark","hark","5B6CF0","F3F4FB","0B0E1E","1B1F4A","090B1E","ear"),
    ("05-numen","Numen","numen","C9A24B","F7F3EA","140F22","2A1F44","120C22","numen"),
    ("06-lodestar","Lodestar","lodestar","5AA9E6","EFF3FA","070B18","11244A","060B18","star"),
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

    if motif=="gems":
        # three faceted gems in a tidy row (match-3)
        def gem(gx,gy,r,col):
            top=(gx,gy-r); l=(gx-r*0.92,gy-r*0.18); rr=(gx+r*0.92,gy-r*0.18)
            bl=(gx-r*0.5,gy+r); br=(gx+r*0.5,gy+r)
            d.polygon([top,rr,br,bl,l],fill=col)
            # table facet
            cl=lerp(col[:3],(255,255,255),0.35)
            d.polygon([top,(gx-r*0.42,gy-r*0.18),(gx,gy+r*0.05),(gx+r*0.42,gy-r*0.18)],fill=(cl[0],cl[1],cl[2],255))
            cd=lerp(col[:3],(0,0,0),0.18)
            d.polygon([bl,br,(gx,gy+r*0.05)],fill=(cd[0],cd[1],cd[2],255))
        r=S*0.135
        gem(cx-r*1.9,cy-r*0.55,r,(244,168,196,255))
        gem(cx+r*1.9,cy-r*0.2,r,(120,210,200,255))
        gem(cx,cy+r*1.1,r*1.18,A)
        # sparkle
        sx,sy=cx+r*1.1,cy-r*1.7
        for ang in range(0,360,90):
            a=math.radians(ang); ln=S*0.05
            d.line([(sx,sy),(sx+math.cos(a)*ln,sy+math.sin(a)*ln)],fill=light,width=int(S*0.012))
    elif motif=="dice":
        # two rounded dice, one showing 5 pips, one showing 3, slight tilt feel
        def die(x0,y0,sz,pips,col,pipcol):
            d.rounded_rectangle([x0,y0,x0+sz,y0+sz],radius=sz*0.22,fill=col)
            d.rounded_rectangle([x0,y0,x0+sz,y0+sz],radius=sz*0.22,outline=accD(0.25),width=int(S*0.006))
            pr=sz*0.085
            coords={
                "tl":(0.28,0.28),"tr":(0.72,0.28),"ml":(0.28,0.5),"mr":(0.72,0.5),
                "c":(0.5,0.5),"bl":(0.28,0.72),"br":(0.72,0.72)
            }
            layouts={3:["tl","c","br"],5:["tl","tr","c","bl","br"]}
            for k in layouts[pips]:
                fx,fy=coords[k]
                d.ellipse([x0+fx*sz-pr,y0+fy*sz-pr,x0+fx*sz+pr,y0+fy*sz+pr],fill=pipcol)
        sz=S*0.34
        die(cx-sz*1.02,cy-sz*0.62,sz,5,light,accD(0.05))
        die(cx+sz*0.06,cy-sz*0.18,sz*0.9,3,A,light)
    elif motif=="road":
        # a road receding to a horizon with dashed centre line + sign-green
        d.polygon([(cx-S*0.05,cy-S*0.22),(cx+S*0.05,cy-S*0.22),(cx+S*0.30,cy+S*0.34),(cx-S*0.30,cy+S*0.34)],fill=accD(0.3))
        # dashes
        n=5
        for i in range(n):
            t=i/(n-0.0)
            yy=cy-S*0.20+t*S*0.52
            w=S*0.012+t*S*0.03
            h=S*0.03+t*S*0.03
            d.rounded_rectangle([cx-w,yy,cx+w,yy+h],radius=w*0.5,fill=light)
        # sun/horizon disc
        d.ellipse([cx-S*0.11,cy-S*0.34,cx+S*0.11,cy-S*0.12],fill=A)
    elif motif=="ear":
        # concentric sound arcs emanating to an ear-dot (hearing)
        ox=cx-S*0.12
        for i,rr in enumerate([0.10,0.18,0.26,0.34]):
            col=accL(0.1) if i%2==0 else A
            d.arc([ox-rr*S,cy-rr*S,ox+rr*S,cy+rr*S],-58,58,fill=col,width=int(S*0.028))
        # ear/listener dot
        d.ellipse([ox-S*0.05,cy-S*0.05,ox+S*0.05,cy+S*0.05],fill=light)
    elif motif=="numen":
        # a circle of sacred geometry with a central numeral '7' glyph in gold
        R=S*0.30
        d.ellipse([cx-R,cy-R,cx+R,cy+R],outline=A,width=int(S*0.018))
        d.ellipse([cx-R*0.72,cy-R*0.72,cx+R*0.72,cy+R*0.72],outline=accD(0.18),width=int(S*0.01))
        # vertices star
        pts=[]
        for k in range(9):
            a=math.radians(-90+k*40)
            pts.append((cx+math.cos(a)*R,cy+math.sin(a)*R))
        for i in range(9):
            d.line([pts[i],pts[(i+4)%9]],fill=(acc[0],acc[1],acc[2],120),width=int(S*0.006))
        # numeral 7 strokes
        d.line([(cx-R*0.34,cy-R*0.40),(cx+R*0.34,cy-R*0.40)],fill=light,width=int(S*0.03))
        d.line([(cx+R*0.34,cy-R*0.40),(cx-R*0.02,cy+R*0.44)],fill=light,width=int(S*0.03))
    elif motif=="star":
        # north star (4-point) + scattered stars + faint constellation lines
        small=[(-0.28,-0.22,0.012),(0.24,-0.30,0.010),(0.30,0.10,0.013),(-0.22,0.26,0.011),(0.05,0.30,0.009),(-0.34,0.04,0.009)]
        coords=[]
        for ox,oy,r in small:
            sx,sy=cx+ox*S,cy+oy*S; coords.append((sx,sy))
            d.ellipse([sx-r*S,sy-r*S,sx+r*S,sy+r*S],fill=light)
        # constellation lines
        order=[0,2,4,3,5]
        for i in range(len(order)-1):
            d.line([coords[order[i]],coords[order[i+1]]],fill=(173,200,235,90),width=int(S*0.006))
        # main 4-point star
        R=S*0.20; w=S*0.05
        d.polygon([(cx,cy-R),(cx+w,cy-w),(cx+R,cy),(cx+w,cy+w),(cx,cy+R),(cx-w,cy+w),(cx-R,cy),(cx-w,cy-w)],fill=A)
        d.polygon([(cx,cy-R*0.5),(cx+w*0.5,cy-w*0.5),(cx+R*0.5,cy),(cx+w*0.5,cy+w*0.5),(cx,cy+R*0.5),(cx-w*0.5,cy+w*0.5),(cx-R*0.5,cy),(cx-w*0.5,cy-w*0.5)],fill=accL(0.5))
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
