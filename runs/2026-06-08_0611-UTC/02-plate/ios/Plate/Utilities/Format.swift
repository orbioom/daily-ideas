import Foundation

enum Format {

    // MARK: - Calorie formatting
    static func kcal(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        return "\(rounded) kcal"
    }

    static func kcalShort(_ value: Double) -> String {
        "\(Int(value.rounded()))"
    }

    /// Returns e.g. "+120" or "-340" for over/under display
    static func kcalDelta(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        if rounded >= 0 { return "+\(rounded)" }
        return "\(rounded)"
    }

    // MARK: - Gram formatting
    static func grams(_ value: Double) -> String {
        "\(Int(value.rounded()))g"
    }

    static func gramsDecimal(_ value: Double) -> String {
        String(format: "%.1fg", value)
    }

    // MARK: - Percent
    static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    static func percentSafe(part: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return percent(part / total)
    }

    // MARK: - Date display
    static func dayHeader(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func weekdayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // MARK: - Weight/height display (metric vs. imperial)
    static func weightDisplay(_ kg: Double, imperial: Bool) -> String {
        if imperial {
            let lbs = kg * 2.20462
            return String(format: "%.0f lbs", lbs)
        }
        return String(format: "%.1f kg", kg)
    }

    static func heightDisplay(_ cm: Double, imperial: Bool) -> String {
        if imperial {
            let totalInches = cm / 2.54
            let feet = Int(totalInches) / 12
            let inches = Int(totalInches) % 12
            return "\(feet)'\(inches)\""
        }
        return String(format: "%.0f cm", cm)
    }

    // MARK: - Serving count
    static func servings(_ count: Double) -> String {
        if count == count.rounded() {
            return "\(Int(count.rounded()))"
        }
        return String(format: "%.1f", count)
    }
}
