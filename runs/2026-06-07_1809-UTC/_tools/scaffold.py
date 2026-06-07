#!/usr/bin/env python3
"""Scaffold the shared, on-brand Orbioom boilerplate for one iOS app.

Usage:
    python3 scaffold.py <AppName> <slug> <glyph>

Generates, under <run>/<slug>/ios/, every app-agnostic file (Brand theme,
Haptics, shared Components, asset catalog, AppIcon, Info.plist, project.yml,
preview assets). App-specific Swift (App entry, RootView, Models, Engine,
Views, SampleData, Onboarding, Settings, README) is written separately.
"""
import os
import sys
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
RUN = os.path.dirname(HERE)

BRAND_SWIFT = r'''import SwiftUI

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
    }
}
'''

HAPTICS_SWIFT = r'''import UIKit

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

COMPONENTS_SWIFT = r'''import SwiftUI

/// A compact metric tile: a big mono value over a quiet label.
struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Brand.mono(24, weight: .semibold))
                .foregroundStyle(accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(10, weight: .medium))
                .tracking(1.0)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A quiet section title used above grouped content.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Brand.text2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A horizontal labelled row (label left, value right).
struct InfoRow: View {
    let label: String
    let value: String
    var mono: Bool = false
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(mono ? Brand.mono(15, weight: .medium) : .body.weight(.medium))
                .foregroundStyle(Brand.text)
        }
        .font(.subheadline)
    }
}

/// A coloured pill badge.
struct Badge: View {
    let text: String
    var color: Color = Brand.text2
    var body: some View {
        Text(text)
            .font(Brand.mono(11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }
}

/// A horizontal labelled progress bar.
struct MeterBar: View {
    var fraction: Double
    var color: Color = Brand.live
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline).frame(height: height)
                Capsule().fill(color)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width, height: height)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
'''

INFO_PLIST = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDevelopmentRegion</key>
\t<string>$(DEVELOPMENT_LANGUAGE)</string>
\t<key>CFBundleDisplayName</key>
\t<string>{APP}</string>
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

PROJECT_YML = '''name: {APP}
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  {APP}:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - {APP}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.{LOWER}
        INFOPLIST_FILE: {APP}/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
'''

APPICON_CONTENTS = '''{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
'''

ACCENT_COLORSET = '''{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0x1B", "green" : "0x1D", "blue" : "0x2A" } }
    },
    {
      "idiom" : "universal",
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0xF2", "green" : "0xF3", "blue" : "0xF8" } }
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
'''

LAUNCH_COLORSET = '''{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0xED", "green" : "0xEE", "blue" : "0xF3" } }
    },
    {
      "idiom" : "universal",
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0x14", "green" : "0x15", "blue" : "0x1B" } }
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
'''

ROOT_ASSET = '{ "info" : { "author" : "xcode", "version" : 1 } }\n'


def w(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def main():
    app, slug, glyph = sys.argv[1], sys.argv[2], sys.argv[3]
    lower = app.lower()
    base = os.path.join(RUN, slug, "ios")
    appdir = os.path.join(base, app)
    assets = os.path.join(appdir, "Assets.xcassets")

    w(os.path.join(appdir, "Theme", "Brand.swift"), BRAND_SWIFT)
    w(os.path.join(appdir, "Utilities", "Haptics.swift"), HAPTICS_SWIFT)
    w(os.path.join(appdir, "Views", "Components", "Components.swift"), COMPONENTS_SWIFT)
    w(os.path.join(appdir, "Info.plist"), INFO_PLIST.replace("{APP}", app))
    w(os.path.join(base, "project.yml"), PROJECT_YML.replace("{APP}", app).replace("{LOWER}", lower))

    w(os.path.join(assets, "Contents.json"), ROOT_ASSET)
    w(os.path.join(assets, "AppIcon.appiconset", "Contents.json"), APPICON_CONTENTS)
    w(os.path.join(assets, "AccentColor.colorset", "Contents.json"), ACCENT_COLORSET)
    w(os.path.join(assets, "LaunchBackground.colorset", "Contents.json"), LAUNCH_COLORSET)
    w(os.path.join(appdir, "Preview Content", "Preview Assets.xcassets", "Contents.json"), ROOT_ASSET)

    icon_path = os.path.join(assets, "AppIcon.appiconset", "icon-1024.png")
    subprocess.run([sys.executable, os.path.join(HERE, "make_icon.py"), icon_path, glyph], check=True)
    print("scaffolded", app, "->", base)


if __name__ == "__main__":
    main()
