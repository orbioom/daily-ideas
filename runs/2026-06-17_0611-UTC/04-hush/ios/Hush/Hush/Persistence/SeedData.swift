import Foundation
import SwiftData

/// Seeds a couple of starter saved mixes plus ~5 weeks of nightly listening
/// sessions on first launch so the Mixes and Sessions screens have real data.
/// Idempotent: it checks for existing data before inserting anything.
enum SeedData {

    static func seedIfNeeded(_ context: ModelContext) {
        seedMixesIfNeeded(context)
        seedSessionsIfNeeded(context)
    }

    private static func seedMixesIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<SavedMix>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let now = Date()
        let cal = Calendar.current

        // A couple of personal saved mixes (favorited).
        let rainy = SavedMix(name: "Rainy Window",
                             createdAt: cal.date(byAdding: .day, value: -20, to: now) ?? now,
                             isFavorite: true)
        rainy.layers = [
            MixLayer(type: .rain, volume: 0.65),
            MixLayer(type: .brown, volume: 0.3),
            MixLayer(type: .fan, volume: 0.2)
        ]
        rainy.layers.forEach { $0.mix = rainy }
        context.insert(rainy)

        let waves = SavedMix(name: "Tide & Breeze",
                             createdAt: cal.date(byAdding: .day, value: -8, to: now) ?? now,
                             isFavorite: false)
        waves.layers = [
            MixLayer(type: .ocean, volume: 0.7),
            MixLayer(type: .pink, volume: 0.2)
        ]
        waves.layers.forEach { $0.mix = waves }
        context.insert(waves)

        try? context.save()
    }

    private static func seedSessionsIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<ListeningSession>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let now = Date()

        // ~5 weeks of mostly-nightly sessions with realistic durations and a
        // rotating set of mixes, to populate charts and the streak stat.
        let samples: [(daysAgo: Int, minutes: Int, mix: String, sounds: [SoundType])] = [
            (0, 52, "Rainy Window", [.rain, .brown, .fan]),
            (1, 47, "Ocean Night", [.ocean, .wind, .pink]),
            (2, 61, "Rainstorm", [.rain, .brown, .wind]),
            (3, 38, "Deep Focus", [.pink, .brown]),
            (4, 55, "Rainy Window", [.rain, .brown, .fan]),
            (5, 44, "Tide & Breeze", [.ocean, .pink]),
            (7, 50, "Rainstorm", [.rain, .brown, .wind]),
            (8, 33, "Cozy Fan", [.fan, .brown]),
            (9, 58, "Rainy Window", [.rain, .brown, .fan]),
            (10, 41, "Ocean Night", [.ocean, .wind, .pink]),
            (11, 49, "Forest Stream", [.stream, .night, .wind]),
            (13, 36, "Deep Focus", [.pink, .brown]),
            (14, 53, "Rainstorm", [.rain, .brown, .wind]),
            (16, 45, "Tide & Breeze", [.ocean, .pink]),
            (18, 60, "Rainy Window", [.rain, .brown, .fan]),
            (20, 39, "Campfire Night", [.fire, .night, .wind]),
            (21, 47, "Ocean Night", [.ocean, .wind, .pink]),
            (24, 51, "Rainstorm", [.rain, .brown, .wind]),
            (27, 42, "Cozy Fan", [.fan, .brown]),
            (30, 35, "Deep Focus", [.pink, .brown]),
            (33, 56, "Rainy Window", [.rain, .brown, .fan])
        ]

        for s in samples {
            guard let day = cal.date(byAdding: .day, value: -s.daysAgo, to: now) else { continue }
            // Start the session in the late evening.
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = 22
            comps.minute = 30
            let started = cal.date(from: comps) ?? day
            let session = ListeningSession(
                startedAt: started,
                durationSeconds: s.minutes * 60,
                mixName: s.mix,
                soundRaws: s.sounds.map { $0.rawValue }
            )
            context.insert(session)
        }

        try? context.save()
    }
}
