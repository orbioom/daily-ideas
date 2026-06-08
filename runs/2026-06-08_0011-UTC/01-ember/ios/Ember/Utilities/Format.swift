import Foundation

enum Format {
    static let dayTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM, HH:mm"
        return f
    }()

    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    static func hours(_ h: Double) -> String {
        String(format: "%.1f", h)
    }

    static func relativeRange(_ start: Date, _ end: Date?) -> String {
        let s = dayTime.string(from: start)
        guard let end else { return "Started \(s)" }
        return "\(s) → \(dayTime.string(from: end))"
    }
}
