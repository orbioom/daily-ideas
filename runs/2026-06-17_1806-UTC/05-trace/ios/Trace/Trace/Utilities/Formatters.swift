import Foundation

enum Formatters {
    static let relativeDate: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    static func relative(_ date: Date) -> String {
        relativeDate.localizedString(for: date, relativeTo: .now)
    }

    /// "3 stars" / "1 star" / "no stars yet".
    static func starsPhrase(_ count: Int) -> String {
        switch count {
        case 0: return "no stars yet"
        case 1: return "1 star"
        default: return "\(count) stars"
        }
    }
}
