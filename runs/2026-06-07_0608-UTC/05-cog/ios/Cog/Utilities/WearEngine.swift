import Foundation

/// Distance/unit conversion and component-wear projections.
enum Units {
    static func kmTo(_ km: Double, miles: Bool) -> Double { miles ? km * 0.621371 : km }
    static func toKm(_ value: Double, miles: Bool) -> Double { miles ? value / 0.621371 : value }
    static func label(miles: Bool) -> String { miles ? "mi" : "km" }
    static func format(_ km: Double, miles: Bool, decimals: Int = 0) -> String {
        let v = kmTo(km, miles: miles)
        return String(format: "%.\(decimals)f %@", v, label(miles: miles))
    }
}

enum WearEngine {

    enum Status { case ok, soon, due
        var label: String { switch self { case .ok: return "OK"; case .soon: return "Soon"; case .due: return "Replace" } }
    }

    static func status(wear: Double, soonThreshold: Double = 0.8) -> Status {
        if wear >= 1.0 { return .due }
        if wear >= soonThreshold { return .soon }
        return .ok
    }

    /// Projected date a component reaches 100% wear, from the bike's daily usage
    /// and/or its time-based lifespan — whichever comes first.
    static func projectedReplacement(component: Component, dailyKm: Double) -> Date? {
        var candidates: [Date] = []
        if component.lifespanKm > 0, dailyKm > 0.01, component.distanceRemainingKm > 0 {
            let days = component.distanceRemainingKm / dailyKm
            if let d = Calendar.current.date(byAdding: .day, value: Int(days.rounded()), to: Date()) {
                candidates.append(d)
            }
        }
        if component.lifespanDays > 0 {
            let remaining = component.lifespanDays - component.daysUsed
            if let d = Calendar.current.date(byAdding: .day, value: remaining, to: Date()) {
                candidates.append(d)
            }
        }
        return candidates.min()
    }

    /// Total distance ridden in the trailing `days` window (km).
    static func distance(in rides: [Ride], trailingDays days: Int) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        return rides.filter { $0.date >= cutoff }.map { $0.distanceKm }.reduce(0, +)
    }

    /// Distance per ISO week for the last `weeks` weeks (oldest first), km.
    static func weeklyDistance(rides: [Ride], weeks: Int) -> [Double] {
        let cal = Calendar.current
        var buckets = Array(repeating: 0.0, count: weeks)
        let now = Date()
        for r in rides {
            let days = cal.dateComponents([.day], from: r.date, to: now).day ?? 0
            let weekIndex = days / 7
            if weekIndex >= 0 && weekIndex < weeks {
                buckets[weeks - 1 - weekIndex] += r.distanceKm
            }
        }
        return buckets
    }

    /// Standard expected component lifespans (km) for quick presets.
    static let presets: [(name: String, category: String, km: Double, days: Int)] = [
        ("Chain", "Drivetrain", 3500, 0),
        ("Cassette", "Drivetrain", 10000, 0),
        ("Chainrings", "Drivetrain", 20000, 0),
        ("Front tyre", "Tyres", 5000, 0),
        ("Rear tyre", "Tyres", 3500, 0),
        ("Brake pads (front)", "Brakes", 4000, 0),
        ("Brake pads (rear)", "Brakes", 3000, 0),
        ("Brake cable/hose", "Brakes", 0, 730),
        ("Bar tape", "Cockpit", 0, 365),
        ("Bottom bracket", "Drivetrain", 15000, 0),
        ("Cables (shift)", "Drivetrain", 0, 365),
        ("Tubeless sealant", "Tyres", 0, 120),
        ("Chain lube", "Drivetrain", 300, 0)
    ]

    static let categories = ["Drivetrain", "Tyres", "Brakes", "Cockpit", "Suspension", "Other"]
    static let bikeKinds = ["Road", "Gravel", "Mountain", "Commuter", "E-bike", "Track"]
    static let serviceActions = ["Replaced", "Serviced", "Adjusted", "Cleaned"]
}
