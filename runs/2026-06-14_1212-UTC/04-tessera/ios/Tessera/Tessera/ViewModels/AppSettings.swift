import SwiftUI

/// How the codes list is ordered.
enum AccountSort: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case issuer = "Issuer"
    case recent = "Recent"
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .manual: return "line.3.horizontal"
        case .issuer: return "textformat.abc"
        case .recent: return "clock"
        }
    }
}

/// App appearance preference.
enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.stars"
        }
    }
}

/// Persisted user preferences that actually change behaviour.
@MainActor
final class AppSettings: ObservableObject {
    /// Gate the whole app behind Face ID / Touch ID on launch and on resume.
    @AppStorage("requireBiometrics") var requireBiometrics: Bool = false
    /// Blur codes until the row is tapped (shoulder-surfing protection).
    @AppStorage("hideCodes") var hideCodes: Bool = false
    /// Haptic feedback on copy / actions.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Default list sort.
    @AppStorage("accountSortRaw") var accountSortRaw: String = AccountSort.manual.rawValue
    /// Appearance.
    @AppStorage("themeModeRaw") var themeModeRaw: String = ThemeMode.system.rawValue

    var accountSort: AccountSort {
        get { AccountSort(rawValue: accountSortRaw) ?? .manual }
        set { accountSortRaw = newValue.rawValue }
    }

    var themeMode: ThemeMode {
        get { ThemeMode(rawValue: themeModeRaw) ?? .system }
        set { themeModeRaw = newValue.rawValue }
    }
}
