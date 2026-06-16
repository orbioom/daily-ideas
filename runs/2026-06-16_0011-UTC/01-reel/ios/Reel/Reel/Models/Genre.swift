import Foundation

/// The canonical set of genres a Title can be tagged with. Genres are stored on `Title`
/// as an array of raw names (`genresRaw`) so the model stays simple and SwiftData-stable.
enum Genre: String, CaseIterable, Identifiable {
    case action = "Action"
    case adventure = "Adventure"
    case animation = "Animation"
    case comedy = "Comedy"
    case crime = "Crime"
    case documentary = "Documentary"
    case drama = "Drama"
    case fantasy = "Fantasy"
    case horror = "Horror"
    case mystery = "Mystery"
    case romance = "Romance"
    case sciFi = "Sci-Fi"
    case thriller = "Thriller"
    case war = "War"
    case western = "Western"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// Tolerant lookup so seed/import strings resolve to a known genre when possible.
    static func from(_ name: String) -> Genre? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return allCases.first { $0.rawValue.compare(trimmed, options: .caseInsensitive) == .orderedSame }
    }
}
