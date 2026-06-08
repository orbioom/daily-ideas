import Foundation
import SwiftData

enum SampleData {
    static func load(into context: ModelContext) {
        let cal = Calendar.current
        let tags = ["Study", "Work", "Read", "Create", "Deep work"]
        let durations: [Double] = [25, 25, 50, 15, 90, 45]
        for offset in 0..<16 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            if offset == 5 || offset == 12 { continue }
            let count = 1 + (offset % 3)
            for k in 0..<count {
                let planned = durations[(offset + k) % durations.count] * 60
                let success = !(offset % 6 == 0 && k == 0) // occasional wither
                let completed = success ? planned : planned * 0.4
                let hour = 9 + k * 3
                let date = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
                let species = TreeSpecies.forDuration(minutes: planned / 60).rawValue
                context.insert(FocusSession(date: date, plannedSeconds: planned,
                                            completedSeconds: completed, success: success,
                                            tagName: tags[(offset + k) % tags.count], species: species))
            }
        }
        try? context.save()
    }
}
