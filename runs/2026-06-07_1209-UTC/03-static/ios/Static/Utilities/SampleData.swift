import Foundation
import SwiftData

/// Seeds a starter CO₂ and O₂ table plus a few weeks of sessions showing a
/// rising personal best.
enum SampleData {
    static func seed(into context: ModelContext) {
        let co2 = ApneaTable(name: "CO₂ Tolerance", type: .co2, maxHoldSeconds: 210, rounds: 8)
        let o2 = ApneaTable(name: "O₂ Builder", type: .o2, maxHoldSeconds: 210, rounds: 8)
        context.insert(co2)
        context.insert(o2)

        let cal = Calendar.current
        let history: [(daysAgo: Int, type: TableType, planned: Int, done: Int, pb: Int)] = [
            (24, .co2, 8, 8, 150),
            (20, .o2, 8, 6, 162),
            (16, .co2, 8, 8, 168),
            (12, .o2, 8, 8, 181),
            (8, .co2, 8, 8, 190),
            (4, .o2, 8, 7, 205),
            (1, .o2, 8, 8, 214),
        ]
        for h in history {
            guard let date = cal.date(byAdding: .day, value: -h.daysAgo, to: Date()) else { continue }
            let s = ApneaSession(date: date,
                                 tableName: h.type == .co2 ? "CO₂ Tolerance" : "O₂ Builder",
                                 type: h.type, roundsPlanned: h.planned,
                                 roundsCompleted: h.done, longestHoldSeconds: h.pb)
            context.insert(s)
        }
    }
}
