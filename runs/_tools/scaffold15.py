#!/usr/bin/env python3
"""Orbioom iOS scaffold v15 — boilerplate + on-brand 1024 icons for run 2026-06-17_0611.

Creates per-app: folder tree, project.yml, Info.plist, Assets.xcassets
(AppIcon 1024 PNG + AccentColor + LaunchBackground colorsets), Preview Assets.
Swift sources + README are authored separately. Run from repo root.
"""
import os, math, json
from PIL import Image, ImageDraw

RUN = "runs/2026-06-17_0611-UTC"

def hx(h): return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

# app: (slug, AppName, lower, accentHex, launchLightHex, launchDarkHex, iconTop, iconBot, motif)
APPS = [
    ("01-lexicon","Lexicon","lexicon","6AAA64","F5F2EA","10120F","1F5D2E","08160C","tiles"),
    ("02-pitch","Pitch","pitch","5B6CF0","EEF0FC","0A0C1A","1B2A6E","070A16","fork"),
    ("03-lace","Lace","lace","E4574C","FFF1EF","1E0C0A","5C1A14","1A0807","track"),
    ("04-hush","Hush","hush","2E8E9E","EAF3F5","081316","103A42","061417","moon"),
    ("05-arcana","Arcana","arcana","8E54C9","F3EEFB","120A1E","3A1A5E","0E0718","tarot"),
    ("06-abode","Abode","abode","2D6CB3","EBF1F9","070D16","12345E","05101C","house"),
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

    if motif=="tiles":
        # a row of three rounded letter tiles, middle one accent-filled (a "correct" guess)
        tw=S*0.22; gap=S*0.045
        total=3*tw+2*gap
        x0=cx-total/2; y0=cy-tw/2
        fills=[accD(0.30), A, accL(0.55)]
        for i in range(3):
            xa=x0+i*(tw+gap)
            d.rounded_rectangle([xa,y0,xa+tw,y0+tw], radius=S*0.028, fill=fills[i])
            # a small glyph bar to suggest a letter
            gx=xa+tw*0.5; gy=y0+tw*0.5; gr=tw*0.20
            col = light if i==1 else light
            d.line([(gx-gr,gy+gr),(gx,gy-gr),(gx+gr,gy+gr)], fill=col, width=int(S*0.018), joint="curve")
            d.line([(gx-gr*0.55,gy+gr*0.1),(gx+gr*0.55,gy+gr*0.1)], fill=col, width=int(S*0.016))
    elif motif=="fork":
        # a tuning fork: two prongs + stem, plus a small pitch dot
        pw=int(S*0.07)
        leftx, rightx = cx-S*0.11, cx+S*0.11
        topy = cy-S*0.26
        boty = cy+S*0.06
        d.line([(leftx, topy),(leftx, boty)], fill=A, width=pw)
        d.line([(rightx, topy),(rightx, boty)], fill=A, width=pw)
        # rounded prong tops
        for xx in (leftx, rightx):
            d.ellipse([xx-pw/2, topy-pw/2, xx+pw/2, topy+pw/2], fill=A)
        # bridge connecting the prongs at the bottom
        d.line([(leftx, boty),(rightx, boty)], fill=A, width=pw)
        # stem
        d.line([(cx, boty),(cx, cy+S*0.27)], fill=A, width=pw)
        d.ellipse([cx-pw/2, cy+S*0.27-pw/2, cx+pw/2, cy+S*0.27+pw/2], fill=A)
        # a light vibration dot to suggest sound
        d.ellipse([cx-S*0.022, topy-S*0.13, cx+S*0.022, topy-S*0.13+S*0.044], fill=light)
    elif motif=="track":
        # a running track: two concentric stadium (rounded-rect) ovals = lanes
        ow,oh=S*0.62,S*0.40
        rad=oh/2
        d.rounded_rectangle([cx-ow/2,cy-oh/2,cx+ow/2,cy+oh/2], radius=rad, outline=A, width=int(S*0.055))
        iw,ih=S*0.40,S*0.20
        d.rounded_rectangle([cx-iw/2,cy-ih/2,cx+iw/2,cy+ih/2], radius=ih/2, outline=accL(0.45), width=int(S*0.040))
        # a start dot on the track
        d.ellipse([cx-ow/2-S*0.018, cy-S*0.024, cx-ow/2+S*0.030, cy+S*0.024], fill=light)
    elif motif=="moon":
        # crescent moon + three sound-wave arcs
        mr=S*0.20
        mx,my=cx-S*0.06, cy-S*0.02
        d.ellipse([mx-mr,my-mr,mx+mr,my+mr], fill=light)
        # carve crescent by overlaying a bg-colored circle
        bgc=lerp(top,bot,0.45)
        offx=S*0.10
        d.ellipse([mx-mr+offx,my-mr-S*0.02,mx+mr+offx,my+mr-S*0.02], fill=(bgc[0],bgc[1],bgc[2],255))
        # sound waves to the right
        for i,r in enumerate([S*0.10,S*0.16,S*0.22]):
            ax,ay=cx+S*0.18, cy-S*0.02
            d.arc([ax-r,ay-r,ax+r,ay+r], start=-55, end=55, fill=A if i==0 else accL(0.2+0.15*i), width=int(S*0.026))
        # a small star
        sx,sy=cx+S*0.02, cy-S*0.22
        d.ellipse([sx-S*0.02,sy-S*0.02,sx+S*0.02,sy+S*0.02], fill=light)
    elif motif=="tarot":
        # an upright tarot card bearing an eight-pointed star + crescent
        cw,ch=S*0.34,S*0.50
        d.rounded_rectangle([cx-cw/2,cy-ch/2,cx+cw/2,cy+ch/2], radius=S*0.035, fill=accD(0.18))
        # inner border
        m=S*0.028
        d.rounded_rectangle([cx-cw/2+m,cy-ch/2+m,cx+cw/2-m,cy+ch/2-m], radius=S*0.025, outline=accL(0.5), width=int(S*0.010))
        # eight-pointed star
        R=S*0.115; r=S*0.045
        pts=[]
        for k in range(16):
            ang=math.pi*2*k/16 - math.pi/2
            rad=R if k%2==0 else r
            pts.append((cx+math.cos(ang)*rad, cy-S*0.03+math.sin(ang)*rad))
        d.polygon(pts, fill=light)
        # small crescent below the star
        cmx,cmy,cmr=cx, cy+S*0.16, S*0.05
        d.ellipse([cmx-cmr,cmy-cmr,cmx+cmr,cmy+cmr], fill=accL(0.4))
        bgc=lerp(hx(topHex),hx(botHex),0.4)
        d.ellipse([cmx-cmr+S*0.03,cmy-cmr,cmx+cmr+S*0.03,cmy+cmr], fill=accD(0.18))
    elif motif=="house":
        # a house with a roof + a percent badge (mortgage)
        bw=S*0.40; bh=S*0.26
        bx0,by0=cx-bw/2, cy-S*0.00
        d.rounded_rectangle([bx0,by0,bx0+bw,by0+bh], radius=S*0.022, fill=light)
        d.polygon([(cx-bw*0.62, by0+S*0.005),(cx, cy-S*0.22),(cx+bw*0.62, by0+S*0.005)], fill=A)
        # door
        dw=S*0.10
        d.rounded_rectangle([cx-dw/2, by0+bh-S*0.14, cx+dw/2, by0+bh], radius=S*0.012, fill=accD(0.10))
        # percent badge upper-right of the building
        pxc,pyc=cx+bw*0.46, cy-S*0.16
        pr=S*0.10
        d.ellipse([pxc-pr,pyc-pr,pxc+pr,pyc+pr], fill=A)
        # percent sign: diagonal + two dots
        d.line([(pxc-pr*0.40,pyc+pr*0.42),(pxc+pr*0.40,pyc-pr*0.42)], fill=light, width=int(S*0.014))
        dr=pr*0.20
        d.ellipse([pxc-pr*0.42-dr,pyc-pr*0.40-dr,pxc-pr*0.42+dr,pyc-pr*0.40+dr], fill=light)
        d.ellipse([pxc+pr*0.42-dr,pyc+pr*0.40-dr,pxc+pr*0.42+dr,pyc+pr*0.40+dr], fill=light)
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
