import Foundation
import SwiftData

/// Seeds two jobs and ~6 weeks of realistic shifts so the overview, the shift
/// list and every chart are alive immediately.
enum SeedData {
    @MainActor
    static func installIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Job>())) ?? 0
        guard count == 0 else { return }
        let cal = Calendar.current

        let restaurant = Job(name: "The Oyster Bar", role: .server, hourlyWage: 6.5)
        let cafe = Job(name: "Bluebird Café", role: .barista, hourlyWage: 15)
        context.insert(restaurant)
        context.insert(cafe)

        var seed: UInt64 = 0x5EED
        func rnd() -> Double { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return Double(seed % 10_000) / 10_000 }

        for offset in 0..<42 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let wd = cal.component(.weekday, from: day)
            let isWeekend = (wd == 6 || wd == 7)   // Fri/Sat busier

            // Restaurant: works ~Wed–Sun.
            if wd >= 4 || wd == 1 {
                let hours = 5 + rnd() * 4
                let sales = (isWeekend ? 900 : 500) + rnd() * 500
                let tips = sales * (0.16 + rnd() * 0.06)
                let cash = tips * (0.35 + rnd() * 0.2)
                let sh = Shift(date: day, hoursWorked: round(hours * 2) / 2,
                               cashTips: round(cash), cardTips: round(tips - cash),
                               tipOut: round(tips * 0.12), sales: round(sales))
                sh.job = restaurant; restaurant.shifts.append(sh); context.insert(sh)
            }
            // Café: works ~Mon–Fri mornings.
            if wd >= 2 && wd <= 6 {
                let hours = 4 + rnd() * 3
                let tips = 18 + rnd() * 40
                let sh = Shift(date: day, hoursWorked: round(hours * 2) / 2,
                               cashTips: round(tips * 0.4), cardTips: round(tips * 0.6),
                               tipOut: 0, sales: 0)
                sh.job = cafe; cafe.shifts.append(sh); context.insert(sh)
            }
        }
        try? context.save()
    }
}
