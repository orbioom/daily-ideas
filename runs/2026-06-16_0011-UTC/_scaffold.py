#!/usr/bin/env python3
"""Orbioom run 2026-06-16 — generate Xcode config + Assets (incl. designed icons)
for all 6 apps. Subagents author the Swift sources only. Pure-PIL icons rendered
at 4x then downsampled for clean edges."""
import os, math, json
from PIL import Image, ImageDraw, ImageFilter

RUN = os.path.dirname(os.path.abspath(__file__))

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

def hx(h):
    h = h.lstrip("#")
    return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))

def lerp(a,b,t):
    return tuple(int(round(a[i]+(b[i]-a[i])*t)) for i in range(3))

def vgrad(draw, w, h, top, bot, diagonal=False):
    for y in range(h):
        t = y/(h-1)
        draw.line([(0,y),(w,y)], fill=lerp(top,bot,t))

def radial_glow(img, cx, cy, radius, color, strength):
    w,h = img.size
    px = img.load()
    for y in range(h):
        for x in range(w):
            d = math.hypot(x-cx, y-cy)/radius
            g = max(0.0, 1.0-d)
            g = g*g*strength
            r,gr,b = px[x,y]
            px[x,y] = (min(255,int(r+(color[0]-r)*g)),
                       min(255,int(gr+(color[1]-gr)*g)),
                       min(255,int(b+(color[2]-b)*g)))

def rrect(d, box, r, **kw):
    d.rounded_rectangle(box, radius=r, **kw)

# ---------------- per-app icon painters (canvas S, supersampled) ----------------
def icon_reel(d, S, A):
    cx, cy = S*0.5, S*0.5
    # film frame ring with sprockets
    white=(245,247,250); soft=(220,224,232)
    # two vertical perforation strips
    strip_w = S*0.12
    for side in (S*0.10, S*0.78):
        rrect(d,[side, S*0.18, side+strip_w, S*0.82], r=S*0.03, fill=(28,30,40))
        for i in range(5):
            yy = S*0.225 + i*(S*0.118)
            rrect(d,[side+strip_w*0.22, yy, side+strip_w*0.78, yy+S*0.06], r=S*0.012, fill=white)
    # center frame
    rrect(d,[S*0.27, S*0.2, S*0.73, S*0.8], r=S*0.05, fill=(18,19,26))
    # play triangle
    t=[(cx-S*0.075, cy-S*0.12),(cx-S*0.075, cy+S*0.12),(cx+S*0.115, cy)]
    d.polygon(t, fill=A)

def icon_tome(d, S, A):
    cx, cy = S*0.5, S*0.52
    page=(248,243,232); page2=(236,229,214); shadow=(120,96,60)
    # book spread: two trapezoid pages
    d.polygon([(cx, cy-S*0.20),(cx-S*0.30, cy-S*0.12),(cx-S*0.30, cy+S*0.22),(cx, cy+S*0.16)], fill=page)
    d.polygon([(cx, cy-S*0.20),(cx+S*0.30, cy-S*0.12),(cx+S*0.30, cy+S*0.22),(cx, cy+S*0.16)], fill=page2)
    # spine
    d.line([(cx, cy-S*0.20),(cx, cy+S*0.16)], fill=shadow, width=int(S*0.012))
    # text lines
    for i in range(4):
        yy = cy-S*0.10 + i*S*0.06
        d.line([(cx-S*0.245, yy),(cx-S*0.05, yy-S*0.012)], fill=(180,160,120), width=int(S*0.012))
        d.line([(cx+S*0.05, yy-S*0.012),(cx+S*0.245, yy)], fill=(170,152,118), width=int(S*0.012))
    # bookmark ribbon
    d.polygon([(cx+S*0.12, cy-S*0.17),(cx+S*0.17, cy-S*0.165),(cx+S*0.165, cy+S*0.02),(cx+S*0.145,cy-S*0.02),(cx+S*0.125,cy+S*0.02)], fill=A)

def icon_recall(d, S, A):
    cx, cy = S*0.5, S*0.5
    # three stacked offset cards
    base=(250,250,253)
    for i,off in enumerate([( S*0.05, S*0.09),(0.0, 0.0),(-S*0.05,-S*0.09)]):
        shade = lerp((255,255,255), A, 0.10*i)
        rrect(d,[cx-S*0.24+off[0], cy-S*0.16+off[1], cx+S*0.24+off[0], cy+S*0.16+off[1]], r=S*0.04, fill=shade)
    # front card content: a big stylized "?" -> checkmark suggestion via lightbulb dot grid
    # draw a check mark on the front card
    d.line([(cx-S*0.10, cy+S*0.00),(cx-S*0.02, cy+S*0.08),(cx+S*0.12, cy-S*0.10)], fill=A, width=int(S*0.04), joint="curve")

def icon_limn(d, S, A):
    # nonogram grid forming a heart
    n=5
    cell = S*0.092
    gw = cell*n
    ox = S*0.5 - gw/2; oy = S*0.5 - gw/2 + S*0.01
    light=(238,242,244); empty=(255,255,255)
    pattern = [
        [0,1,0,1,0],
        [1,1,1,1,1],
        [1,1,1,1,1],
        [0,1,1,1,0],
        [0,0,1,0,0],
    ]
    for r in range(n):
        for c in range(n):
            x0=ox+c*cell; y0=oy+r*cell
            fill = A if pattern[r][c] else empty
            rrect(d,[x0+S*0.006,y0+S*0.006,x0+cell-S*0.006,y0+cell-S*0.006], r=S*0.012, fill=fill)

def icon_encore(d, S, A):
    cx, cy = S*0.5, S*0.52
    # stage light beams from top
    beam=(255,255,255)
    for bx,col in [(S*0.30,(255,255,255)),(S*0.70,(255,255,255))]:
        d.polygon([(bx, S*0.10),(bx-S*0.10, S*0.92),(bx+S*0.10, S*0.92)], fill=(255,255,255,40))
    # ticket stub
    tw, th = S*0.46, S*0.26
    x0,y0 = cx-tw/2, cy-th/2+S*0.04
    rrect(d,[x0,y0,x0+tw,y0+th], r=S*0.03, fill=(250,248,252))
    # perforation notch (dashed line)
    nx = x0+tw*0.66
    for i in range(7):
        yy=y0+S*0.02+i*(th-S*0.04)/6
        d.ellipse([nx-S*0.008,yy-S*0.008,nx+S*0.008,yy+S*0.008], fill=A)
    # star on stub
    star_c=(cx-tw*0.16, cy+S*0.04)
    star(d, star_c[0], star_c[1], S*0.075, S*0.032, A)

def star(d, cx, cy, ro, ri, fill, points=5, rot=-math.pi/2):
    pts=[]
    for i in range(points*2):
        r = ro if i%2==0 else ri
        a = rot + i*math.pi/points
        pts.append((cx+r*math.cos(a), cy+r*math.sin(a)))
    d.polygon(pts, fill=fill)

def icon_astra(d, S, A):
    cx, cy = S*0.5, S*0.5
    gold=(245,214,131)
    white=(240,242,250)
    # zodiac ring
    d.ellipse([cx-S*0.34, cy-S*0.34, cx+S*0.34, cy+S*0.34], outline=(120,110,170), width=int(S*0.012))
    d.ellipse([cx-S*0.40, cy-S*0.40, cx+S*0.40, cy+S*0.40], outline=(80,72,120), width=int(S*0.008))
    # crescent moon (two overlapping circles)
    mc=(cx+S*0.02, cy-S*0.02); mr=S*0.20
    d.ellipse([mc[0]-mr,mc[1]-mr,mc[0]+mr,mc[1]+mr], fill=gold)
    off=S*0.085
    # cut crescent by painting bg-colored circle — use a separate approach: draw smaller circle of bg
    d.ellipse([mc[0]-mr+off,mc[1]-mr-off*0.6,mc[0]+mr+off,mc[1]+mr-off*0.6], fill=(20,18,42))
    # stars / constellation
    coords=[(cx-S*0.22,cy+S*0.18),(cx-S*0.06,cy+S*0.27),(cx+S*0.12,cy+S*0.20),(cx+S*0.26,cy+S*0.30)]
    for i in range(len(coords)-1):
        d.line([coords[i],coords[i+1]], fill=(150,160,210), width=int(S*0.006))
    for p in coords:
        star(d, p[0], p[1], S*0.028, S*0.011, white)
    # scattered tiny stars
    for p in [(cx-S*0.30,cy-S*0.22),(cx+S*0.30,cy-S*0.10),(cx-S*0.16,cy-S*0.30),(cx+S*0.20,cy-S*0.28)]:
        star(d, p[0], p[1], S*0.018, S*0.007, gold)

ICONS = {
    "Reel":   (icon_reel,   "#0E0F14", "#241016", "#E63950"),
    "Tome":   (icon_tome,   "#2A1C0E", "#3A2410", "#D98A2B"),
    "Recall": (icon_recall, "#161531", "#241F4A", "#6C5CE7"),
    "Limn":   (icon_limn,   "#06262B", "#0B3A40", "#13B6A8"),
    "Encore": (icon_encore, "#1A0A23", "#2A0F3A", "#C2459B"),
    "Astra":  (icon_astra,  "#14122A", "#221E46", "#8B7CE8"),
}

def make_icon(app, painter, bg_top, bg_bot, accent, out):
    SS = 4
    S = 1024*SS
    img = Image.new("RGB",(S,S),hx(bg_top))
    d = ImageDraw.Draw(img)
    vgrad(d, S, S, hx(bg_top), hx(bg_bot))
    radial_glow(img, S*0.5, S*0.32, S*0.7, hx(accent), 0.22)
    d = ImageDraw.Draw(img, "RGBA")
    painter(d, S, hx(accent))
    img = img.resize((1024,1024), Image.LANCZOS)
    img.save(out, "PNG")

# ---------------- asset catalogs / plist / project.yml ----------------
def accent_colorset(accent):
    r,g,b = hx(accent)
    return json.dumps({
        "colors":[{"color":{"color-space":"srgb","components":{
            "red":f"0x{r:02X}","green":f"0x{g:02X}","blue":f"0x{b:02X}","alpha":"1.000"}},
            "idiom":"universal"}],
        "info":{"author":"xcode","version":1}}, indent=2)

def launch_colorset(light, dark):
    lr,lg,lb = hx(light); dr,dg,db = hx(dark)
    return json.dumps({
        "colors":[
            {"color":{"color-space":"srgb","components":{
                "red":f"0x{lr:02X}","green":f"0x{lg:02X}","blue":f"0x{lb:02X}","alpha":"1.000"}},
                "idiom":"universal"},
            {"appearances":[{"appearance":"luminosity","value":"dark"}],
             "color":{"color-space":"srgb","components":{
                "red":f"0x{dr:02X}","green":f"0x{dg:02X}","blue":f"0x{db:02X}","alpha":"1.000"}},
             "idiom":"universal"}],
        "info":{"author":"xcode","version":1}}, indent=2)

APPICON_CONTENTS = json.dumps({
    "images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
    "info":{"author":"xcode","version":1}}, indent=2)
ROOT_CONTENTS = json.dumps({"info":{"author":"xcode","version":1}}, indent=2)

def project_yml(App, lower):
    return f"""name: {App}
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

def info_plist(App, portrait_only=True):
    orient = "<array><string>UIInterfaceOrientationPortrait</string></array>"
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleDisplayName</key><string>{App}</string>
	<key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key><string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key><string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key><string>$(CURRENT_PROJECT_VERSION)</string>
	<key>LSRequiresIPhoneOS</key><true/>
	<key>UIApplicationSceneManifest</key>
	<dict><key>UIApplicationSupportsMultipleScenes</key><false/></dict>
	<key>UILaunchScreen</key>
	<dict><key>UIColorName</key><string>LaunchBackground</string></dict>
	<key>UIRequiredDeviceCapabilities</key><array><string>arm64</string></array>
	<key>UISupportedInterfaceOrientations</key>
	{orient}
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>
"""

APPS = {
    "01-reel":   ("Reel","reel"),
    "02-tome":   ("Tome","tome"),
    "03-recall": ("Recall","recall"),
    "04-limn":   ("Limn","limn"),
    "05-encore": ("Encore","encore"),
    "06-astra":  ("Astra","astra"),
}

for slug,(App,lower) in APPS.items():
    painter, bgt, bgd, accent = ICONS[App]
    ios = os.path.join(RUN, slug, "ios")
    appdir = os.path.join(ios, App)            # ios/<App>
    src = os.path.join(appdir, App)            # ios/<App>/<App>
    assets = os.path.join(src, "Assets.xcassets")
    write(os.path.join(ios,"project.yml"), project_yml(App, lower))
    write(os.path.join(appdir,"Info.plist"), info_plist(App))
    write(os.path.join(assets,"Contents.json"), ROOT_CONTENTS)
    write(os.path.join(assets,"AppIcon.appiconset","Contents.json"), APPICON_CONTENTS)
    write(os.path.join(assets,"AccentColor.colorset","Contents.json"), accent_colorset(accent))
    write(os.path.join(assets,"LaunchBackground.colorset","Contents.json"), launch_colorset("#F6F3EE", bgt))
    os.makedirs(os.path.join(appdir,"Preview Content","Preview Assets.xcassets"), exist_ok=True)
    write(os.path.join(appdir,"Preview Content","Preview Assets.xcassets","Contents.json"), ROOT_CONTENTS)
    make_icon(App, painter, bgt, bgd, accent, os.path.join(assets,"AppIcon.appiconset","icon-1024.png"))
    print("scaffolded", App)

print("done")
