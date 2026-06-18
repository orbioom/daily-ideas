#!/usr/bin/env python3
"""Orbioom iOS scaffold v18 — boilerplate + on-brand 1024 icons for run 2026-06-18_0725.

Creates per-app: folder tree, project.yml, Info.plist, Assets.xcassets
(AppIcon 1024 PNG + AccentColor + LaunchBackground colorsets), Preview Assets.
Swift sources + README are authored separately. Run from repo root.
"""
import os, math, json
from PIL import Image, ImageDraw

RUN = "runs/2026-06-18_0725-UTC"

def hx(h): return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

# (slug, AppName, lower, accentHex, launchLightHex, launchDarkHex, iconTopHex, iconBotHex, motif)
APPS = [
    ("01-pangram","Pangram","pangram","E0A92B","FFF7E6","14100A","7A5A10","1E1606","hex"),
    ("02-crest","Crest","crest","1FA463","EAF6EF","06140D","0E5C3A","04140C","peaks"),
    ("03-glimpse","Glimpse","glimpse","F2664B","FFF1EC","16100E","8A2E1E","1C0A06","frame"),
    ("04-fetch","Fetch","fetch","2E86DE","EAF2FC","06101C","134A87","04101C","paw"),
    ("05-assay","Assay","assay","0E9AA8","E9F6F7","041416","0A5A63","03141A","vial"),
    ("06-crisp","Crisp","crisp","F2792B","FFF2E8","160C04","9A3E0E","1E0C04","basket"),
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

    def hexagon(ccx,ccy,r,fill,outline=None,w=0):
        pts=[(ccx+r*math.cos(math.radians(60*k-90)), ccy+r*math.sin(math.radians(60*k-90))) for k in range(6)]
        d.polygon(pts, fill=fill, outline=outline, width=w)

    if motif=="hex":
        # honeycomb cluster: center accent hex + 6 surrounding (spelling bee)
        r=S*0.135; dx=r*math.sqrt(3); dy=r*1.5
        centers=[(0,0),(dx,0),(-dx,0),(dx/2,-dy),(-dx/2,-dy),(dx/2,dy),(-dx/2,dy)]
        for i,(ox,oy) in enumerate(centers):
            fill = A if (ox==0 and oy==0) else (accL(0.20) if (i%2==0) else accL(0.34))
            hexagon(cx+ox, cy+oy, r*0.92, fill)
        # a small light dot in the center hex (the queen letter)
        d.ellipse([cx-S*0.045, cy-S*0.045, cx+S*0.045, cy+S*0.045], fill=light)
    elif motif=="peaks":
        # three peaks (tri-peaks solitaire) made of triangles + a card resting below
        baseY=cy+S*0.20
        peaks=[(cx-S*0.24, S*0.30),(cx, S*0.36),(cx+S*0.24, S*0.30)]
        for i,(pxv,h) in enumerate(peaks):
            fill = A if i==1 else (accL(0.22) if i==0 else accL(0.34))
            d.polygon([(pxv, baseY-h),(pxv-S*0.155, baseY),(pxv+S*0.155, baseY)], fill=fill)
        # a playing card (rounded rect) at the foundation
        cw,ch=S*0.20,S*0.27
        d.rounded_rectangle([cx-cw/2, baseY+S*0.02, cx+cw/2, baseY+S*0.02+ch], radius=S*0.026, fill=light)
        d.ellipse([cx-S*0.035, baseY+S*0.11, cx+S*0.035, baseY+S*0.18], fill=A)
    elif motif=="frame":
        # a photo frame with a mountain/sun snapshot + a corner "day" dot grid (moment a day)
        fr=S*0.30
        d.rounded_rectangle([cx-fr, cy-fr, cx+fr, cy+fr], radius=S*0.06, fill=accD(0.10))
        inset=S*0.045
        d.rounded_rectangle([cx-fr+inset, cy-fr+inset, cx+fr-inset, cy+fr-inset], radius=S*0.04, fill=accL(0.30))
        # sun
        d.ellipse([cx+S*0.06, cy-S*0.17, cx+S*0.06+S*0.10, cy-S*0.17+S*0.10], fill=light)
        # hills
        d.polygon([(cx-fr+inset, cy+fr-inset),(cx-S*0.06, cy+S*0.02),(cx+S*0.10, cy+fr-inset)], fill=A)
        d.polygon([(cx-S*0.02, cy+fr-inset),(cx+S*0.12, cy-S*0.02),(cx+fr-inset, cy+fr-inset)], fill=accD(0.22))
        # shutter dot
        d.ellipse([cx-fr-S*0.0, cy-fr-S*0.0, cx-fr+S*0.0, cy-fr+S*0.0])
    elif motif=="paw":
        # a friendly paw print (dog training)
        # main pad
        d.ellipse([cx-S*0.15, cy-S*0.02, cx+S*0.15, cy+S*0.27], fill=A)
        # toes
        toes=[(-0.18,-0.16,0.085),(-0.06,-0.24,0.095),(0.06,-0.24,0.095),(0.18,-0.16,0.085)]
        for tx,ty,rr in toes:
            d.ellipse([cx+S*tx-S*rr, cy+S*ty-S*rr, cx+S*tx+S*rr, cy+S*ty+S*rr], fill=accL(0.18))
        # little bone highlight on the pad
        d.ellipse([cx-S*0.05, cy+S*0.07, cx+S*0.05, cy+S*0.17], fill=light)
    elif motif=="vial":
        # a test tube with liquid + level ticks and a tiny trend spark (lab results)
        tw=S*0.16
        x0,x1=cx-tw/2, cx+tw/2; y0,y1=cy-S*0.27, cy+S*0.27
        # tube outline
        d.rounded_rectangle([x0,y0,x1,y1], radius=tw/2, outline=light, width=int(S*0.018))
        # liquid (lower 55%)
        ly=y1-(y1-y0)*0.55
        d.rounded_rectangle([x0+S*0.012, ly, x1-S*0.012, y1-S*0.012], radius=tw/2-S*0.012, fill=A)
        # surface ellipse
        d.ellipse([x0+S*0.012, ly-S*0.02, x1-S*0.012, ly+S*0.02], fill=accL(0.25))
        # ticks on the right
        for k in range(1,5):
            ty=y0+(y1-y0)*k/5.0
            d.line([(x1+S*0.02, ty),(x1+S*0.07, ty)], fill=light, width=int(S*0.010))
        # tiny upward trend marker (droplet) top-left
        d.ellipse([cx-S*0.27, cy-S*0.24, cx-S*0.27+S*0.07, cy-S*0.24+S*0.09], fill=accL(0.30))
    elif motif=="basket":
        # an air-fryer basket (rounded trapezoid) with mesh dots + rising heat waves (crisp)
        # heat waves
        for i,oy in enumerate([-0.30,-0.30,-0.30]):
            bx=cx-S*0.16+i*S*0.16
            pts=[(bx+math.sin(t*math.pi*2)*S*0.02, cy+oy*S - t*S*0.10) for t in [x/10 for x in range(11)]]
            d.line(pts, fill=accL(0.40), width=int(S*0.016), joint="curve")
        # basket body (trapezoid, rounded)
        topw,botw=S*0.46,S*0.34; ty=cy-S*0.06; by=cy+S*0.28
        d.polygon([(cx-topw/2,ty),(cx+topw/2,ty),(cx+botw/2,by),(cx-botw/2,by)], fill=A)
        # rim
        d.line([(cx-topw/2,ty),(cx+topw/2,ty)], fill=light, width=int(S*0.03))
        # mesh dots
        for r in range(3):
            for c in range(5):
                mx=cx-S*0.16+c*S*0.08; my=ty+S*0.06+r*S*0.07
                if abs(mx-cx) < (topw/2 - (my-ty)/(by-ty)*(topw-botw)/2) - S*0.02:
                    d.ellipse([mx-S*0.012,my-S*0.012,mx+S*0.012,my+S*0.012], fill=accD(0.30))

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
        with open(f"{base}/project.yml","w") as f: f.write(PROJ.format(name=name,lower=lower))
        with open(f"{base}/{name}/Info.plist","w") as f: f.write(PLIST.format(name=name))
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
