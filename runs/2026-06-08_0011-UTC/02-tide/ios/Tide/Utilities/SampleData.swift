import Foundation
import SwiftData

enum SampleData {
    static func load(into context: ModelContext) {
        let activities = (try? context.fetch(FetchDescriptor<Activity>())) ?? []
        guard !activities.isEmpty else { return }
        func find(_ name: String) -> Activity? { activities.first { $0.name == name } }
        let cal = Calendar.current

        // 24 days of entries with a believable structure: exercise & good sleep
        // skew positive, screen time & chores skew negative.
        for offset in 0..<24 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            if offset == 6 || offset == 14 { continue } // gaps
            let count = (offset % 3 == 0) ? 2 : 1
            for k in 0..<count {
                var tags: [Activity] = []
                var base = 3
                if offset % 2 == 0 { if let a = find("Exercise") { tags.append(a) }; base += 1 }
                if offset % 3 == 0 { if let a = find("Good sleep") { tags.append(a) }; base += 1 }
                if offset % 4 == 0 { if let a = find("Screen time") { tags.append(a) }; base -= 1 }
                if offset % 5 == 0 { if let a = find("Friends") { tags.append(a) }; base += 1 }
                if offset % 7 == 0 { if let a = find("Chores") { tags.append(a) }; base -= 1 }
                if let a = find("Work"), k == 0 { tags.append(a) }
                let mood = max(1, min(5, base + ((offset + k) % 2 == 0 ? 0 : -1)))
                let hour = k == 0 ? 9 : 20
                let date = cal.date(bySettingHour: hour, minute: 15, second: 0, of: day) ?? day
                let entry = MoodEntry(date: date, mood: mood,
                                      note: offset % 5 == 0 ? "A steady day." : "",
                                      activities: tags)
                context.insert(entry)
            }
        }
        try? context.save()
    }
}
