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

/// How the Library grid is ordered. Persisted; changeable per-session in the toolbar.
enum LibrarySort: String, CaseIterable, Identifiable {
    case recentlyAdded = "Recently added"
    case title = "Title"
    case author = "Author"
    case rating = "Rating"
    case progress = "Progress"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .recentlyAdded: return "clock"
        case .title: return "textformat"
        case .author: return "person"
        case .rating: return "star"
        case .progress: return "chart.bar"
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
    /// App-specific: yearly reading-challenge goal (books to finish this year).
    @AppStorage("readingGoal") var readingGoal: Int = 24
    /// App-specific: personal pages-per-day target, used for pace coaching.
    @AppStorage("pagesPerDayTarget") var pagesPerDayTarget: Int = 30
    /// App-specific: default Library sort order.
    @AppStorage("defaultSort") var defaultSortRaw: String = LibrarySort.recentlyAdded.rawValue
    /// App-specific: render covers as generated gradients (off = flat tinted covers).
    @AppStorage("showCoversAsGradient") var showCoversAsGradient: Bool = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultSort: LibrarySort {
        get { LibrarySort(rawValue: defaultSortRaw) ?? .recentlyAdded }
        set { defaultSortRaw = newValue.rawValue }
    }
}
