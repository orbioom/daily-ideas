#!/usr/bin/env python3
"""Orbioom iOS scaffold v4: shared boilerplate + on-brand 1024 app icon (PIL)
   + emits shared Brand.swift and Haptics.swift into each app.

Motifs for the 2026-06-10 (afternoon) run:
  rays (affirmations), neuron (brain training), grid (sudoku),
  tiles (word game), collage (photo collage), fork (tuner)

Usage:
  python3 scaffold4.py <app_root_ios_dir> <App> <lower> <accentHexRRGGBB> <motif>
"""
import os, sys, json, math
from PIL import Image, ImageDraw, ImageFilter

ios_dir, App, lower, hexv, motif = sys.argv[1:6]
app_dir = os.path.join(ios_dir, App)

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

def hx(h):
    return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))
accent = hx(hexv)

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
            t = y / S
            base = lerp(top, bot, t)
            dd = math.hypot(x-cx, y-cy) / (S*0.75)
            glow = max(0.0, 1.0 - dd)
            g = 0.16 * glow*glow
            px[x,y] = (
                int(base[0]+(255-base[0])*g*0.10),
                int(base[1]+(255-base[1])*g*0.10),
                int(base[2]+(255-base[2])*g*0.12),
            )
    d = ImageDraw.Draw(img, "RGBA")
    light = (236,238,243,255)
    silver = (200,205,220,255)
    green = hx("5EF0B0")
    gr = (green[0],green[1],green[2],255)
    acc = (accent[0],accent[1],accent[2],255)

    if motif == "rays":  # affirmations — a luminous rising sun with rays
        # rays
        for k in range(16):
            a = math.radians(k*22.5)
            r0 = 250; r1 = 360
            x0 = cx + r0*math.cos(a); y0 = cy + r0*math.sin(a)
            x1 = cx + r1*math.cos(a); y1 = cy + r1*math.sin(a)
            col = gr if k % 4 == 0 else (light[0],light[1],light[2],150)
            d.line([(x0,y0),(x1,y1)], fill=col, width=18)
        # core disc (luminous)
        d.ellipse([cx-180, cy-180, cx+180, cy+180], fill=gr)
        # calm inner ring
        d.ellipse([cx-110, cy-110, cx+110, cy+110], outline=(20,24,30,150), width=14)
    elif motif == "neuron":  # brain training — node graph, one luminous node
        nodes = []
        for (ang, r) in [(90,0),(20,210),(95,230),(160,200),(230,220),(300,210),(345,150)]:
            a = math.radians(ang)
            nodes.append((cx + r*math.cos(a), cy + r*math.sin(a)))
        edges = [(0,1),(0,2),(0,3),(0,4),(0,5),(1,6),(5,6),(2,3)]
        for (i,j) in edges:
            d.line([nodes[i], nodes[j]], fill=(silver[0],silver[1],silver[2],150), width=10)
        for i,p in enumerate(nodes):
            c = gr if i == 0 else light
            rr = 54 if i == 0 else 34
            d.ellipse([p[0]-rr, p[1]-rr, p[0]+rr, p[1]+rr], fill=c)
    elif motif == "grid":  # sudoku — 3x3 grid, one luminous cell + a numeral
        n = 3; total = 420; cell = total/n
        x0 = cx-total/2; y0 = cy-total/2
        # luminous filled cell
        d.rounded_rectangle([x0+cell, y0, x0+2*cell, y0+cell], radius=8, fill=gr)
        for k in range(n+1):
            w = 20 if k % n == 0 else 10
            d.line([(x0+k*cell, y0),(x0+k*cell, y0+total)], fill=light, width=w)
            d.line([(x0, y0+k*cell),(x0+total, y0+k*cell)], fill=light, width=w)
        # a small numeral mark in the luminous cell (a simple "5" via strokes)
        mx = x0+1.5*cell; my = y0+0.5*cell
        d.line([(mx-30,my-46),(mx+30,my-46)], fill=(20,24,30,230), width=16)
        d.line([(mx-30,my-46),(mx-30,my-2)], fill=(20,24,30,230), width=16)
        d.line([(mx-30,my-2),(mx+30,my-2)], fill=(20,24,30,230), width=16)
        d.line([(mx+30,my-2),(mx+30,my+46)], fill=(20,24,30,230), width=16)
        d.line([(mx-30,my+46),(mx+30,my+46)], fill=(20,24,30,230), width=16)
    elif motif == "tiles":  # word game — row of letter tiles, one luminous (correct)
        n = 4; tw = 170; gap = 26
        total = n*tw + (n-1)*gap
        sx = cx - total/2
        ty = cy - tw/2
        cols = [light, gr, silver, light]
        for k in range(n):
            x = sx + k*(tw+gap)
            d.rounded_rectangle([x, ty, x+tw, ty+tw], radius=24, fill=cols[k])
            # glyph bar
            gx = x + tw*0.5
            d.line([(gx-44, ty+tw*0.34),(gx+44, ty+tw*0.34)], fill=(20,24,30,210), width=20)
            d.line([(gx-44, ty+tw*0.62),(gx-2, ty+tw*0.62)], fill=(20,24,30,210), width=20)
    elif motif == "collage":  # photo collage — 2x2 frame grid, one luminous tile
        total = 440; gap = 26; cell = (total-gap)/2
        x0 = cx-total/2; y0 = cy-total/2
        spots = [(0,0,light),(1,0,silver),(0,1,silver),(1,1,gr)]
        for (cxi, cyi, col) in spots:
            x = x0 + cxi*(cell+gap); y = y0 + cyi*(cell+gap)
            d.rounded_rectangle([x, y, x+cell, y+cell], radius=22, fill=col)
            # tiny mountain/photo motif inside the light tiles
            if col != gr:
                d.polygon([(x+cell*0.2, y+cell*0.78),(x+cell*0.45, y+cell*0.45),(x+cell*0.7, y+cell*0.78)], fill=(42,46,58,170))
                d.ellipse([x+cell*0.62, y+cell*0.2, x+cell*0.82, y+cell*0.4], fill=(42,46,58,150))
    elif motif == "fork":  # tuner — tuning fork with a luminous pitch needle
        # fork stem
        d.rounded_rectangle([cx-26, cy+60, cx+26, cy+300], radius=20, fill=light)
        # fork tines
        d.rounded_rectangle([cx-130, cy-300, cx-78, cy+90], radius=26, fill=light)
        d.rounded_rectangle([cx+78, cy-300, cx+130, cy+90], radius=26, fill=light)
        d.rounded_rectangle([cx-130, cy+40, cx+130, cy+92], radius=26, fill=light)
        # luminous needle / pitch arc
        d.arc([cx-230, cy-120, cx+230, cy+340], 200, 340, fill=(green[0],green[1],green[2],150), width=16)
        d.line([(cx, cy+110),(cx+150, cy-40)], fill=gr, width=22)
        d.ellipse([cx-22, cy+88, cx+22, cy+132], fill=gr)

    img = img.filter(ImageFilter.GaussianBlur(0.4))
    img = img.convert("RGBA")
    img.save(path, "PNG")

write(os.path.join(app_dir,"Assets.xcassets","Contents.json"), json.dumps({"info":{"author":"xcode","version":1}}, indent=2))
write(os.path.join(app_dir,"Assets.xcassets","AppIcon.appiconset","Contents.json"),
      json.dumps({"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
                  "info":{"author":"xcode","version":1}}, indent=2))
make_icon(os.path.join(app_dir,"Assets.xcassets","AppIcon.appiconset","icon-1024.png"))

def colorset(name, light, dark):
    def comp(h):
        return {"red": f"0x{h[0:2]}", "green": f"0x{h[2:4]}", "blue": f"0x{h[4:6]}", "alpha": "1.000"}
    obj = {"colors": [
        {"idiom":"universal","color":{"color-space":"srgb","components":comp(light)}},
        {"idiom":"universal","appearances":[{"appearance":"luminosity","value":"dark"}],
         "color":{"color-space":"srgb","components":comp(dark)}},
    ], "info":{"author":"xcode","version":1}}
    write(os.path.join(app_dir,"Assets.xcassets",name+".colorset","Contents.json"), json.dumps(obj, indent=2))

colorset("AccentColor", hexv, "F2F3F8")
colorset("LaunchBackground", "EDEEF3", "14151B")
write(os.path.join(app_dir,"Preview Content","Preview Assets.xcassets","Contents.json"),
      json.dumps({"info":{"author":"xcode","version":1}}, indent=2))

info = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDevelopmentRegion</key>
\t<string>$(DEVELOPMENT_LANGUAGE)</string>
\t<key>CFBundleDisplayName</key>
\t<string>%s</string>
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
''' % App
write(os.path.join(app_dir,"Info.plist"), info)

proj = '''name: %(App)s
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  %(App)s:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - %(App)s
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.%(lower)s
        INFOPLIST_FILE: %(App)s/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        DEVELOPMENT_ASSET_PATHS: "\\"%(App)s/Preview Content\\""
''' % {"App": App, "lower": lower}
write(os.path.join(ios_dir,"project.yml"), proj)

# ---- Shared Brand.swift ----
brand = r'''import SwiftUI

/// Orbioom brand system: color tokens, typography, motion, and shared surface
/// primitives in one place. Colors resolve per color scheme so light and dark
/// are both first-class. "Conjured, not just coded."
enum Brand {

    // MARK: - Color resolution
    static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }

    static let mist1 = dynamic(0xEDEEF3, 0x14151B)
    static let mist2 = dynamic(0xE7E9F0, 0x191B22)
    static let mist3 = dynamic(0xECEEF2, 0x1E2027)

    static let text  = dynamic(0x1B1D2A, 0xF2F3F8)
    static let text2 = dynamic(0x565A70, 0xB4B8CC)
    static let text3 = dynamic(0x8B8FA3, 0x7C8095)

    static let live   = dynamic(0x4FB98C, 0x86C79A)
    static let magic  = dynamic(0x3E9E78, 0x5EF0B0)
    static let warn   = dynamic(0xC08A3E, 0xE0B86A)
    static let danger = dynamic(0xC0553E, 0xE08A78)
    static let info   = dynamic(0x4E6BA8, 0x8FAEE8)

    static let glassStroke = dynamic(0xFFFFFF, 0x3A3D49)
    static let hairline    = dynamic(0xD7DAE4, 0x2C2F38)
    static let cardShadow  = Color(UIColor { t in
        UIColor(hex: t.userInterfaceStyle == .dark ? 0x000000 : 0x282C50)
            .withAlphaComponent(t.userInterfaceStyle == .dark ? 0.45 : 0.12)
    })

    static let inkGradient = LinearGradient(
        colors: [Color(hex: 0x3A3E4C), Color(hex: 0x23262F)],
        startPoint: .top, endPoint: .bottom
    )

    static var pageBackground: some View {
        LinearGradient(colors: [mist1, mist2, mist3],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    // MARK: - Motion
    static func ease(_ duration: Double = 0.45) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }

    // MARK: - Typography
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension Color {
    init(hex: UInt32) { self.init(UIColor(hex: hex)) }
}

// MARK: - Shared surface primitives

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Brand.cardShadow, radius: 14, x: 0, y: 8)
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        GlassCard(padding: padding) { self }
    }
}

struct InkButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Brand.inkGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .shadow(color: Brand.cardShadow, radius: 8, x: 0, y: 4)
            .animation(Brand.ease(0.2), value: configuration.isPressed)
    }
}

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Brand.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(Brand.ease(0.2), value: configuration.isPressed)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Brand.mono(12, weight: .medium))
            .tracking(1.4)
            .foregroundStyle(Brand.text3)
    }
}

struct StatusDot: View {
    var color: Color = Brand.live
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.7), radius: 4)
            .accessibilityHidden(true)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
    }
}
'''
write(os.path.join(app_dir,"Theme","Brand.swift"), brand)

# ---- Shared Haptics.swift ----
haptics = r'''import UIKit

/// Sparse, meaningful haptics. Gated by the user's Settings toggle.
enum Haptics {
    static var enabled = true

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selection() {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
'''
write(os.path.join(app_dir,"Utilities","Haptics.swift"), haptics)

print(f"scaffolded {App} ({motif}) accent #{hexv}")
