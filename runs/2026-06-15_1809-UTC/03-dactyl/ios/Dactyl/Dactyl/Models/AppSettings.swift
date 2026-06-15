import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
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
}

/// Test durations offered on the Test screen.
enum TestDuration: Int, CaseIterable, Identifiable {
    case fifteen = 15
    case thirty = 30
    case sixty = 60

    var id: Int { rawValue }
    var label: String { "\(rawValue)s" }
    var isFree: Bool { self == .thirty }
}

/// App-wide persisted preferences.
@MainActor
final class AppSettings: ObservableObject {
    /// Light haptic tap feedback while typing (sparse — only on errors) and on completion.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue
    /// Play a subtle key-click sound on each keystroke.
    @AppStorage("keySoundEnabled") var keySoundEnabled: Bool = false
    /// Show the on-screen next-key + finger guide strip during sessions.
    @AppStorage("showFingerGuide") var showFingerGuide: Bool = true
    /// Require fixing mistakes (backspace) before advancing in a session.
    @AppStorage("strictMode") var strictMode: Bool = false
    /// Default duration pre-selected on the Test screen.
    @AppStorage("defaultTestDuration") var defaultTestDurationRaw: Int = TestDuration.thirty.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultTestDuration: TestDuration {
        get { TestDuration(rawValue: defaultTestDurationRaw) ?? .thirty }
        set { defaultTestDurationRaw = newValue.rawValue }
    }
}
