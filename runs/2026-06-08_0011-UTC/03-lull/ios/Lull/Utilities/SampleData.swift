import Foundation
import SwiftData

enum SampleData {
    static func load(into context: ModelContext) {
        let cal = Calendar.current
        let names = ["Box breathing", "4-7-8 relax", "Coherent", "Calm down", "Deep reset"]
        for offset in 0..<16 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            if offset == 4 || offset == 9 { continue }
            let count = offset % 3 == 0 ? 2 : 1
            for k in 0..<count {
                let name = names[(offset + k) % names.count]
                let planned = Double([180.0, 240, 300, 360][(offset + k) % 4])
                let completed = offset % 5 == 0 ? planned * 0.7 : planned
                let hour = k == 0 ? 8 : 22
                let date = cal.date(bySettingHour: hour, minute: 30, second: 0, of: day) ?? day
                context.insert(BreathSession(date: date, patternName: name,
                                             plannedSeconds: planned, completedSeconds: completed,
                                             roundsCompleted: Int(completed / 16),
                                             calmBefore: 2 + (offset % 2), calmAfter: 4 + (offset % 2)))
            }
        }
        try? context.save()
    }
}
