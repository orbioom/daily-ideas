import Foundation
import SwiftData

/// Seeds a few weeks of running so logs and charts have content.
enum SampleData {
    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        func day(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: .now) ?? .now }
        let mile = PaceMath.mile

        let runs: [(String, Int, Double, Double, RunKind, Int)] = [
            ("Saturday long run", 2, 18000, 18 * 6 * 60 + 30, .long, 6),
            ("Easy shakeout", 4, 6000, 6 * 6 * 60, .easy, 3),
            ("Tempo 5 mi", 6, 5 * mile, 5 * 6 * 60 - 90, .tempo, 7),
            ("Track 6×800", 8, 7000, 7 * 5 * 60 + 40, .interval, 9),
            ("Recovery jog", 9, 5000, 5 * 6 * 60 + 40, .easy, 2),
            ("10K race", 11, 10000, 44 * 60 + 12, .race, 10),
            ("Easy mid-week", 13, 8000, 8 * 6 * 60 + 10, .easy, 4),
            ("Long progression", 16, 21097.5, 105 * 60, .long, 7),
            ("Parkrun 5K", 18, 5000, 21 * 60 + 40, .race, 10),
            ("Easy", 20, 6000, 6 * 6 * 60 + 20, .easy, 3),
        ]
        for r in runs {
            context.insert(Run(name: r.0, date: day(r.1), distanceMeters: r.2,
                               durationSeconds: r.3, kind: r.4, rpe: r.5))
        }
        try? context.save()
    }
}
