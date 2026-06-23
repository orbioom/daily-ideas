import Foundation

enum WarrantyEngine {
    /// Classify an appliance's warranty status, treating anything within
    /// `soonDays` as "expiring soon".
    static func status(for appliance: Appliance,
                       today: Date = .now,
                       soonDays: Int = 60,
                       calendar: Calendar = .current) -> WarrantyStatus {
        guard let expiry = appliance.warrantyExpiry else { return .unknown }
        let days = ScheduleEngine.daysUntil(expiry, from: today, calendar: calendar)
        if days < 0 { return .expired }
        if days <= max(1, soonDays) { return .expiringSoon(daysLeft: days) }
        return .active(daysLeft: days)
    }
}
