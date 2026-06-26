import Foundation
import SwiftData

enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<SwimSession>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // Create pools
        let lap25 = SwimPool(name: "Community Aquatic Center", lengthMeters: 25, poolType: "indoor")
        let lap50 = SwimPool(name: "Olympic Pool - City Rec", lengthMeters: 50, poolType: "indoor")
        let outdoor = SwimPool(name: "Sunrise Outdoor Pool", lengthMeters: 25, poolType: "outdoor")
        let lake = SwimPool(name: "Lake Merritt Open Water", lengthMeters: 50, poolType: "openWater")
        context.insert(lap25)
        context.insert(lap50)
        context.insert(outdoor)
        context.insert(lake)

        let cal = Calendar.current
        let now = Date()

        struct SessionTemplate {
            let daysAgo: Int
            let distance: Double
            let duration: Int
            let pool: SwimPool
            let rating: Int
            let sets: [(String, Double, Int, Int, Int, String)] // stroke, dist, reps, dur, rest, intensity
        }

        let templates: [SessionTemplate] = [
            SessionTemplate(daysAgo: 0, distance: 2000, duration: 3600, pool: lap25, rating: 4, sets: [
                ("freestyle", 400, 1, 480, 30, "easy"),
                ("freestyle", 100, 8, 90, 20, "moderate"),
                ("backstroke", 200, 2, 260, 30, "moderate"),
                ("freestyle", 200, 1, 220, 60, "hard")
            ]),
            SessionTemplate(daysAgo: 2, distance: 1800, duration: 3300, pool: lap25, rating: 5, sets: [
                ("freestyle", 200, 1, 240, 30, "easy"),
                ("im", 100, 4, 120, 30, "moderate"),
                ("breaststroke", 200, 2, 280, 30, "moderate"),
                ("kick", 100, 4, 140, 20, "moderate"),
                ("freestyle", 200, 1, 210, 0, "hard")
            ]),
            SessionTemplate(daysAgo: 4, distance: 2500, duration: 4200, pool: lap50, rating: 4, sets: [
                ("freestyle", 500, 1, 600, 60, "easy"),
                ("freestyle", 100, 10, 85, 15, "hard"),
                ("pull", 200, 2, 230, 30, "moderate"),
                ("freestyle", 300, 1, 300, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 7, distance: 1500, duration: 2700, pool: lap25, rating: 3, sets: [
                ("freestyle", 300, 1, 360, 30, "easy"),
                ("drill", 50, 6, 75, 20, "easy"),
                ("freestyle", 100, 6, 92, 15, "moderate"),
                ("freestyle", 100, 1, 105, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 9, distance: 3000, duration: 5400, pool: lap50, rating: 5, sets: [
                ("freestyle", 500, 1, 570, 60, "easy"),
                ("backstroke", 100, 4, 120, 20, "moderate"),
                ("breaststroke", 200, 2, 280, 30, "moderate"),
                ("freestyle", 200, 5, 195, 15, "hard"),
                ("kick", 100, 2, 145, 30, "easy"),
                ("freestyle", 300, 1, 300, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 11, distance: 1000, duration: 1800, pool: outdoor, rating: 4, sets: [
                ("freestyle", 200, 1, 240, 30, "easy"),
                ("freestyle", 50, 6, 52, 15, "moderate"),
                ("backstroke", 100, 2, 130, 20, "easy"),
                ("freestyle", 100, 1, 105, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 14, distance: 2000, duration: 3600, pool: lap25, rating: 3, sets: [
                ("freestyle", 400, 1, 480, 30, "easy"),
                ("im", 100, 4, 130, 30, "moderate"),
                ("freestyle", 100, 8, 88, 15, "hard"),
                ("freestyle", 200, 1, 210, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 16, distance: 1600, duration: 2880, pool: lap25, rating: 4, sets: [
                ("freestyle", 400, 1, 480, 60, "easy"),
                ("butterfly", 50, 4, 65, 30, "hard"),
                ("freestyle", 100, 4, 92, 15, "moderate"),
                ("breaststroke", 100, 2, 140, 30, "easy"),
                ("freestyle", 200, 1, 195, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 18, distance: 2400, duration: 4320, pool: lap50, rating: 5, sets: [
                ("freestyle", 400, 1, 460, 60, "easy"),
                ("freestyle", 200, 6, 198, 20, "moderate"),
                ("pull", 200, 2, 225, 30, "moderate"),
                ("kick", 50, 4, 70, 20, "easy"),
                ("freestyle", 400, 1, 380, 0, "hard")
            ]),
            SessionTemplate(daysAgo: 21, distance: 1200, duration: 2160, pool: outdoor, rating: 3, sets: [
                ("freestyle", 300, 1, 360, 30, "easy"),
                ("backstroke", 100, 3, 130, 20, "moderate"),
                ("freestyle", 100, 3, 90, 15, "moderate"),
                ("freestyle", 200, 1, 195, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 23, distance: 3200, duration: 5760, pool: lap50, rating: 5, sets: [
                ("freestyle", 600, 1, 680, 90, "easy"),
                ("freestyle", 100, 12, 88, 12, "hard"),
                ("backstroke", 200, 2, 255, 30, "moderate"),
                ("im", 200, 2, 265, 30, "hard"),
                ("pull", 200, 2, 230, 30, "moderate"),
                ("freestyle", 400, 1, 380, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 25, distance: 1800, duration: 3240, pool: lap25, rating: 4, sets: [
                ("freestyle", 400, 1, 480, 30, "easy"),
                ("drill", 50, 8, 72, 15, "easy"),
                ("freestyle", 100, 6, 88, 15, "moderate"),
                ("freestyle", 200, 1, 198, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 28, distance: 2000, duration: 3600, pool: lap25, rating: 4, sets: [
                ("freestyle", 500, 1, 590, 60, "easy"),
                ("butterfly", 50, 3, 68, 30, "hard"),
                ("breaststroke", 100, 3, 145, 30, "moderate"),
                ("freestyle", 100, 5, 91, 15, "moderate"),
                ("freestyle", 200, 1, 195, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 30, distance: 1000, duration: 1800, pool: lake, rating: 5, sets: [
                ("freestyle", 500, 1, 620, 120, "easy"),
                ("freestyle", 250, 2, 295, 60, "moderate"),
                ("freestyle", 500, 1, 570, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 32, distance: 2600, duration: 4680, pool: lap50, rating: 4, sets: [
                ("freestyle", 400, 1, 460, 60, "easy"),
                ("freestyle", 200, 5, 196, 20, "hard"),
                ("backstroke", 200, 2, 260, 30, "moderate"),
                ("kick", 100, 4, 145, 20, "easy"),
                ("freestyle", 400, 1, 385, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 35, distance: 1500, duration: 2700, pool: lap25, rating: 3, sets: [
                ("freestyle", 300, 1, 360, 30, "easy"),
                ("breaststroke", 100, 3, 148, 30, "moderate"),
                ("freestyle", 100, 6, 90, 15, "moderate"),
                ("freestyle", 200, 1, 200, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 37, distance: 2000, duration: 3600, pool: lap25, rating: 4, sets: [
                ("freestyle", 400, 1, 480, 30, "easy"),
                ("im", 100, 6, 128, 25, "moderate"),
                ("freestyle", 200, 2, 198, 20, "hard"),
                ("freestyle", 200, 1, 195, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 39, distance: 3500, duration: 6300, pool: lap50, rating: 5, sets: [
                ("freestyle", 700, 1, 780, 90, "easy"),
                ("freestyle", 100, 14, 87, 10, "hard"),
                ("backstroke", 200, 2, 258, 30, "moderate"),
                ("breaststroke", 200, 2, 285, 30, "moderate"),
                ("im", 200, 1, 268, 60, "hard"),
                ("pull", 300, 1, 328, 30, "moderate"),
                ("freestyle", 400, 1, 378, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 42, distance: 1200, duration: 2160, pool: outdoor, rating: 4, sets: [
                ("freestyle", 400, 1, 480, 60, "easy"),
                ("backstroke", 100, 4, 130, 20, "easy"),
                ("freestyle", 100, 4, 91, 15, "moderate")
            ]),
            SessionTemplate(daysAgo: 44, distance: 1800, duration: 3240, pool: lap25, rating: 3, sets: [
                ("freestyle", 400, 1, 480, 30, "easy"),
                ("drill", 50, 6, 74, 15, "easy"),
                ("im", 100, 4, 132, 25, "moderate"),
                ("freestyle", 200, 2, 200, 20, "moderate"),
                ("freestyle", 200, 1, 198, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 46, distance: 2200, duration: 3960, pool: lap50, rating: 4, sets: [
                ("freestyle", 400, 1, 458, 60, "easy"),
                ("freestyle", 200, 5, 197, 20, "moderate"),
                ("pull", 200, 2, 232, 30, "moderate"),
                ("freestyle", 400, 1, 385, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 49, distance: 1500, duration: 2700, pool: lap25, rating: 4, sets: [
                ("freestyle", 300, 1, 360, 30, "easy"),
                ("butterfly", 50, 2, 67, 30, "hard"),
                ("freestyle", 100, 6, 89, 15, "moderate"),
                ("breaststroke", 100, 2, 148, 25, "moderate"),
                ("freestyle", 200, 1, 198, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 51, distance: 1000, duration: 1800, pool: lake, rating: 5, sets: [
                ("freestyle", 1000, 1, 1200, 0, "easy")
            ]),
            SessionTemplate(daysAgo: 53, distance: 2000, duration: 3600, pool: lap25, rating: 4, sets: [
                ("freestyle", 500, 1, 590, 60, "easy"),
                ("im", 100, 5, 130, 25, "moderate"),
                ("freestyle", 100, 5, 89, 12, "hard"),
                ("kick", 100, 2, 147, 25, "easy"),
                ("freestyle", 200, 1, 197, 0, "moderate")
            ]),
            SessionTemplate(daysAgo: 56, distance: 2800, duration: 5040, pool: lap50, rating: 5, sets: [
                ("freestyle", 500, 1, 570, 60, "easy"),
                ("backstroke", 200, 3, 260, 30, "moderate"),
                ("freestyle", 200, 5, 196, 18, "hard"),
                ("breaststroke", 200, 1, 290, 45, "moderate"),
                ("freestyle", 300, 1, 295, 0, "moderate")
            ])
        ]

        for t in templates {
            guard let sessionDate = cal.date(byAdding: .day, value: -t.daysAgo, to: now) else { continue }
            let session = SwimSession(
                date: sessionDate,
                totalDistanceMeters: t.distance,
                durationSeconds: t.duration,
                pool: t.pool,
                notes: "",
                feelRating: t.rating
            )
            context.insert(session)
            for (idx, s) in t.sets.enumerated() {
                let set = SwimSet(
                    sortOrder: idx,
                    strokeType: s.0,
                    distanceMeters: s.1,
                    repetitions: s.2,
                    durationSeconds: s.3,
                    restSeconds: s.4,
                    intensityLevel: s.5
                )
                set.session = session
                context.insert(set)
            }
        }

        try? context.save()
    }
}
