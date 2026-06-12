import Foundation
import SwiftData

/// Seeds one example intention with two weeks of believable practice so Home,
/// the detail heatmap and Insights look alive on first launch. The user can
/// delete it any time.
enum SeedData {
    @MainActor
    static func installIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Intention>())) ?? 0
        guard count == 0 else { return }

        let intent = Intention(
            title: "Dream role",
            affirmation: "I am thriving in work I love and am paid generously for it.",
            category: .career,
            practiceLength: 33,
            notes: "I can already feel the excitement of the offer call.")
        let cal = Calendar.current
        intent.createdAt = cal.date(byAdding: .day, value: -16, to: Date()) ?? Date()
        context.insert(intent)

        var seed: UInt64 = 0xC0FFEE
        func chance() -> Double { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return Double(seed % 1000) / 1000 }

        for offset in stride(from: 15, through: 1, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let roll = chance()
            let log: PracticeLog
            if roll > 0.78 {              // a missed day here and there
                continue
            } else if roll > 0.18 {       // a full 3-6-9 day
                log = PracticeLog(day: day, morning: 3, afternoon: 6, evening: 9)
            } else {                      // a partial day
                log = PracticeLog(day: day, morning: 3, afternoon: Int(chance() * 6), evening: 0)
            }
            log.intention = intent
            intent.logs.append(log)
            context.insert(log)
        }
        try? context.save()
    }
}
