#!/usr/bin/env python3
"""Scaffold Assets.xcassets, Preview Content, and Info.plist for a SwiftUI app.

Usage: python3 scaffold.py <app_dir> <DisplayName> <accentHex RRGGBB>
"""
import os, sys, json

app_dir, display, hexv = sys.argv[1], sys.argv[2], sys.argv[3]
r = round(int(hexv[0:2], 16) / 255, 3)
g = round(int(hexv[2:4], 16) / 255, 3)
b = round(int(hexv[4:6], 16) / 255, 3)

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

# Assets.xcassets root
write(os.path.join(app_dir, "Assets.xcassets", "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

# AppIcon (single 1024 universal placeholder slot; builds without an image file
# because the slot is unfilled -> Xcode warns, not errors)
appicon = {
    "images": [{"idiom": "universal", "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1},
}
write(os.path.join(app_dir, "Assets.xcassets", "AppIcon.appiconset", "Contents.json"),
      json.dumps(appicon, indent=2))

# AccentColor
accent = {
    "colors": [{
        "idiom": "universal",
        "color": {
            "color-space": "srgb",
            "components": {"red": f"{r}", "green": f"{g}", "blue": f"{b}", "alpha": "1.000"},
        },
    }],
    "info": {"author": "xcode", "version": 1},
}
write(os.path.join(app_dir, "Assets.xcassets", "AccentColor.colorset", "Contents.json"),
      json.dumps(accent, indent=2))

# Preview Content
write(os.path.join(app_dir, "Preview Content", "Preview Assets.xcassets", "Contents.json"),
      json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

# Info.plist
info = f'''<?xml version="1.0" encoding="UTF-8"?>
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
\t<key>UILaunchScreen</key>
\t<dict/>
\t<key>UIApplicationSceneManifest</key>
\t<dict>
\t\t<key>UIApplicationSupportsMultipleScenes</key>
\t\t<true/>
\t</dict>
\t<key>UISupportedInterfaceOrientations</key>
\t<array>
\t\t<string>UIInterfaceOrientationPortrait</string>
\t\t<string>UIInterfaceOrientationLandscapeLeft</string>
\t\t<string>UIInterfaceOrientationLandscapeRight</string>
\t</array>
\t<key>UISupportedInterfaceOrientations~ipad</key>
\t<array>
\t\t<string>UIInterfaceOrientationPortrait</string>
\t\t<string>UIInterfaceOrientationPortraitUpsideDown</string>
\t\t<string>UIInterfaceOrientationLandscapeLeft</string>
\t\t<string>UIInterfaceOrientationLandscapeRight</string>
\t</array>
{{EXTRA}}</dict>
</plist>
'''
extra = ""
if len(sys.argv) > 4:
    extra = sys.argv[4] + "\n"
write(os.path.join(app_dir, "Info.plist"), info.replace("{EXTRA}", extra))
print(f"scaffolded assets + Info.plist for {display} in {app_dir}")
