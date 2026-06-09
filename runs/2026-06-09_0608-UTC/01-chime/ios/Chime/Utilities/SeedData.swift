import Foundation
import SwiftData

/// Seeds a small set of built-in presets and a little history on first launch so
/// charts and lists are never empty for a brand-new user.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<MeditationPreset>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let presets: [MeditationPreset] = [
            MeditationPreset(name: "Quick reset", minutes: 5, warmupSeconds: 5,
                             startBell: .chime, endBell: .chime, isBuiltIn: true, sortIndex: 0),
            MeditationPreset(name: "Morning sit", minutes: 10, warmupSeconds: 10,
                             startBell: .bowl, endBell: .bowl, isBuiltIn: true, sortIndex: 1),
            MeditationPreset(name: "Daily practice", minutes: 20, warmupSeconds: 15,
                             intervalMinutes: 10, startBell: .temple, intervalBell: .woodblock,
                             endBell: .temple, isBuiltIn: true, sortIndex: 2),
            MeditationPreset(name: "Deep stillness", minutes: 45, warmupSeconds: 20,
                             intervalMinutes: 15, startBell: .gong, intervalBell: .chime,
                             endBell: .gong, isBuiltIn: true, sortIndex: 3)
        ]
        presets.forEach { context.insert($0) }

        // A gentle starter history across the last several days.
        let cal = Calendar.current
        let samples: [(daysAgo: Int, name: String, planned: Int, actual: Int, done: Bool, feel: Int)] = [
            (1, "Morning sit", 600, 600, true, 4),
            (2, "Quick reset", 300, 300, true, 3),
            (3, "Daily practice", 1200, 1080, false, 4),
            (4, "Morning sit", 600, 600, true, 5),
            (6, "Quick reset", 300, 300, true, 3)
        ]
        for s in samples {
            if let date = cal.date(byAdding: .day, value: -s.daysAgo, to: .now) {
                context.insert(MeditationSession(date: date, presetName: s.name,
                                                 plannedSeconds: s.planned, actualSeconds: s.actual,
                                                 completed: s.done, feeling: s.feel))
            }
        }
        try? context.save()
    }
}
