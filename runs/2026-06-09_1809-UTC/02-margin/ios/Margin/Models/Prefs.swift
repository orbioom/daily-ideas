import Foundation

/// How reading progress is displayed and entered throughout the app. Persisted
/// via @AppStorage("margin.progressUnit").
enum ProgressUnit: String, CaseIterable, Identifiable, Codable {
    case pages, percent

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pages: return "Pages"
        case .percent: return "Percent"
        }
    }
}

/// How the Library sorts its books. Persisted via @AppStorage("margin.sort").
enum LibrarySort: String, CaseIterable, Identifiable, Codable {
    case recent, title, rating

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent: return "Recent"
        case .title: return "Title"
        case .rating: return "Rating"
        }
    }
}
