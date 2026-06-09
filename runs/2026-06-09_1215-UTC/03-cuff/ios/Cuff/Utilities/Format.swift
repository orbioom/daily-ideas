import Foundation

/// Small, dependency-free formatting helpers shared across views. Display of
/// metric values lives here so unit handling stays in one place.
enum Format {
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let time: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return shortDay.string(from: date)
    }

    /// A signed integer with a leading +/− for trend deltas.
    static func signed(_ value: Double, decimals: Int = 0) -> String {
        let sign = value > 0 ? "+" : (value < 0 ? "" : "±")
        return sign + String(format: "%.\(decimals)f", value)
    }

    /// A short value for a non-BP metric in the user's display units.
    static func value(_ entry: VitalEntry, weight: WeightUnit, glucose: GlucoseUnit) -> String {
        switch entry.kind {
        case .weight:
            return String(format: "%.1f %@", weight.fromKg(entry.value), weight.short)
        case .glucose:
            let v = glucose.fromMgdl(entry.value)
            return glucose == .mgdl
                ? String(format: "%.0f %@", v, glucose.short)
                : String(format: "%.1f %@", v, glucose.short)
        case .spo2:
            return String(format: "%.0f%%", entry.value)
        case .pulse:
            return String(format: "%.0f bpm", entry.value)
        case .bloodPressure:
            return "\(entry.systolic)/\(entry.diastolic)"
        }
    }

    /// Average for a non-BP metric in display units, or a dash when empty.
    static func averageValue(_ avg: Double?, kind: VitalKind,
                             weight: WeightUnit, glucose: GlucoseUnit) -> String {
        guard let avg else { return "—" }
        switch kind {
        case .weight:  return String(format: "%.1f %@", weight.fromKg(avg), weight.short)
        case .glucose:
            let v = glucose.fromMgdl(avg)
            return glucose == .mgdl
                ? String(format: "%.0f %@", v, glucose.short)
                : String(format: "%.1f %@", v, glucose.short)
        case .spo2:   return String(format: "%.0f%%", avg)
        case .pulse:  return String(format: "%.0f bpm", avg)
        case .bloodPressure: return String(format: "%.0f", avg)
        }
    }
}
