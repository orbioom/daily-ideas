import Foundation

enum Units: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var label: String { self == .metric ? "Kilometers" : "Miles" }
    var shortDistance: String { self == .metric ? "km" : "mi" }
}

enum Fmt {
    static let int: NumberFormatter = {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0; return f
    }()

    static func steps(_ n: Int) -> String { int.string(from: NSNumber(value: n)) ?? "\(n)" }

    static func distance(_ meters: Double, units: Units) -> String {
        if units == .metric {
            return String(format: "%.2f", meters / 1000)
        } else {
            return String(format: "%.2f", meters / 1609.344)
        }
    }

    static func calories(steps: Int, distanceMeters: Double, weightKg: Double) -> Int {
        // ~0.9 kcal per kg per km walked; fall back to a per-step estimate.
        let km = distanceMeters > 0 ? distanceMeters / 1000 : Double(steps) * 0.000_72
        return max(0, Int((km * weightKg * 0.9).rounded()))
    }

    static func dayTitle(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"; return f.string(from: date)
    }

    static func weekday(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date)
    }
}
