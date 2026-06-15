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

/// App-wide persisted preferences. All values survive relaunch via `@AppStorage`.
@MainActor
final class AppSettings: ObservableObject {
    /// Required: gates all haptic feedback.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Required: System / Light / Dark.
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue
    /// App-specific: default board size for a brand-new game (4, 5, or 6).
    @AppStorage("defaultBoardSize") var defaultBoardSize: Int = 4
    /// App-specific: show the per-size best score chip in the Play header.
    @AppStorage("showBestOverlay") var showBestOverlay: Bool = true
    /// App-specific: enable the Undo control on the board.
    @AppStorage("swipeToUndoEnabled") var swipeToUndoEnabled: Bool = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
