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
    /// Max brand-new cards introduced per deck per day.
    @AppStorage("dailyNewLimit") var dailyNewLimit: Int = 20
    /// Max review (already-seen due) cards per deck per day.
    @AppStorage("dailyReviewLimit") var dailyReviewLimit: Int = 120
    /// Default study mode for a new session.
    @AppStorage("defaultStudyModeRaw") var defaultStudyModeRaw: String = ReviewMode.flip.rawValue
    /// Shuffle the study queue rather than strict due-order.
    @AppStorage("shuffleOrder") var shuffleOrder: Bool = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultStudyMode: ReviewMode {
        get { ReviewMode(rawValue: defaultStudyModeRaw) ?? .flip }
        set { defaultStudyModeRaw = newValue.rawValue }
    }

    /// Clamp the new-card limit to a sane stepper range.
    func boundedNewLimit() -> Int { min(max(dailyNewLimit, 0), 100) }
    /// Clamp the review limit to a sane stepper range.
    func boundedReviewLimit() -> Int { min(max(dailyReviewLimit, 10), 500) }
}
