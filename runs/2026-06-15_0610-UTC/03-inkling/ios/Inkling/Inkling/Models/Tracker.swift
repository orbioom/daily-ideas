import SwiftUI
import SwiftData

/// A single thing the user tracks — a symptom, a mood, a lifestyle factor, a med, or a
/// measurement. Its `scaleType` decides how values are entered and how correlations read.
@Model
final class Tracker {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var scaleTypeRaw: String
    var unit: String?
    var colorHex: String
    var symbolName: String
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date

    /// Reverse side of the LogEntry → Tracker relationship. Deleting a tracker removes its
    /// log history so we never leave orphaned entries.
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.tracker)
    var entries: [LogEntry]? = []

    init(id: UUID = UUID(),
         name: String,
         kind: TrackerKind,
         scaleType: ScaleType,
         unit: String? = nil,
         colorHex: String,
         symbolName: String,
         isActive: Bool = true,
         sortOrder: Int = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.scaleTypeRaw = scaleType.rawValue
        self.unit = unit
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var kind: TrackerKind {
        get { TrackerKind(rawValue: kindRaw) ?? .factor }
        set { kindRaw = newValue.rawValue }
    }

    var scaleType: ScaleType {
        get { ScaleType(rawValue: scaleTypeRaw) ?? .severity }
        set { scaleTypeRaw = newValue.rawValue }
    }

    var color: Color { Color(hex: UInt(colorHex, radix: 16) ?? 0x7C5CFF) }

    /// The maximum value for a severity tracker given the user's chosen scale (0...4 or 0...10).
    func severityMax(scale10: Bool) -> Double { scale10 ? 10 : 4 }

    /// A human-readable rendering of a stored value for this tracker's scale.
    func displayValue(_ value: Double, scale10: Bool) -> String {
        switch scaleType {
        case .yesNo:
            return value >= 0.5 ? "Yes" : "No"
        case .count:
            return String(Int(value.rounded()))
        case .severity:
            return "\(Int(value.rounded()))/\(Int(severityMax(scale10: scale10)))"
        case .numeric:
            let n = value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
            if let unit, !unit.isEmpty { return "\(n) \(unit)" }
            return n
        }
    }

    /// Sorted, non-optional entries (SwiftData relationships are optional arrays).
    var sortedEntries: [LogEntry] {
        (entries ?? []).sorted { $0.date < $1.date }
    }
}
