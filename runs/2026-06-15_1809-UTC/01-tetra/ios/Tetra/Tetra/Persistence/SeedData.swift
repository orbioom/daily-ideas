import Foundation
import SwiftData

/// Seeds 50+ realistic past `GameRecord`s on first launch so Stats and
/// Achievements look alive immediately. Guarded by a one-time flag and by an
/// empty-store check so it never duplicates or overwrites real play.
enum SeedData {
    private static let seededKey = "didSeedTetraHistory"

    static func seedIfNeeded(context: ModelContext) {
        if UserDefaults.standard.bool(forKey: seededKey) { return }

        // Don't seed if the player already has records (e.g. flag was reset).
        let descriptor = FetchDescriptor<GameRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        for record in makeRecords() {
            context.insert(record)
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// Builds a deterministic but lifelike spread of ~58 games across ~8 weeks.
    static func makeRecords(now: Date = Date(), calendar: Calendar = .current) -> [GameRecord] {
        var rng = SplitMix64(seed: 0xA11CE_2048)
        var records: [GameRecord] = []

        // (daysAgo, boardSize, score, highestTile, won, moves, seconds, mode)
        let plan: [(Int, Int, Int, Int, Bool, Int, Int, GameMode)] = [
            (55, 4, 1_240, 128, false, 96, 240, .classic),
            (55, 4, 880, 64, false, 70, 160, .classic),
            (53, 4, 2_360, 256, false, 150, 360, .classic),
            (52, 4, 1_020, 128, false, 84, 210, .daily),
            (50, 4, 3_180, 256, false, 188, 470, .classic),
            (49, 4, 640, 64, false, 58, 130, .classic),
            (48, 4, 4_220, 512, false, 232, 560, .classic),
            (47, 4, 1_560, 128, false, 110, 270, .daily),
            (45, 4, 2_040, 256, false, 142, 330, .classic),
            (44, 4, 760, 64, false, 64, 150, .classic),
            (43, 4, 5_380, 512, false, 268, 640, .classic),
            (42, 4, 1_180, 128, false, 92, 220, .daily),
            (41, 4, 3_640, 256, false, 198, 480, .classic),
            (39, 4, 6_720, 512, false, 312, 720, .classic),
            (38, 4, 940, 128, false, 76, 180, .classic),
            (37, 4, 2_880, 256, false, 176, 410, .daily),
            (36, 4, 8_460, 1_024, false, 360, 880, .classic),
            (35, 4, 1_320, 128, false, 100, 240, .classic),
            (34, 4, 4_960, 512, false, 256, 600, .classic),
            (33, 4, 2_140, 256, false, 148, 350, .daily),
            (31, 5, 7_240, 512, false, 330, 760, .classic),
            (30, 4, 11_280, 1_024, false, 408, 980, .classic),
            (29, 4, 1_640, 128, false, 116, 260, .classic),
            (28, 4, 5_720, 512, false, 280, 660, .daily),
            (27, 5, 3_880, 256, false, 214, 520, .classic),
            (26, 4, 9_640, 1_024, false, 372, 900, .classic),
            (25, 4, 2_460, 256, false, 162, 380, .classic),
            (24, 4, 14_320, 1_024, false, 446, 1_080, .classic),
            (23, 4, 1_080, 128, false, 88, 200, .daily),
            (22, 5, 6_180, 512, false, 300, 700, .classic),
            (21, 4, 18_960, 2_048, true, 512, 1_240, .classic),
            (20, 4, 2_720, 256, false, 172, 400, .classic),
            (19, 4, 7_840, 512, false, 336, 780, .daily),
            (18, 5, 10_460, 1_024, false, 388, 940, .classic),
            (17, 4, 3_240, 256, false, 190, 450, .classic),
            (16, 4, 12_680, 1_024, false, 420, 1_010, .classic),
            (15, 4, 1_460, 128, false, 106, 250, .daily),
            (14, 6, 8_920, 512, false, 360, 850, .classic),
            (13, 4, 21_540, 2_048, true, 540, 1_320, .classic),
            (12, 4, 4_120, 512, false, 240, 570, .classic),
            (11, 4, 2_960, 256, false, 184, 430, .daily),
            (10, 5, 13_780, 1_024, false, 432, 1_040, .classic),
            (9, 4, 6_640, 512, false, 312, 730, .classic),
            (8, 4, 1_720, 128, false, 120, 270, .classic),
            (7, 4, 9_280, 1_024, false, 366, 890, .daily),
            (6, 5, 16_240, 1_024, false, 470, 1_140, .classic),
            (5, 4, 3_520, 256, false, 196, 460, .classic),
            (4, 4, 24_880, 2_048, true, 560, 1_380, .classic),
            (3, 4, 2_280, 256, false, 156, 370, .daily),
            (3, 6, 11_960, 1_024, false, 404, 970, .classic),
            (2, 4, 7_120, 512, false, 320, 750, .classic),
            (2, 4, 1_380, 128, false, 102, 230, .classic),
            (1, 4, 13_240, 1_024, false, 426, 1_020, .daily),
            (1, 5, 5_640, 512, false, 286, 670, .classic),
            (0, 4, 4_460, 512, false, 248, 590, .classic),
            (0, 4, 2_640, 256, false, 168, 390, .classic),
            (0, 4, 920, 64, false, 74, 170, .classic),
            (0, 6, 18_320, 2_048, true, 524, 1_280, .classic)
        ]

        for (daysAgo, size, score, tile, won, moves, secs, mode) in plan {
            // Scatter the time-of-day a little so the chart isn't a straight grid.
            let dayStart = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now)) ?? now
            let jitter = Int(rng.next() % 60_000) // up to ~16.6 hours of seconds
            let date = dayStart.addingTimeInterval(TimeInterval(jitter))
            records.append(GameRecord(date: date, boardSize: size, score: score,
                                      highestTile: tile, won: won, moves: moves,
                                      durationSeconds: secs, mode: mode))
        }
        return records
    }
}
