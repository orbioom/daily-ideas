#!/usr/bin/env python3
"""
Generate a valid, Xcode-15-compatible project.pbxproj for a SwiftUI app.

Usage:
    python3 genproj.py <ios_dir> <AppName> <bundle_id>

It scans <ios_dir>/<AppName> for .swift files (recursively), plus
Assets.xcassets and "Preview Content", and writes
<ios_dir>/<AppName>.xcodeproj/project.pbxproj.

Classic object graph (objectVersion 56) with explicit file references, so it
opens and builds in Xcode 15 and later. Deterministic 24-hex IDs.
"""

import os
import sys
import hashlib

def idgen(app, seed):
    h = hashlib.sha1((app + "::" + seed).encode()).hexdigest().upper()
    return h[:24]

def main():
    ios_dir, app, bundle = sys.argv[1], sys.argv[2], sys.argv[3]
    root = os.path.join(ios_dir, app)
    # discover swift files relative to root, grouped by immediate subfolder
    swift = []
    for dirpath, _, files in os.walk(root):
        # skip Preview Content (resource, not compiled)
        if "Preview Content" in dirpath:
            continue
        for f in sorted(files):
            if f.endswith(".swift"):
                rel = os.path.relpath(os.path.join(dirpath, f), root)
                swift.append(rel)
    swift.sort(key=lambda p: (p.count(os.sep), p))

    has_assets = os.path.isdir(os.path.join(root, "Assets.xcassets"))
    has_preview = os.path.isdir(os.path.join(root, "Preview Content"))

    def I(seed): return idgen(app, seed)

    # --- IDs ---
    PROJECT = I("project")
    MAIN_GROUP = I("maingroup")
    APP_GROUP = I("appgroup")
    PRODUCTS_GROUP = I("products")
    FRAMEWORKS_GROUP = I("frameworks")
    TARGET = I("target")
    PRODUCT_REF = I("productref")
    CFG_LIST_PROJ = I("cfglistproj")
    CFG_LIST_TARGET = I("cfglisttarget")
    CFG_PROJ_DEBUG = I("cfgprojdebug")
    CFG_PROJ_RELEASE = I("cfgprojrelease")
    CFG_TGT_DEBUG = I("cfgtgtdebug")
    CFG_TGT_RELEASE = I("cfgtgtrelease")
    SOURCES_PHASE = I("sourcesphase")
    RESOURCES_PHASE = I("resourcesphase")
    FRAMEWORKS_PHASE = I("frameworksphase")

    # file refs / build files for swift
    fileref = {}
    buildfile = {}
    for s in swift:
        fileref[s] = I("fref:" + s)
        buildfile[s] = I("bf:" + s)

    ASSETS_REF = I("assetsref")
    ASSETS_BF = I("assetsbf")
    PREVIEW_REF = I("previewref")
    PREVIEW_BF = I("previewbf")

    out = []
    w = out.append
    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {};")
    w("\tobjectVersion = 56;")
    w("\tobjects = {")

    # PBXBuildFile
    w("\n/* Begin PBXBuildFile section */")
    for s in swift:
        w(f"\t\t{buildfile[s]} /* {os.path.basename(s)} in Sources */ = {{isa = PBXBuildFile; fileRef = {fileref[s]} /* {os.path.basename(s)} */; }};")
    if has_assets:
        w(f"\t\t{ASSETS_BF} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ASSETS_REF} /* Assets.xcassets */; }};")
    if has_preview:
        w(f"\t\t{PREVIEW_BF} /* Preview Content in Resources */ = {{isa = PBXBuildFile; fileRef = {PREVIEW_REF} /* Preview Content */; }};")
    w("/* End PBXBuildFile section */")

    # PBXFileReference
    w("\n/* Begin PBXFileReference section */")
    w(f"\t\t{PRODUCT_REF} /* {app}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {app}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for s in swift:
        w(f"\t\t{fileref[s]} /* {os.path.basename(s)} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{s}\"; sourceTree = \"<group>\"; }};")
    if has_assets:
        w(f"\t\t{ASSETS_REF} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
    if has_preview:
        w(f"\t\t{PREVIEW_REF} /* Preview Content */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = \"Preview Content\"; sourceTree = \"<group>\"; }};")
    w("/* End PBXFileReference section */")

    # PBXFrameworksBuildPhase
    w("\n/* Begin PBXFrameworksBuildPhase section */")
    w(f"\t\t{FRAMEWORKS_PHASE} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXFrameworksBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")

    # PBXGroup
    app_children = [f"\t\t\t\t{fileref[s]} /* {os.path.basename(s)} */," for s in swift]
    if has_assets:
        app_children.append(f"\t\t\t\t{ASSETS_REF} /* Assets.xcassets */,")
    if has_preview:
        app_children.append(f"\t\t\t\t{PREVIEW_REF} /* Preview Content */,")
    w("\n/* Begin PBXGroup section */")
    w(f"\t\t{MAIN_GROUP} = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{APP_GROUP} /* {app} */,")
    w(f"\t\t\t\t{PRODUCTS_GROUP} /* Products */,")
    w(f"\t\t\t\t{FRAMEWORKS_GROUP} /* Frameworks */,")
    w("\t\t\t);")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    w(f"\t\t{APP_GROUP} /* {app} */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for line in app_children:
        w(line)
    w("\t\t\t);")
    w(f"\t\t\tpath = {app};")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    w(f"\t\t{PRODUCTS_GROUP} /* Products */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{PRODUCT_REF} /* {app}.app */,")
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    w(f"\t\t{FRAMEWORKS_GROUP} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w("\t\t\t);")
    w("\t\t\tname = Frameworks;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    w("/* End PBXGroup section */")

    # PBXNativeTarget
    w("\n/* Begin PBXNativeTarget section */")
    w(f"\t\t{TARGET} /* {app} */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {CFG_LIST_TARGET} /* Build configuration list for PBXNativeTarget \"{app}\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{SOURCES_PHASE} /* Sources */,")
    w(f"\t\t\t\t{FRAMEWORKS_PHASE} /* Frameworks */,")
    w(f"\t\t\t\t{RESOURCES_PHASE} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w("\t\t\t);")
    w(f"\t\t\tname = {app};")
    w(f"\t\t\tproductName = {app};")
    w(f"\t\t\tproductReference = {PRODUCT_REF} /* {app}.app */;")
    w("\t\t\tproductType = \"com.apple.product-type.application\";")
    w("\t\t};")
    w("/* End PBXNativeTarget section */")

    # PBXProject
    w("\n/* Begin PBXProject section */")
    w(f"\t\t{PROJECT} /* Project object */ = {{")
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    w("\t\t\t\tLastUpgradeCheck = 1500;")
    w("\t\t\t\tTargetAttributes = {")
    w(f"\t\t\t\t\t{TARGET} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w("\t\t\t\t\t};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f"\t\t\tbuildConfigurationList = {CFG_LIST_PROJ} /* Build configuration list for PBXProject \"{app}\" */;")
    w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    w("\t\t\tdevelopmentRegion = en;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (")
    w("\t\t\t\ten,")
    w("\t\t\t\tBase,")
    w("\t\t\t);")
    w(f"\t\t\tmainGroup = {MAIN_GROUP};")
    w(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP} /* Products */;")
    w("\t\t\tprojectDirPath = \"\";")
    w("\t\t\tprojectRoot = \"\";")
    w("\t\t\ttargets = (")
    w(f"\t\t\t\t{TARGET} /* {app} */,")
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")

    # PBXResourcesBuildPhase
    w("\n/* Begin PBXResourcesBuildPhase section */")
    w(f"\t\t{RESOURCES_PHASE} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    if has_preview:
        w(f"\t\t\t\t{PREVIEW_BF} /* Preview Content in Resources */,")
    if has_assets:
        w(f"\t\t\t\t{ASSETS_BF} /* Assets.xcassets in Resources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXResourcesBuildPhase section */")

    # PBXSourcesBuildPhase
    w("\n/* Begin PBXSourcesBuildPhase section */")
    w(f"\t\t{SOURCES_PHASE} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for s in swift:
        w(f"\t\t\t\t{buildfile[s]} /* {os.path.basename(s)} in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")

    # XCBuildConfiguration
    def proj_common(name):
        base = [
            "ALWAYS_SEARCH_USER_PATHS = NO;",
            "CLANG_ANALYZER_NONNULL = YES;",
            "CLANG_ENABLE_MODULES = YES;",
            "CLANG_ENABLE_OBJC_ARC = YES;",
            "COPY_PHASE_STRIP = NO;",
            "ENABLE_STRICT_OBJC_MSGSEND = YES;",
            "GCC_C_LANGUAGE_STANDARD = gnu17;",
            "GCC_NO_COMMON_BLOCKS = YES;",
            "IPHONEOS_DEPLOYMENT_TARGET = 17.0;",
            "MTL_ENABLE_DEBUG_INFO = NO;",
            "SDKROOT = iphoneos;",
            "SWIFT_VERSION = 5.0;",
        ]
        return base

    def target_common():
        return [
            "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;",
            "CODE_SIGN_STYLE = Automatic;",
            "CURRENT_PROJECT_VERSION = 1;",
            f"DEVELOPMENT_ASSET_PATHS = \"\\\"{app}/Preview Content\\\"\";" if has_preview else "",
            "ENABLE_PREVIEWS = YES;",
            "GENERATE_INFOPLIST_FILE = NO;",
            f"INFOPLIST_FILE = {app}/Info.plist;",
            "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;",
            "\"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=*]\" = YES;",
            "LD_RUNPATH_SEARCH_PATHS = (",
            "\t\"$(inherited)\",",
            "\t\"@executable_path/Frameworks\",",
            ");",
            "MARKETING_VERSION = 1.0;",
            f"PRODUCT_BUNDLE_IDENTIFIER = {bundle};",
            "PRODUCT_NAME = \"$(TARGET_NAME)\";",
            "SWIFT_EMIT_LOC_STRINGS = YES;",
            "TARGETED_DEVICE_FAMILY = \"1,2\";",
        ]

    w("\n/* Begin XCBuildConfiguration section */")
    # project debug
    w(f"\t\t{CFG_PROJ_DEBUG} /* Debug */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    for line in proj_common("Debug"):
        w(f"\t\t\t\t{line}")
    w("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    w("\t\t\t\tENABLE_TESTABILITY = YES;")
    w("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
    w("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    w("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (\n\t\t\t\t\t\"DEBUG=1\",\n\t\t\t\t\t\"$(inherited)\",\n\t\t\t\t);")
    w("\t\t\t\tMTL_FAST_MATH = YES;")
    w("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    w("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\";")
    w("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    w("\t\t\t};")
    w("\t\t\tname = Debug;")
    w("\t\t};")
    # project release
    w(f"\t\t{CFG_PROJ_RELEASE} /* Release */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    for line in proj_common("Release"):
        w(f"\t\t\t\t{line}")
    w("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
    w("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
    w("\t\t\t\tMTL_FAST_MATH = YES;")
    w("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
    w("\t\t\t};")
    w("\t\t\tname = Release;")
    w("\t\t};")
    # target debug
    w(f"\t\t{CFG_TGT_DEBUG} /* Debug */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    for line in target_common():
        if line:
            w(f"\t\t\t\t{line}")
    w("\t\t\t};")
    w("\t\t\tname = Debug;")
    w("\t\t};")
    # target release
    w(f"\t\t{CFG_TGT_RELEASE} /* Release */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    for line in target_common():
        if line:
            w(f"\t\t\t\t{line}")
    w("\t\t\t};")
    w("\t\t\tname = Release;")
    w("\t\t};")
    w("/* End XCBuildConfiguration section */")

    # XCConfigurationList
    w("\n/* Begin XCConfigurationList section */")
    w(f"\t\t{CFG_LIST_PROJ} /* Build configuration list for PBXProject \"{app}\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{CFG_PROJ_DEBUG} /* Debug */,")
    w(f"\t\t\t\t{CFG_PROJ_RELEASE} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w(f"\t\t{CFG_LIST_TARGET} /* Build configuration list for PBXNativeTarget \"{app}\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{CFG_TGT_DEBUG} /* Debug */,")
    w(f"\t\t\t\t{CFG_TGT_RELEASE} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w("/* End XCConfigurationList section */")

    w("\t};")
    w(f"\trootObject = {PROJECT} /* Project object */;")
    w("}")

    proj_dir = os.path.join(ios_dir, app + ".xcodeproj")
    os.makedirs(proj_dir, exist_ok=True)
    with open(os.path.join(proj_dir, "project.pbxproj"), "w") as f:
        f.write("\n".join(out) + "\n")
    print(f"wrote {proj_dir}/project.pbxproj  ({len(swift)} swift files, "
          f"assets={has_assets}, preview={has_preview})")

if __name__ == "__main__":
    main()
