#!/usr/bin/env python3
"""Generate a valid Xcode .xcodeproj/project.pbxproj for a SwiftUI iOS app.

Usage:
    python3 gen_pbxproj.py <APP_DIR> <AppName> <bundle.id>

<APP_DIR> is the folder that contains the .xcodeproj AND the <AppName>/ source
group (e.g. .../05-strata/ios). The script auto-discovers every *.swift file
under <APP_DIR>/<AppName>/, plus the Assets.xcassets and Preview Content
resource folders, and writes <APP_DIR>/<AppName>.xcodeproj/project.pbxproj.

The build settings mirror a known-good Xcode 15 / iOS 17 / SwiftUI 5 template.
IDs are deterministic (hash of role+path) so re-runs are stable.
"""

import os
import sys
import hashlib


def uid(*parts):
    h = hashlib.sha1("::".join(parts).encode()).hexdigest().upper()
    return h[:24]


def main():
    if len(sys.argv) != 4:
        print("usage: gen_pbxproj.py <APP_DIR> <AppName> <bundle.id>")
        sys.exit(1)
    app_dir = os.path.abspath(sys.argv[1])
    app = sys.argv[2]
    bundle = sys.argv[3]
    src_root = os.path.join(app_dir, app)
    if not os.path.isdir(src_root):
        print(f"ERROR: source dir not found: {src_root}")
        sys.exit(1)

    # Discover swift files (relative to src_root), sorted, App entry first.
    swift = []
    for root, _dirs, files in os.walk(src_root):
        for f in sorted(files):
            if f.endswith(".swift"):
                rel = os.path.relpath(os.path.join(root, f), src_root)
                swift.append(rel.replace(os.sep, "/"))
    swift.sort(key=lambda p: (0 if p == f"{app}App.swift" else 1, p))
    if f"{app}App.swift" not in swift:
        print(f"ERROR: {app}App.swift (@main) not found under {src_root}")
        sys.exit(1)

    has_assets = os.path.isdir(os.path.join(src_root, "Assets.xcassets"))
    has_preview = os.path.isdir(os.path.join(src_root, "Preview Content"))
    if not has_assets:
        print("ERROR: Assets.xcassets missing")
        sys.exit(1)

    # ---- IDs ----
    proj_id = uid("project")
    main_group = uid("mainGroup")
    app_group = uid("appGroup")
    products_group = uid("products")
    frameworks_group = uid("frameworksGroup")
    target_id = uid("target")
    product_ref = uid("productRef")
    sources_phase = uid("sourcesPhase")
    frameworks_phase = uid("frameworksPhase")
    resources_phase = uid("resourcesPhase")
    proj_cfg_list = uid("projCfgList")
    target_cfg_list = uid("targetCfgList")
    cfg_proj_debug = uid("cfgProjDebug")
    cfg_proj_release = uid("cfgProjRelease")
    cfg_tgt_debug = uid("cfgTgtDebug")
    cfg_tgt_release = uid("cfgTgtRelease")

    file_ref = {}     # rel -> id
    build_file = {}   # rel -> id
    for rel in swift:
        file_ref[rel] = uid("fref", rel)
        build_file[rel] = uid("bfile", rel)
    assets_ref = uid("fref", "Assets.xcassets")
    assets_bf = uid("bfile", "Assets.xcassets")
    preview_ref = uid("fref", "Preview Content")
    preview_bf = uid("bfile", "Preview Content")

    L = []
    a = L.append
    a("// !$*UTF8*$!")
    a("{")
    a("\tarchiveVersion = 1;")
    a("\tclasses = {};")
    a("\tobjectVersion = 56;")
    a("\tobjects = {")
    a("")

    # PBXBuildFile
    a("/* Begin PBXBuildFile section */")
    for rel in swift:
        base = os.path.basename(rel)
        a(f"\t\t{build_file[rel]} /* {base} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref[rel]} /* {base} */; }};")
    a(f"\t\t{assets_bf} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};")
    if has_preview:
        a(f"\t\t{preview_bf} /* Preview Content in Resources */ = {{isa = PBXBuildFile; fileRef = {preview_ref} /* Preview Content */; }};")
    a("/* End PBXBuildFile section */")
    a("")

    # PBXFileReference
    a("/* Begin PBXFileReference section */")
    a(f'\t\t{product_ref} /* {app}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {app}.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    for rel in swift:
        base = os.path.basename(rel)
        a(f'\t\t{file_ref[rel]} /* {base} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = "{base}"; path = "{rel}"; sourceTree = "<group>"; }};')
    a(f'\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
    if has_preview:
        a(f'\t\t{preview_ref} /* Preview Content */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Content"; sourceTree = "<group>"; }};')
    a("/* End PBXFileReference section */")
    a("")

    # PBXFrameworksBuildPhase
    a("/* Begin PBXFrameworksBuildPhase section */")
    a(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
    a("\t\t\tisa = PBXFrameworksBuildPhase;")
    a("\t\t\tbuildActionMask = 2147483647;")
    a("\t\t\tfiles = (")
    a("\t\t\t);")
    a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    a("\t\t};")
    a("/* End PBXFrameworksBuildPhase section */")
    a("")

    # PBXGroup
    a("/* Begin PBXGroup section */")
    a(f"\t\t{main_group} = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    a(f"\t\t\t\t{app_group} /* {app} */,")
    a(f"\t\t\t\t{products_group} /* Products */,")
    a(f"\t\t\t\t{frameworks_group} /* Frameworks */,")
    a("\t\t\t);")
    a('\t\t\tsourceTree = "<group>";')
    a("\t\t};")
    a(f"\t\t{app_group} /* {app} */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    for rel in swift:
        base = os.path.basename(rel)
        a(f"\t\t\t\t{file_ref[rel]} /* {base} */,")
    a(f"\t\t\t\t{assets_ref} /* Assets.xcassets */,")
    if has_preview:
        a(f"\t\t\t\t{preview_ref} /* Preview Content */,")
    a("\t\t\t);")
    a(f"\t\t\tpath = {app};")
    a('\t\t\tsourceTree = "<group>";')
    a("\t\t};")
    a(f"\t\t{products_group} /* Products */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    a(f"\t\t\t\t{product_ref} /* {app}.app */,")
    a("\t\t\t);")
    a("\t\t\tname = Products;")
    a('\t\t\tsourceTree = "<group>";')
    a("\t\t};")
    a(f"\t\t{frameworks_group} /* Frameworks */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    a("\t\t\t);")
    a("\t\t\tname = Frameworks;")
    a('\t\t\tsourceTree = "<group>";')
    a("\t\t};")
    a("/* End PBXGroup section */")
    a("")

    # PBXNativeTarget
    a("/* Begin PBXNativeTarget section */")
    a(f'\t\t{target_id} /* {app} */ = {{')
    a("\t\t\tisa = PBXNativeTarget;")
    a(f'\t\t\tbuildConfigurationList = {target_cfg_list} /* Build configuration list for PBXNativeTarget "{app}" */;')
    a("\t\t\tbuildPhases = (")
    a(f"\t\t\t\t{sources_phase} /* Sources */,")
    a(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
    a(f"\t\t\t\t{resources_phase} /* Resources */,")
    a("\t\t\t);")
    a("\t\t\tbuildRules = (")
    a("\t\t\t);")
    a("\t\t\tdependencies = (")
    a("\t\t\t);")
    a(f"\t\t\tname = {app};")
    a(f"\t\t\tproductName = {app};")
    a(f"\t\t\tproductReference = {product_ref} /* {app}.app */;")
    a('\t\t\tproductType = "com.apple.product-type.application";')
    a("\t\t};")
    a("/* End PBXNativeTarget section */")
    a("")

    # PBXProject
    a("/* Begin PBXProject section */")
    a(f"\t\t{proj_id} /* Project object */ = {{")
    a("\t\t\tisa = PBXProject;")
    a("\t\t\tattributes = {")
    a("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    a("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    a("\t\t\t\tLastUpgradeCheck = 1500;")
    a("\t\t\t\tTargetAttributes = {")
    a(f"\t\t\t\t\t{target_id} = {{")
    a("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    a("\t\t\t\t\t};")
    a("\t\t\t\t};")
    a("\t\t\t};")
    a(f'\t\t\tbuildConfigurationList = {proj_cfg_list} /* Build configuration list for PBXProject "{app}" */;')
    a('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    a("\t\t\tdevelopmentRegion = en;")
    a("\t\t\thasScannedForEncodings = 0;")
    a("\t\t\tknownRegions = (")
    a("\t\t\t\ten,")
    a("\t\t\t\tBase,")
    a("\t\t\t);")
    a(f"\t\t\tmainGroup = {main_group};")
    a(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
    a('\t\t\tprojectDirPath = "";')
    a('\t\t\tprojectRoot = "";')
    a("\t\t\ttargets = (")
    a(f"\t\t\t\t{target_id} /* {app} */,")
    a("\t\t\t);")
    a("\t\t};")
    a("/* End PBXProject section */")
    a("")

    # PBXResourcesBuildPhase
    a("/* Begin PBXResourcesBuildPhase section */")
    a(f"\t\t{resources_phase} /* Resources */ = {{")
    a("\t\t\tisa = PBXResourcesBuildPhase;")
    a("\t\t\tbuildActionMask = 2147483647;")
    a("\t\t\tfiles = (")
    if has_preview:
        a(f"\t\t\t\t{preview_bf} /* Preview Content in Resources */,")
    a(f"\t\t\t\t{assets_bf} /* Assets.xcassets in Resources */,")
    a("\t\t\t);")
    a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    a("\t\t};")
    a("/* End PBXResourcesBuildPhase section */")
    a("")

    # PBXSourcesBuildPhase
    a("/* Begin PBXSourcesBuildPhase section */")
    a(f"\t\t{sources_phase} /* Sources */ = {{")
    a("\t\t\tisa = PBXSourcesBuildPhase;")
    a("\t\t\tbuildActionMask = 2147483647;")
    a("\t\t\tfiles = (")
    for rel in swift:
        base = os.path.basename(rel)
        a(f"\t\t\t\t{build_file[rel]} /* {base} in Sources */,")
    a("\t\t\t);")
    a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    a("\t\t};")
    a("/* End PBXSourcesBuildPhase section */")
    a("")

    # XCBuildConfiguration
    preview_path = f'"{app}/Preview Content"' if has_preview else '""'
    def target_cfg(name, extra):
        a(f"\t\t{name} = {{")
        a("\t\t\tisa = XCBuildConfiguration;")
        a("\t\t\tbuildSettings = {")
        a("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
        a("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
        a("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
        a("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
        if has_preview:
            a(f'\t\t\t\tDEVELOPMENT_ASSET_PATHS = "\\"{app}/Preview Content\\"";')
        a("\t\t\t\tENABLE_PREVIEWS = YES;")
        a("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
        a(f"\t\t\t\tINFOPLIST_FILE = {app}/Info.plist;")
        a("\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;")
        a("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
        a('\t\t\t\t\t"$(inherited)",')
        a('\t\t\t\t\t"@executable_path/Frameworks",')
        a("\t\t\t\t);")
        a("\t\t\t\tMARKETING_VERSION = 1.0;")
        a(f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {bundle};")
        a('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
        a("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
        a('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
        for line in extra:
            a("\t\t\t\t" + line)
        a("\t\t\t};")
        a(f"\t\t\tname = {name.split('/')[-1].strip()};")
        a("\t\t};")

    a("/* Begin XCBuildConfiguration section */")
    # Project-level Debug
    a(f"\t\t{cfg_proj_debug} /* Debug */ = {{")
    a("\t\t\tisa = XCBuildConfiguration;")
    a("\t\t\tbuildSettings = {")
    for line in [
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
        "DEBUG_INFORMATION_FORMAT = dwarf;",
        "ENABLE_TESTABILITY = YES;",
        "GCC_DYNAMIC_NO_PIC = NO;",
        "GCC_OPTIMIZATION_LEVEL = 0;",
        'GCC_PREPROCESSOR_DEFINITIONS = (',
        '\t"DEBUG=1",',
        '\t"$(inherited)",',
        ');',
        "MTL_FAST_MATH = YES;",
        "ONLY_ACTIVE_ARCH = YES;",
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";',
        'SWIFT_OPTIMIZATION_LEVEL = "-Onone";',
    ]:
        a("\t\t\t\t" + line)
    a("\t\t\t};")
    a("\t\t\tname = Debug;")
    a("\t\t};")
    # Project-level Release
    a(f"\t\t{cfg_proj_release} /* Release */ = {{")
    a("\t\t\tisa = XCBuildConfiguration;")
    a("\t\t\tbuildSettings = {")
    for line in [
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
        'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";',
        "ENABLE_NS_ASSERTIONS = NO;",
        "MTL_FAST_MATH = YES;",
        "SWIFT_COMPILATION_MODE = wholemodule;",
    ]:
        a("\t\t\t\t" + line)
    a("\t\t\t};")
    a("\t\t\tname = Release;")
    a("\t\t};")
    target_cfg(f"{cfg_tgt_debug} /* Debug */", ["SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";"])
    target_cfg(f"{cfg_tgt_release} /* Release */", [])
    a("/* End XCBuildConfiguration section */")
    a("")

    # XCConfigurationList
    a("/* Begin XCConfigurationList section */")
    a(f'\t\t{proj_cfg_list} /* Build configuration list for PBXProject "{app}" */ = {{')
    a("\t\t\tisa = XCConfigurationList;")
    a("\t\t\tbuildConfigurations = (")
    a(f"\t\t\t\t{cfg_proj_debug} /* Debug */,")
    a(f"\t\t\t\t{cfg_proj_release} /* Release */,")
    a("\t\t\t);")
    a("\t\t\tdefaultConfigurationIsVisible = 0;")
    a("\t\t\tdefaultConfigurationName = Release;")
    a("\t\t};")
    a(f'\t\t{target_cfg_list} /* Build configuration list for PBXNativeTarget "{app}" */ = {{')
    a("\t\t\tisa = XCConfigurationList;")
    a("\t\t\tbuildConfigurations = (")
    a(f"\t\t\t\t{cfg_tgt_debug} /* Debug */,")
    a(f"\t\t\t\t{cfg_tgt_release} /* Release */,")
    a("\t\t\t);")
    a("\t\t\tdefaultConfigurationIsVisible = 0;")
    a("\t\t\tdefaultConfigurationName = Release;")
    a("\t\t};")
    a("/* End XCConfigurationList section */")
    a("\t};")
    a(f"\trootObject = {proj_id} /* Project object */;")
    a("}")

    out_dir = os.path.join(app_dir, f"{app}.xcodeproj")
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "project.pbxproj"), "w") as f:
        f.write("\n".join(L) + "\n")
    print(f"wrote {out_dir}/project.pbxproj  ({len(swift)} swift files)")


if __name__ == "__main__":
    main()
