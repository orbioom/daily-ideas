import Foundation
import SwiftData
import SwiftUI

/// A recurring or one-off medication course for a pet.
@Model
final class Medication {
    var id: UUID
    var name: String
    var dosage: String
    var frequencyRaw: String
    /// Date of the next scheduled dose.
    var nextDue: Date
    /// Optional end date for time-limited courses (e.g. a 10-day antibiotic).
    var courseEnd: Date?
    var notes: String
    var isActive: Bool
    var lastGiven: Date?
    var createdAt: Date

    var pet: Pet?

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String = "",
        frequency: DoseFrequency = .daily,
        nextDue: Date = .now,
        courseEnd: Date? = nil,
        notes: String = "",
        isActive: Bool = true,
        lastGiven: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequencyRaw = frequency.rawValue
        self.nextDue = nextDue
        self.courseEnd = courseEnd
        self.notes = notes
        self.isActive = isActive
        self.lastGiven = lastGiven
        self.createdAt = createdAt
    }

    var frequency: DoseFrequency {
        get { DoseFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    /// Marks a dose as given and rolls the next-due date forward by the frequency.
    func markGiven(on date: Date = .now) {
        lastGiven = date
        let next = frequency.advance(from: max(date, nextDue))
        if let end = courseEnd, next > end {
            isActive = false
        } else {
            nextDue = next
        }
    }
}

enum DoseFrequency: String, CaseIterable, Identifiable, Codable {
    case onceDaily = "once-daily"
    case twiceDaily = "twice-daily"
    case daily
    case everyOtherDay = "every-other-day"
    case weekly
    case biweekly
    case monthly
    case asNeeded = "as-needed"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .onceDaily: return "Once daily"
        case .twiceDaily: return "Twice daily"
        case .daily: return "Daily"
        case .everyOtherDay: return "Every other day"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        case .asNeeded: return "As needed"
        }
    }

    /// Advances a date by one interval. `asNeeded` adds a day as a soft default.
    func advance(from date: Date) -> Date {
        let cal = Calendar.current
        switch self {
        case .onceDaily, .daily, .asNeeded:
            return cal.date(byAdding: .day, value: 1, to: date) ?? date
        case .twiceDaily:
            return cal.date(byAdding: .hour, value: 12, to: date) ?? date
        case .everyOtherDay:
            return cal.date(byAdding: .day, value: 2, to: date) ?? date
        case .weekly:
            return cal.date(byAdding: .day, value: 7, to: date) ?? date
        case .biweekly:
            return cal.date(byAdding: .day, value: 14, to: date) ?? date
        case .monthly:
            return cal.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}
