import Foundation

struct ReadingSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var page: Int
}

struct Book: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var author: String
    var totalPages: Int
    var sessions: [ReadingSession]   // chronological, last = latest progress
    var addedAt: Date = Date()

    var currentPage: Int { sessions.last?.page ?? 0 }

    var progress: Double {
        totalPages > 0 ? min(1, Double(currentPage) / Double(totalPages)) : 0
    }

    var isFinished: Bool { totalPages > 0 && currentPage >= totalPages }

    /// Reading speed in pages/day from the first to the most recent session.
    var pace: Double? {
        guard sessions.count >= 2,
              let first = sessions.first, let last = sessions.last else { return nil }
        let days = max(0.5, last.date.timeIntervalSince(first.date) / 86400.0)
        let pages = Double(last.page - first.page)
        return pages > 0 ? pages / days : nil
    }

    /// Projected finish date, assuming the current pace holds.
    var projectedFinish: Date? {
        guard let pace, pace > 0, !isFinished else { return nil }
        let remaining = Double(totalPages - currentPage)
        return Date().addingTimeInterval(remaining / pace * 86400.0)
    }

    var pagesLeft: Int { max(0, totalPages - currentPage) }
}
