import SwiftData
import Foundation

enum StrokeSeeder {
    static func seed(context: ModelContext) {
        let desc = FetchDescriptor<RowWorkout>()
        guard (try? context.fetch(desc))?.isEmpty == true else { return }

        let calendar = Calendar.current
        let now = Date()
        var workouts: [RowWorkout] = []

        // Seed 55 workouts over 6 months with realistic progression
        let templates: [(WorkoutType, Int, Int, Int)] = [
            // type, distanceM, timeSeconds, splitSeconds
            (.distance, 2000, 456, 114),   // 7:36 2k @ 1:54/500m
            (.distance, 5000, 1320, 132),  // 22:00 5k @ 2:12/500m
            (.timed, 3850, 1200, 155),     // 20min piece
            (.distance, 500, 102, 102),    // 500m sprint
            (.timed, 5800, 1800, 155),     // 30min piece
            (.distance, 2000, 448, 112),   // 7:28 2k
            (.intervals, 4000, 900, 112),  // 8×500m intervals
            (.distance, 10000, 2760, 138), // 46min 10k
            (.freerow, 3000, 780, 130),    // Easy row
        ]

        for i in 0..<55 {
            let daysAgo = Double(i) * 3.2 + Double.random(in: 0...2)
            let date = calendar.date(byAdding: .day, value: -Int(daysAgo), to: now) ?? now
            let t = templates[i % templates.count]
            let splitVariation = Int.random(in: -8...5)
            let split = max(90, t.3 + splitVariation)
            let distance = t.0 == .timed ? t.1 + Int.random(in: -200...200) : t.1
            let time = t.0 == .timed ? t.3 : distance * split / 500
            let spm = Int.random(in: 18...26)
            let watts = RowEngine.splitToWatts(split)
            let rating = StrokeRating.allCases.randomElement() ?? .three

            let intervals: [WorkoutInterval] = t.0 == .intervals ? (0..<8).map { idx in
                let ivSplit = split + Int.random(in: -5...5)
                return WorkoutInterval(
                    number: idx + 1,
                    distanceM: 500,
                    timeSeconds: ivSplit,
                    splitSeconds: ivSplit,
                    strokeRate: spm + Int.random(in: -2...2),
                    watts: RowEngine.splitToWatts(ivSplit)
                )
            } : []

            let w = RowWorkout(
                date: date,
                type: t.0,
                distanceM: distance,
                timeSeconds: time,
                avgSplitSeconds: split,
                avgStrokeRate: spm,
                avgWatts: watts,
                rating: rating,
                notes: i % 8 == 0 ? "Felt strong today" : i % 11 == 0 ? "Tough session" : "",
                intervals: intervals
            )
            context.insert(w)
            workouts.append(w)
        }

        // Seed PRs
        let prValues: [(PRCategory, Int)] = [
            (.m500, 99), (.m2000, 448), (.m5000, 1298), (.m10000, 2720),
            (.min20, 3890), (.min30, 5820)
        ]
        for (cat, val) in prValues {
            let pr = RowPR(category: cat, value: val, achievedDate: calendar.date(byAdding: .day, value: -30, to: now) ?? now)
            context.insert(pr)
        }

        try? context.save()
    }
}
