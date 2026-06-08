import Foundation
import SwiftData

enum SampleData {
    /// ~60 days of noisy daily weigh-ins trending gently downward, so the EMA
    /// trend line and projection have something honest to chew on.
    static func load(into context: ModelContext) {
        let cal = Calendar.current
        var weight = 82.0
        for offset in stride(from: 60, through: 0, by: -1) {
            // Skip ~25% of days to mimic real, gappy logging.
            if offset % 4 == 0 { weight -= 0.06; continue }
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            // Gentle downward drift plus daily noise (water, food, time of day).
            weight -= 0.07
            let noise = sin(Double(offset) * 1.7) * 0.6 + (Double((offset * 31) % 7) - 3) * 0.18
            let kg = (weight + noise).rounded(toPlaces: 1)
            let date = cal.date(bySettingHour: 7, minute: 30, second: 0, of: day) ?? day
            context.insert(WeightEntry(date: date, kilograms: kg))
        }
        try? context.save()
    }
}
