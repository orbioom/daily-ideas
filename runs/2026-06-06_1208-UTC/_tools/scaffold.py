#!/usr/bin/env python3
"""Scaffold the non-Swift boilerplate for an Orbioom iOS app.

Usage:
    python3 scaffold.py <run_dir> <slug> <App> <display> <glyph> <accentR,G,B>

Creates 0X-<slug>/ios/<App>/ with Info.plist, Assets.xcassets (real icon,
AccentColor, LaunchBackground, color sets), Preview Content, and project.yml.
Swift sources are written separately.
"""
import json
import os
import subprocess
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))


def w(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def colorset(name, light, dark):
    r, g, b = [int(c) for c in light]
    dr, dg, db = [int(c) for c in dark]
    return {
        "colors": [
            {"idiom": "universal", "color": {"color-space": "srgb", "components": {
                "alpha": "1.000", "red": f"0x{r:02X}", "green": f"0x{g:02X}", "blue": f"0x{b:02X}"}}},
            {"idiom": "universal", "appearances": [{"appearance": "luminosity", "value": "dark"}],
             "color": {"color-space": "srgb", "components": {
                 "alpha": "1.000", "red": f"0x{dr:02X}", "green": f"0x{dg:02X}", "blue": f"0x{db:02X}"}}},
        ],
        "info": {"author": "xcode", "version": 1},
    }


def main():
    run_dir, slug, app, display, glyph, accent = sys.argv[1:7]
    accent_rgb = [int(v) for v in accent.split(",")]
    folder = os.path.join(run_dir, slug)
    src = os.path.join(folder, "ios", app)
    assets = os.path.join(src, "Assets.xcassets")

    # project.yml
    lower = app.lower()
    w(os.path.join(folder, "ios", "project.yml"), f"""name: {app}
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  {app}:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - {app}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.{lower}
        INFOPLIST_FILE: {app}/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
""")

    # Info.plist
    w(os.path.join(src, "Info.plist"), f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDevelopmentRegion</key>
\t<string>$(DEVELOPMENT_LANGUAGE)</string>
\t<key>CFBundleDisplayName</key>
\t<string>{display}</string>
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
""")

    # Assets top
    w(os.path.join(assets, "Contents.json"), json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))
    # AppIcon
    w(os.path.join(assets, "AppIcon.appiconset", "Contents.json"), json.dumps({
        "images": [{"filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2))
    # AccentColor — ink in light, near-white in dark (matches brand text ink tint)
    w(os.path.join(assets, "AccentColor.colorset", "Contents.json"),
      json.dumps(colorset("AccentColor", (0x1B, 0x1D, 0x2A), (0xF2, 0xF3, 0xF8)), indent=2))
    # LaunchBackground — mist light / deep ink dark
    w(os.path.join(assets, "LaunchBackground.colorset", "Contents.json"),
      json.dumps(colorset("LaunchBackground", (0xED, 0xEE, 0xF3), (0x14, 0x15, 0x1B)), indent=2))
    # Preview Content
    w(os.path.join(src, "Preview Content", "Preview Assets.xcassets", "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

    # Icon PNG
    icon_path = os.path.join(assets, "AppIcon.appiconset", "icon-1024.png")
    subprocess.run([sys.executable, os.path.join(TOOLS, "make_icon.py"), icon_path, glyph,
                    f"{accent_rgb[0]},{accent_rgb[1]},{accent_rgb[2]}"], check=True)
    print("scaffolded", folder)


if __name__ == "__main__":
    main()
