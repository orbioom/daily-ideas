import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Supported full-mock exam lengths.
enum MockLength: Int, CaseIterable, Identifiable {
    case twenty = 20, thirty = 30, forty = 40
    var id: Int { rawValue }
    var label: String { "\(rawValue) questions" }
}

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("mockLength") var mockLengthRaw = MockLength.forty.rawValue
    @AppStorage("instantExplanations") var instantExplanations = true
    @AppStorage("showTimer") var showTimer = true
    @AppStorage("studyState") var studyState = ""

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var mockLength: MockLength {
        get { MockLength(rawValue: mockLengthRaw) ?? .forty }
        set { mockLengthRaw = newValue.rawValue }
    }
}
