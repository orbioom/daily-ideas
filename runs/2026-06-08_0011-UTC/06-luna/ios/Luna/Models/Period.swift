import Foundation
import SwiftData

/// A recorded menstrual period. `endDate` is nil while it's ongoing.
@Model
final class Period {
    var id: UUID
    var startDate: Date
    var endDate: Date?

    init(id: UUID = UUID(), startDate: Date, endDate: Date? = nil) {
        self.id = id
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = endDate.map { Calendar.current.startOfDay(for: $0) }
    }

    var isOngoing: Bool { endDate == nil }

    /// Length in days (inclusive). Ongoing periods count up to today.
    var lengthDays: Int {
        let end = endDate ?? Calendar.current.startOfDay(for: .now)
        let days = Calendar.current.dateComponents([.day], from: startDate, to: end).day ?? 0
        return max(1, days + 1)
    }

    func contains(_ date: Date) -> Bool {
        let d = Calendar.current.startOfDay(for: date)
        let end = endDate ?? Calendar.current.startOfDay(for: .now)
        return d >= startDate && d <= end
    }
}
