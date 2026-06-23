import Foundation
import SwiftData

/// A single trip the user is packing for. Owns its pack items (cascade delete).
@Model
final class Trip {
    @Attribute(.unique) var id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var tripTypeRaw: String
    var travelerCount: Int
    /// Raw values of selected `Activity` cases.
    var activityRaws: [String]
    var createdAt: Date
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \PackItem.trip)
    var items: [PackItem]

    init(
        id: UUID = UUID(),
        name: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        tripType: TripType,
        travelerCount: Int = 1,
        activities: [Activity] = [],
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.tripTypeRaw = tripType.rawValue
        self.travelerCount = max(1, travelerCount)
        self.activityRaws = activities.map(\.rawValue)
        self.notes = notes
        self.createdAt = createdAt
        self.items = []
    }

    // MARK: Derived

    var tripType: TripType {
        TripType(rawValue: tripTypeRaw) ?? .city
    }

    var activities: [Activity] {
        activityRaws.compactMap { Activity(rawValue: $0) }
    }

    /// Number of nights, never below 1, guarded against reversed dates.
    var nights: Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: min(startDate, endDate))
        let to = cal.startOfDay(for: max(startDate, endDate))
        let days = cal.dateComponents([.day], from: from, to: to).day ?? 0
        return max(1, days)
    }

    var packedCount: Int { items.filter(\.isPacked).count }
    var totalCount: Int { items.count }

    /// Fraction packed in 0...1, division-guarded.
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(packedCount) / Double(totalCount)
    }

    var isComplete: Bool { totalCount > 0 && packedCount == totalCount }

    /// Days until departure (negative if already started/past).
    var daysUntilDeparture: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let start = cal.startOfDay(for: startDate)
        return cal.dateComponents([.day], from: today, to: start).day ?? 0
    }

    var isPast: Bool {
        Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: .now)
    }

    var dateRangeText: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let start = f.string(from: startDate)
        f.dateFormat = "MMM d, yyyy"
        let end = f.string(from: endDate)
        return "\(start) – \(end)"
    }
}
