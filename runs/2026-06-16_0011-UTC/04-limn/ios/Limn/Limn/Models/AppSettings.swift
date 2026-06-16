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

/// The default action a plain tap performs on a cell.
enum TapMode: String, CaseIterable, Identifiable {
    case fill = "Fill"
    case cross = "Cross"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .fill: return "square.fill"
        case .cross: return "xmark"
        }
    }
}

/// App-wide persisted preferences. All values survive relaunch via `@AppStorage`.
@MainActor
final class AppSettings: ObservableObject {
    /// Required: gates all haptic feedback.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Required: System / Light / Dark.
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue

    /// Assist mode: flag a fill on a solution-empty cell as a mistake immediately.
    @AppStorage("assistMode") var assistMode: Bool = true
    /// When a line's clue is fully satisfied, auto-cross the remaining cells in it.
    @AppStorage("autoCrossCompletedLines") var autoCrossCompletedLines: Bool = true
    /// The default action for a plain single tap (fill or cross).
    @AppStorage("defaultTapMode") var defaultTapModeRaw: String = TapMode.fill.rawValue
    /// Show the running mistakes counter in the Play header.
    @AppStorage("showMistakes") var showMistakes: Bool = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultTapMode: TapMode {
        get { TapMode(rawValue: defaultTapModeRaw) ?? .fill }
        set { defaultTapModeRaw = newValue.rawValue }
    }
}
