import Foundation
import SwiftData

enum PrayerStatus: String, Codable, CaseIterable {
    case prayed
    case late

    var displayName: String {
        switch self {
        case .prayed: return "Prayed"
        case .late: return "Prayed late"
        }
    }
}

/// One logged prayer on one day. Absence of a row means "not logged".
@Model
final class PrayerLog {
    /// "yyyy-MM-dd" in the selected city's timezone — stable across travel.
    var dayKey: String
    var prayerRaw: String
    var statusRaw: String
    var loggedAt: Date

    init(dayKey: String, prayer: Prayer, status: PrayerStatus, loggedAt: Date = .now) {
        self.dayKey = dayKey
        self.prayerRaw = prayer.rawValue
        self.statusRaw = status.rawValue
        self.loggedAt = loggedAt
    }

    var prayer: Prayer? { Prayer(rawValue: prayerRaw) }
    var status: PrayerStatus { PrayerStatus(rawValue: statusRaw) ?? .prayed }
}

enum DayKey {
    static func make(for date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
