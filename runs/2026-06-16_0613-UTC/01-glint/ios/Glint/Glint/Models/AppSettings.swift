import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}

/// How the player swaps gems.
enum SwapMode: String, CaseIterable, Identifiable {
    case tap = "Tap-Tap", drag = "Drag"
    var id: String { rawValue }
    var help: String {
        self == .tap ? "Tap a gem, then tap an adjacent gem to swap."
                     : "Press and drag a gem onto an adjacent one."
    }
}

@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("swapMode") var swapModeRaw = SwapMode.tap.rawValue
    @AppStorage("reducedEffects") var reducedEffects = false
    @AppStorage("showHints") var showHints = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var swapMode: SwapMode {
        get { SwapMode(rawValue: swapModeRaw) ?? .tap }
        set { swapModeRaw = newValue.rawValue }
    }
}
