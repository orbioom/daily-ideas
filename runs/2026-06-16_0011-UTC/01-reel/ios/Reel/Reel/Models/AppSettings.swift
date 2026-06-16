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

/// Sort options for the Library grid. Persisted as raw string.
enum LibrarySort: String, CaseIterable, Identifiable {
    case recentlyAdded = "Recently added"
    case rating = "Rating"
    case title = "Title"
    case year = "Year"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .recentlyAdded: return "clock"
        case .rating: return "star"
        case .title: return "textformat"
        case .year: return "calendar"
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
    /// App-specific: how many titles you aim to watch this year (the Diary goal ring).
    @AppStorage("yearlyGoal") var yearlyGoal: Int = 52
    /// App-specific: default sort for the Library grid.
    @AppStorage("defaultSortRaw") var defaultSortRaw: String = LibrarySort.recentlyAdded.rawValue
    /// App-specific: render posters as generated gradients (off = flat surface cards).
    @AppStorage("showPostersAsGradient") var showPostersAsGradient: Bool = true
    /// App-specific: blur synopsis & review text until tapped (spoiler guard).
    @AppStorage("hideSpoilers") var hideSpoilers: Bool = false

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultSort: LibrarySort {
        get { LibrarySort(rawValue: defaultSortRaw) ?? .recentlyAdded }
        set { defaultSortRaw = newValue.rawValue }
    }
}
