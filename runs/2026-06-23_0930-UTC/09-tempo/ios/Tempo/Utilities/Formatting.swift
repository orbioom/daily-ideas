import Foundation

/// Weight conversion + display helpers. Storage is always kilograms.
enum Units {
    static let kgPerLb = 0.45359237

    static func kg(fromDisplay value: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return value
        case .lb: return value * kgPerLb
        }
    }

    static func display(fromKg kg: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return kg
        case .lb: return kg / kgPerLb
        }
    }

    /// "100", "102.5", "67.5" — trims trailing zeros, max one decimal place.
    static func trimmed(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.1f", rounded)
    }

    /// Convenience: format a kg value into the user's unit with suffix.
    static func weightString(kg: Double, unit: WeightUnit, showUnit: Bool = true) -> String {
        let v = display(fromKg: kg, unit: unit)
        return showUnit ? "\(trimmed(v)) \(unit.display)" : trimmed(v)
    }
}

enum Format {
    /// "1h 12m" / "12m 04s" / "48s"
    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return "\(s)s"
    }

    /// "2:05" countdown style for the rest timer.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static func volume(_ kg: Double, unit: WeightUnit) -> String {
        let v = Units.display(fromKg: kg, unit: unit)
        if v >= 1000 {
            return String(format: "%.1fk %@", v / 1000, unit.display)
        }
        return "\(Units.trimmed(v)) \(unit.display)"
    }

    static let relativeDate: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    static func dayTitle(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    static func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
}
