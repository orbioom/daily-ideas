import SwiftUI

/// Centralised @AppStorage key names so the same string is never duplicated.
enum PrefKey {
    static let hasOnboarded     = "reserve.hasOnboarded"
    static let haptics          = "reserve.haptics"
    static let appearance       = "reserve.appearance"
    static let defaultChemistry = "reserve.defaultChemistry"
    static let defaultSunHours  = "reserve.defaultSunHours"
}

/// Appearance preference persisted as a raw string.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
