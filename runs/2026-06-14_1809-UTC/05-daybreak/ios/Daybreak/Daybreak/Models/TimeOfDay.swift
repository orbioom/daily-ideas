import SwiftUI

/// When a routine is meant to run. Stored as rawValue on `Routine`.
enum TimeOfDay: String, CaseIterable, Identifiable, Codable {
    case morning
    case evening
    case anytime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .anytime: return "Anytime"
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .evening: return "moon.stars.fill"
        case .anytime: return "clock.fill"
        }
    }

    /// Decorative header gradient per time of day.
    var gradient: LinearGradient {
        switch self {
        case .morning:
            return LinearGradient(colors: [Color.dyn(0xFCE3C4, 0x2C2546), Color.dyn(0xF4B968, 0x3E3060)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .evening:
            return LinearGradient(colors: [Color.dyn(0xE7C7E8, 0x241F3C), Color.dyn(0xB98AD6, 0x382A56)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .anytime:
            return LinearGradient(colors: [Color.dyn(0xF6E6C8, 0x262636), Color.dyn(0xE8C083, 0x35354C)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    /// Heuristic: which time-of-day the current hour belongs to.
    static func current(date: Date = Date(), calendar: Calendar = .current) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        if hour < 12 { return .morning }
        if hour >= 18 { return .evening }
        return .anytime
    }
}
