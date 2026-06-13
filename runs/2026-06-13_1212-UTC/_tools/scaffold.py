#!/usr/bin/env python3
"""Scaffold the non-Swift boilerplate for one app in this run.

Creates: ios/project.yml, ios/<App>/Info.plist, Assets.xcassets (AppIcon with a
real 1024 PNG, AccentColor, LaunchBackground, root Contents), and Preview
Assets. Swift sources are written separately by hand.

Usage:
  python3 scaffold.py <slot-folder> <App> <slug> <motif> <bgTop> <bgBot> \
      <accentHex> <accentR> <accentG> <accentB>
"""
import os, sys, json, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))


def w(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def colorset(r, g, b):
    return {
        "colors": [{
            "color": {"color-space": "srgb", "components": {
                "red": f"0x{r:02X}", "green": f"0x{g:02X}",
                "blue": f"0x{b:02X}", "alpha": "1.000"}},
            "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1}}


def main():
    (slot, app, slug, motif, bg_top, bg_bot, accent_hex,
     ar, ag, ab) = sys.argv[1:11]
    ar, ag, ab = int(ar), int(ag), int(ab)
    root = os.path.join(HERE, "..", slot, "ios")
    appdir = os.path.join(root, app)

    # project.yml
    w(os.path.join(root, "project.yml"), f"""name: {app}
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
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.{slug}
        INFOPLIST_FILE: {app}/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        DEVELOPMENT_ASSET_PATHS: "\\"{app}/Preview Content\\""
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
""")

    # Info.plist
    w(os.path.join(appdir, "Info.plist"), f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDevelopmentRegion</key>
\t<string>en</string>
\t<key>CFBundleDisplayName</key>
\t<string>{app}</string>
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
\t\t<false/>
\t</dict>
\t<key>UILaunchScreen</key>
\t<dict>
\t\t<key>UIColorName</key>
\t\t<string>LaunchBackground</string>
\t</dict>
\t<key>UIRequiredDeviceCapabilities</key>
\t<array>
\t\t<string>arm64</string>
\t</array>
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

    # Asset catalog
    assets = os.path.join(appdir, "Assets.xcassets")
    w(os.path.join(assets, "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))
    w(os.path.join(assets, "AppIcon.appiconset", "Contents.json"),
      json.dumps({"images": [{"filename": "icon-1024.png", "idiom": "universal",
                              "platform": "ios", "size": "1024x1024"}],
                  "info": {"author": "xcode", "version": 1}}, indent=2))
    w(os.path.join(assets, "AccentColor.colorset", "Contents.json"),
      json.dumps(colorset(ar, ag, ab), indent=2))
    # LaunchBackground = bg top color
    lr, lg, lb = (int(bg_top[0:2], 16), int(bg_top[2:4], 16), int(bg_top[4:6], 16))
    w(os.path.join(assets, "LaunchBackground.colorset", "Contents.json"),
      json.dumps(colorset(lr, lg, lb), indent=2))
    # Preview assets
    w(os.path.join(appdir, "Preview Content", "Preview Assets.xcassets", "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

    # Icon PNG
    icon_path = os.path.join(assets, "AppIcon.appiconset", "icon-1024.png")
    subprocess.run([sys.executable, os.path.join(HERE, "make_icon.py"),
                    icon_path, motif, bg_top, bg_bot, accent_hex], check=True)
    print("scaffolded", app)


if __name__ == "__main__":
    main()
