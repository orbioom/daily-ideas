import SwiftUI

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Which kind the Library opens to on launch.
    @AppStorage("defaultKindRaw") var defaultKindRaw: String = KindFilter.all.rawValue
    /// Default sort for the Library grid.
    @AppStorage("defaultSortRaw") var defaultSortRaw: String = LibrarySort.recent.rawValue
    /// Show estimated time-spent figures in Stats / detail.
    @AppStorage("showTimeSpent") var showTimeSpent: Bool = true
    /// Spoiler-safe: hide numeric scores in lists.
    @AppStorage("hideScores") var hideScores: Bool = false
    /// How vivid gradient covers render.
    @AppStorage("accentIntensityRaw") var accentIntensityRaw: String = AccentIntensity.standard.rawValue

    var defaultKind: KindFilter {
        get { KindFilter(rawValue: defaultKindRaw) ?? .all }
        set { defaultKindRaw = newValue.rawValue }
    }

    var defaultSort: LibrarySort {
        get { LibrarySort(rawValue: defaultSortRaw) ?? .recent }
        set { defaultSortRaw = newValue.rawValue }
    }

    var accentIntensity: AccentIntensity {
        get { AccentIntensity(rawValue: accentIntensityRaw) ?? .standard }
        set { accentIntensityRaw = newValue.rawValue }
    }

    /// A 0–10 score rendered for display ("8" or "—" when unrated / hidden).
    func scoreLabel(_ score: Int) -> String {
        if hideScores { return "•" }
        let clamped = min(max(score, 0), 10)
        return clamped == 0 ? "—" : "\(clamped)"
    }

    /// Human-readable estimated minutes, e.g. "1,240 min" → "20h 40m".
    func formatMinutes(_ minutes: Int) -> String {
        let m = max(0, minutes)
        if m < 60 { return "\(m)m" }
        let hours = m / 60
        let rem = m % 60
        if hours < 100 {
            return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
        }
        let days = hours / 24
        let remH = hours % 24
        return "\(days)d \(remH)h"
    }
}
