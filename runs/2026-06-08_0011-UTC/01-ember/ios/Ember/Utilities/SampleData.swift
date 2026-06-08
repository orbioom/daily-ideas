import Foundation
import SwiftData

/// Seeds a realistic history the first time the user opts into sample data
/// (offered on the empty History screen), so charts and insights have life.
enum SampleData {
    static func loadFasts(into context: ModelContext) {
        let cal = Calendar.current
        let plans: [(String, Double)] = [("16:8", 16), ("18:6", 18), ("16:8", 16), ("14:10", 14), ("20:4", 20)]
        for offset in 1...18 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            // Skip a couple of days to make streaks realistic.
            if offset == 5 || offset == 11 { continue }
            let plan = plans[offset % plans.count]
            let startHour = 19 + (offset % 3) // evening start
            guard let start = cal.date(bySettingHour: startHour, minute: 0, second: 0, of: cal.date(byAdding: .day, value: -1, to: day) ?? day) else { continue }
            let achieved = plan.1 + Double((offset * 7) % 5) - 1.5 // some over, some under
            let end = start.addingTimeInterval(achieved * 3600)
            let fast = Fast(start: start, end: end, goalHours: plan.1,
                            planName: plan.0,
                            feeling: 3 + (offset % 3),
                            note: offset % 4 == 0 ? "Felt sharp by morning." : "")
            context.insert(fast)
        }
        try? context.save()
    }
}
