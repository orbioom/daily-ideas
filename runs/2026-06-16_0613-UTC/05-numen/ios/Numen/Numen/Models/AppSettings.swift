import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}

/// The numerology letter→number system. User-selectable in Settings.
enum NumerologySystem: String, CaseIterable, Identifiable {
    case pythagorean = "Pythagorean"
    case chaldean = "Chaldean"
    var id: String { rawValue }
    var blurb: String {
        switch self {
        case .pythagorean:
            return "Western standard. Letters map to 1–9 in alphabetical order."
        case .chaldean:
            return "Ancient Babylonian. Letters map to 1–8 by sound vibration; 9 is sacred."
        }
    }
}

@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("numerologySystem") var systemRaw = NumerologySystem.pythagorean.rawValue
    /// When true, master numbers 11/22/33 are reduced fully to a single digit.
    @AppStorage("reduceMasterNumbers") var reduceMasterNumbers = false
    /// The currently selected profile id (UUID string). Empty means none chosen yet.
    @AppStorage("selectedProfileID") var selectedProfileID = ""

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var system: NumerologySystem {
        get { NumerologySystem(rawValue: systemRaw) ?? .pythagorean }
        set { systemRaw = newValue.rawValue }
    }

    /// A single options bundle the engine consumes, derived from current settings.
    var engineConfig: NumerologyConfig {
        NumerologyConfig(system: system, preserveMasterNumbers: !reduceMasterNumbers)
    }
}
