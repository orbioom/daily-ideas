import SwiftUI

enum LibrarySort: String, CaseIterable, Identifiable {
    case recentlyAdded
    case title
    case rating
    case hoursLogged
    case lengthEstimate

    var id: String { rawValue }
    var label: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .title: return "Title (A–Z)"
        case .rating: return "Rating"
        case .hoursLogged: return "Hours Logged"
        case .lengthEstimate: return "Length"
        }
    }
}

enum HoursFormat: String, CaseIterable, Identifiable {
    case hoursMinutes   // 12h 30m
    case decimal        // 12.5h

    var id: String { rawValue }
    var label: String {
        switch self {
        case .hoursMinutes: return "Hours & minutes"
        case .decimal: return "Decimal"
        }
    }
}

enum CoverStyle: String, CaseIterable, Identifiable {
    case gradient
    case solid

    var id: String { rawValue }
    var label: String {
        switch self {
        case .gradient: return "Gradient"
        case .solid: return "Solid"
        }
    }
}

/// App-wide preferences persisted in UserDefaults. These actually change behavior.
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("defaultLibrarySort") var defaultLibrarySortRaw: String = LibrarySort.recentlyAdded.rawValue
    @AppStorage("hoursFormat") var hoursFormatRaw: String = HoursFormat.hoursMinutes.rawValue
    @AppStorage("coverStyle") var coverStyleRaw: String = CoverStyle.gradient.rawValue
    @AppStorage("yearChallengeGoal") var yearChallengeGoal: Int = 12
    @AppStorage("celebrateCompletions") var celebrateCompletions: Bool = true

    var defaultLibrarySort: LibrarySort {
        get { LibrarySort(rawValue: defaultLibrarySortRaw) ?? .recentlyAdded }
        set { defaultLibrarySortRaw = newValue.rawValue }
    }

    var hoursFormat: HoursFormat {
        get { HoursFormat(rawValue: hoursFormatRaw) ?? .hoursMinutes }
        set { hoursFormatRaw = newValue.rawValue }
    }

    var coverStyle: CoverStyle {
        get { CoverStyle(rawValue: coverStyleRaw) ?? .gradient }
        set { coverStyleRaw = newValue.rawValue }
    }

    /// Format hours respecting the user's preference.
    func formatHours(_ hours: Double) -> String {
        let h = max(0, hours)
        switch hoursFormat {
        case .decimal:
            if h == h.rounded() { return "\(Int(h))h" }
            return String(format: "%.1fh", h)
        case .hoursMinutes:
            let whole = Int(h)
            let minutes = Int((h - Double(whole)) * 60 + 0.5)
            if whole == 0 && minutes == 0 { return "0h" }
            if minutes == 0 { return "\(whole)h" }
            if whole == 0 { return "\(minutes)m" }
            return "\(whole)h \(minutes)m"
        }
    }
}
