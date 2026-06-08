import Foundation
import SwiftData

enum SeedData {
    /// Installs the default drink catalog once. Called on first launch so the
    /// quick-add row is never empty.
    @MainActor
    static func installCatalogIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<DrinkType>())) ?? []
        guard existing.isEmpty else { return }
        for type in DrinkType.catalog { context.insert(type) }
        try? context.save()
    }

    /// Optional: a few days of realistic logs so History/Insights aren't empty.
    @MainActor
    static func seedSampleLogs(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let water = DrinkType.catalog[0]
        let coffee = DrinkType.catalog[2]
        let tea = DrinkType.catalog[3]

        for dayOffset in 0..<6 {
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let glasses = [6, 7, 5, 8, 6, 4][dayOffset]
            for g in 0..<glasses {
                let hour = 8 + g * 2
                let when = cal.date(bySettingHour: min(22, hour), minute: 15, second: 0, of: day) ?? day
                let type = (g == 1) ? coffee : (g == 4 ? tea : water)
                context.insert(DrinkLog(from: type, volumeML: type.defaultVolumeML, date: when))
            }
        }
        try? context.save()
    }
}
