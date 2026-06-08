import Foundation
import SwiftData

enum SeedData {
    @MainActor
    static func populate(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        let acme = Client(name: "Acme Studio", colorHex: 0x3E8E7E, hourlyRate: 85)
        let northwind = Client(name: "Northwind", colorHex: 0x6E7BA6, hourlyRate: 110)
        context.insert(acme); context.insert(northwind)

        let brand = Project(name: "Brand refresh", colorHex: 0x3E8E7E, billable: true, client: acme)
        let app = Project(name: "iOS app", colorHex: 0x6E7BA6, billable: true, useCustomRate: true, customRate: 125, client: northwind)
        let admin = Project(name: "Admin & email", colorHex: 0x8B8FA3, billable: false, client: acme)
        [brand, app, admin].forEach { context.insert($0) }

        func entry(_ proj: Project, _ detail: String, dayOffset: Int, startHour: Int, minutes: Int) {
            let day = cal.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let start = cal.date(bySettingHour: startHour, minute: 0, second: 0, of: day) ?? day
            let end = start.addingTimeInterval(Double(minutes) * 60)
            context.insert(TimeEntry(detail: detail, start: start, end: end, project: proj))
        }

        entry(app, "Auth flow", dayOffset: 0, startHour: 9, minutes: 95)
        entry(brand, "Logo explorations", dayOffset: 0, startHour: 13, minutes: 130)
        entry(admin, "Inbox & invoices", dayOffset: 1, startHour: 8, minutes: 40)
        entry(app, "SwiftData models", dayOffset: 1, startHour: 10, minutes: 150)
        entry(brand, "Style tiles", dayOffset: 2, startHour: 11, minutes: 110)
        entry(app, "Charts screen", dayOffset: 3, startHour: 14, minutes: 175)
        entry(brand, "Client review", dayOffset: 4, startHour: 9, minutes: 60)
        entry(app, "Bug fixes", dayOffset: 5, startHour: 10, minutes: 90)
        entry(brand, "Deck polish", dayOffset: 6, startHour: 15, minutes: 80)

        try? context.save()
    }
}
