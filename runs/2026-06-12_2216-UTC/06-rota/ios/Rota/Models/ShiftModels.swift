import Foundation
import SwiftData

/// A kind of shift: "Day 07:00–19:00", "Night", "Off", … with pay info.
@Model
final class ShiftType {
    var name: String
    var symbol: String          // short badge text, e.g. "D", "N", "OFF"
    var colorHex: String
    /// Minutes from midnight. If endMinutes <= startMinutes the shift wraps
    /// past midnight (e.g. 19:00 → 07:00).
    var startMinutes: Int
    var endMinutes: Int
    var unpaidBreakMinutes: Int
    var hourlyRate: Double
    var isRest: Bool            // an "Off"/rest day: no times, no pay
    var createdAt: Date

    init(
        name: String,
        symbol: String,
        colorHex: String,
        startMinutes: Int = 7 * 60,
        endMinutes: Int = 19 * 60,
        unpaidBreakMinutes: Int = 30,
        hourlyRate: Double = 0,
        isRest: Bool = false
    ) {
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.unpaidBreakMinutes = unpaidBreakMinutes
        self.hourlyRate = hourlyRate
        self.isRest = isRest
        self.createdAt = .now
    }

    /// Paid hours for one occurrence (overnight-aware, break deducted).
    var paidHours: Double {
        guard !isRest else { return 0 }
        var span = endMinutes - startMinutes
        if span <= 0 { span += 24 * 60 }
        let paid = max(0, span - unpaidBreakMinutes)
        return Double(paid) / 60.0
    }

    var earningsPerShift: Double { paidHours * hourlyRate }

    func timeRangeString(use24Hour: Bool) -> String {
        guard !isRest else { return "Rest day" }
        func fmt(_ minutes: Int) -> String {
            let h = (minutes / 60) % 24
            let m = minutes % 60
            if use24Hour {
                return String(format: "%02d:%02d", h, m)
            }
            let suffix = h >= 12 ? "PM" : "AM"
            var hour12 = h % 12
            if hour12 == 0 { hour12 = 12 }
            return m == 0 ? "\(hour12) \(suffix)" : String(format: "%d:%02d %@", hour12, m, suffix)
        }
        let wraps = endMinutes <= startMinutes
        return "\(fmt(startMinutes)) – \(fmt(endMinutes))\(wraps ? " (+1d)" : "")"
    }
}

/// The repeating pattern: an ordered cycle of shift types anchored to a date.
@Model
final class RotationPattern {
    var name: String
    var anchorDay: Date          // start of day; cycle position 0 falls here
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PatternSlot.pattern)
    var slots: [PatternSlot] = []

    init(name: String, anchorDay: Date, isActive: Bool = true) {
        self.name = name
        self.anchorDay = anchorDay
        self.isActive = isActive
        self.createdAt = .now
    }

    var sortedSlots: [PatternSlot] {
        slots.sorted { $0.orderIndex < $1.orderIndex }
    }
}

/// One position in the rotation cycle.
@Model
final class PatternSlot {
    var orderIndex: Int
    var shiftType: ShiftType?
    var pattern: RotationPattern?

    init(orderIndex: Int, shiftType: ShiftType?) {
        self.orderIndex = orderIndex
        self.shiftType = shiftType
    }
}

/// A manual override for a single day (swap, overtime, sick day…).
/// `shiftType == nil` means "forced day off".
@Model
final class ShiftOverride {
    var dayKey: String           // yyyy-MM-dd local
    var shiftType: ShiftType?
    var note: String

    init(dayKey: String, shiftType: ShiftType?, note: String = "") {
        self.dayKey = dayKey
        self.shiftType = shiftType
        self.note = note
    }
}

enum RotaDay {
    static func key(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

/// Resolves what's on for any date and aggregates hours/earnings.
enum RotaEngine {
    /// The effective shift for a day: override first, then the active pattern.
    static func shift(
        on date: Date,
        pattern: RotationPattern?,
        overrides: [ShiftOverride]
    ) -> (shiftType: ShiftType?, isOverride: Bool, note: String) {
        let key = RotaDay.key(for: date)
        if let override = overrides.first(where: { $0.dayKey == key }) {
            return (override.shiftType, true, override.note)
        }
        guard let pattern, !pattern.sortedSlots.isEmpty else { return (nil, false, "") }
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: pattern.anchorDay)
        let day = calendar.startOfDay(for: date)
        guard let days = calendar.dateComponents([.day], from: anchor, to: day).day else {
            return (nil, false, "")
        }
        let count = pattern.sortedSlots.count
        let index = ((days % count) + count) % count
        return (pattern.sortedSlots[index].shiftType, false, "")
    }

    struct PeriodSummary {
        var workDays: Int = 0
        var restDays: Int = 0
        var paidHours: Double = 0
        var earnings: Double = 0
        var hoursByType: [String: Double] = [:]    // type name → hours
        var earningsByType: [String: Double] = [:]
        var colorByType: [String: String] = [:]
    }

    static func summary(
        from start: Date,
        through end: Date,
        pattern: RotationPattern?,
        overrides: [ShiftOverride]
    ) -> PeriodSummary {
        var result = PeriodSummary()
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        var safety = 0
        while day <= last && safety < 400 {
            safety += 1
            let resolved = shift(on: day, pattern: pattern, overrides: overrides)
            if let type = resolved.shiftType, !type.isRest {
                result.workDays += 1
                result.paidHours += type.paidHours
                result.earnings += type.earningsPerShift
                result.hoursByType[type.name, default: 0] += type.paidHours
                result.earningsByType[type.name, default: 0] += type.earningsPerShift
                result.colorByType[type.name] = type.colorHex
            } else {
                result.restDays += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// Next working shift strictly after `date` (looks ahead up to 60 days).
    static func nextShift(
        after date: Date,
        pattern: RotationPattern?,
        overrides: [ShiftOverride]
    ) -> (start: Date, type: ShiftType)? {
        let calendar = Calendar.current
        for offset in 0..<60 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)) else { continue }
            let resolved = shift(on: day, pattern: pattern, overrides: overrides)
            guard let type = resolved.shiftType, !type.isRest else { continue }
            guard let start = calendar.date(byAdding: .minute, value: type.startMinutes, to: day) else { continue }
            if start > date {
                return (start, type)
            }
        }
        return nil
    }
}
