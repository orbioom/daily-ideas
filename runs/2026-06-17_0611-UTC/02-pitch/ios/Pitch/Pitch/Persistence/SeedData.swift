import Foundation
import SwiftData

/// Idempotent seeding of starter data: a couple of starter metronome presets
/// and ~8 weeks of synthetic practice history so the Charts summary has volume.
enum SeedData {
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        seedPresetsIfNeeded(context)
        seedPracticeIfNeeded(context)
    }

    @MainActor
    private static func seedPresetsIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<MetronomePreset>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let starters = [
            MetronomePreset(name: "Practice 80", bpm: 80,
                            timeSigTop: 4, timeSigBottom: 4,
                            subdivision: .quarter, accentFirst: true),
            MetronomePreset(name: "Waltz 120", bpm: 120,
                            timeSigTop: 3, timeSigBottom: 4,
                            subdivision: .quarter, accentFirst: true)
        ]
        for p in starters { context.insert(p) }
        try? context.save()
    }

    @MainActor
    private static func seedPracticeIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<PracticeLog>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // ~56 days of light synthetic history (not every day) for a believable chart.
        for dayOffset in 0..<56 {
            // Skip ~40% of days to look human.
            if dayOffset % 5 == 2 || dayOffset % 7 == 4 { continue }
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let minutes = Double(8 + (dayOffset * 7) % 28)
            let bpm = 70 + (dayOffset * 13) % 90
            context.insert(PracticeLog(date: date, minutes: minutes, bpm: bpm))
        }
        try? context.save()
    }
}
