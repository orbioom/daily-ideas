import SwiftUI

/// Sort options for the collection grid.
enum CollectionSort: String, CaseIterable, Identifiable {
    case artist = "Artist"
    case title = "Title"
    case added = "Recently Added"
    case value = "Value"
    case mostSpun = "Most Spun"
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .artist: return "person"
        case .title: return "textformat"
        case .added: return "clock"
        case .value: return "dollarsign.circle"
        case .mostSpun: return "flame"
        }
    }
}

/// How condition grades are displayed.
enum GradeDisplay: String, CaseIterable, Identifiable {
    case full = "Full"
    case abbreviated = "Abbreviated"
    var id: String { rawValue }

    var label: String {
        switch self {
        case .full: return "Full names (Near Mint)"
        case .abbreviated: return "Abbreviations (NM)"
        }
    }
}

/// Persisted user preferences that actually change behavior.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("currencySymbol") var currencySymbol: String = "$"
    @AppStorage("defaultSortRaw") var defaultSortRaw: String = CollectionSort.artist.rawValue
    @AppStorage("gradeDisplayRaw") var gradeDisplayRaw: String = GradeDisplay.abbreviated.rawValue
    @AppStorage("hideValues") var hideValues: Bool = false
    @AppStorage("preferUnplayed") var preferUnplayed: Bool = true

    var defaultSort: CollectionSort {
        get { CollectionSort(rawValue: defaultSortRaw) ?? .artist }
        set { defaultSortRaw = newValue.rawValue }
    }

    var gradeDisplay: GradeDisplay {
        get { GradeDisplay(rawValue: gradeDisplayRaw) ?? .abbreviated }
        set { gradeDisplayRaw = newValue.rawValue }
    }

    /// Format a money amount with the chosen currency symbol.
    func formatMoney(_ value: Double) -> String {
        let symbol = currencySymbol.isEmpty ? "$" : currencySymbol
        return symbol + String(format: "%.2f", max(0, value))
    }

    /// Render a grade per the chosen display style.
    func gradeText(_ grade: Grade) -> String {
        switch gradeDisplay {
        case .full: return grade.display
        case .abbreviated: return grade.abbreviation
        }
    }
}
