import Foundation
import SwiftData

/// Generates ~40 realistic SleepLog records ending on the night before today.
enum SeedData {

    static func seed(into context: ModelContext) {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())

        struct Night {
            let daysAgo: Int
            let bedH: Int; let bedM: Int
            let wakeH: Int; let wakeM: Int
            let quality: Int
            let awakenings: Int
            let tags: [String]
            let note: String
        }

        let nights: [Night] = [
            Night(daysAgo: 1,  bedH: 23, bedM: 10, wakeH: 7,  wakeM: 5,  quality: 4, awakenings: 1, tags: ["Exercise"],          note: "Felt rested after evening run."),
            Night(daysAgo: 2,  bedH: 0,  bedM: 30, wakeH: 7,  wakeM: 45, quality: 3, awakenings: 2, tags: ["Late screen"],        note: ""),
            Night(daysAgo: 3,  bedH: 22, bedM: 45, wakeH: 6,  wakeM: 30, quality: 5, awakenings: 0, tags: [],                    note: "Best sleep in weeks."),
            Night(daysAgo: 4,  bedH: 23, bedM: 55, wakeH: 7,  wakeM: 20, quality: 3, awakenings: 1, tags: ["Caffeine"],          note: "Had coffee at 4pm."),
            Night(daysAgo: 5,  bedH: 1,  bedM: 0,  wakeH: 7,  wakeM: 30, quality: 2, awakenings: 3, tags: ["Stress","Late screen"], note: "Anxious about deadline."),
            Night(daysAgo: 6,  bedH: 23, bedM: 0,  wakeH: 7,  wakeM: 0,  quality: 4, awakenings: 1, tags: ["Exercise"],          note: ""),
            Night(daysAgo: 7,  bedH: 23, bedM: 30, wakeH: 6,  wakeM: 50, quality: 4, awakenings: 0, tags: [],                    note: ""),
            Night(daysAgo: 8,  bedH: 0,  bedM: 15, wakeH: 8,  wakeM: 0,  quality: 3, awakenings: 2, tags: ["Alcohol"],           note: "Glass of wine at dinner."),
            Night(daysAgo: 9,  bedH: 22, bedM: 50, wakeH: 6,  wakeM: 40, quality: 5, awakenings: 0, tags: ["Exercise"],          note: "Morning yoga, very calm."),
            Night(daysAgo: 10, bedH: 23, bedM: 20, wakeH: 7,  wakeM: 10, quality: 4, awakenings: 1, tags: [],                    note: ""),
            Night(daysAgo: 11, bedH: 2,  bedM: 0,  wakeH: 8,  wakeM: 30, quality: 2, awakenings: 3, tags: ["Stress","Caffeine"], note: "Late-night work session."),
            Night(daysAgo: 12, bedH: 23, bedM: 0,  wakeH: 6,  wakeM: 55, quality: 4, awakenings: 1, tags: [],                    note: ""),
            Night(daysAgo: 13, bedH: 22, bedM: 40, wakeH: 6,  wakeM: 30, quality: 5, awakenings: 0, tags: ["Exercise"],          note: "10-mile run, dead tired."),
            Night(daysAgo: 14, bedH: 23, bedM: 50, wakeH: 7,  wakeM: 25, quality: 3, awakenings: 2, tags: ["Late screen"],       note: ""),
            Night(daysAgo: 15, bedH: 0,  bedM: 45, wakeH: 7,  wakeM: 50, quality: 2, awakenings: 3, tags: ["Alcohol","Stress"],  note: "Dinner party, got home late."),
            Night(daysAgo: 16, bedH: 23, bedM: 5,  wakeH: 7,  wakeM: 0,  quality: 4, awakenings: 1, tags: [],                    note: ""),
            Night(daysAgo: 17, bedH: 23, bedM: 15, wakeH: 6,  wakeM: 45, quality: 4, awakenings: 0, tags: ["Exercise"],          note: ""),
            Night(daysAgo: 18, bedH: 22, bedM: 55, wakeH: 6,  wakeM: 35, quality: 5, awakenings: 0, tags: [],                    note: "Super productive next day."),
            Night(daysAgo: 19, bedH: 0,  bedM: 0,  wakeH: 7,  wakeM: 30, quality: 3, awakenings: 2, tags: ["Late screen"],       note: ""),
            Night(daysAgo: 20, bedH: 23, bedM: 30, wakeH: 7,  wakeM: 15, quality: 4, awakenings: 1, tags: [],                    note: ""),
            Night(daysAgo: 21, bedH: 1,  bedM: 30, wakeH: 8,  wakeM: 0,  quality: 2, awakenings: 4, tags: ["Caffeine","Stress"], note: "Couldn't wind down."),
            Night(daysAgo: 22, bedH: 23, bedM: 0,  wakeH: 6,  wakeM: 50, quality: 4, awakenings: 1, tags: [],                    note: ""),
            Night(daysAgo: 23, bedH: 22, bedM: 45, wakeH: 6,  wakeM: 30, quality: 5, awakenings: 0, tags: ["Exercise"],          note: ""),
            Night(daysAgo: 24, bedH: 23, bedM: 40, wakeH: 7,  wakeM: 20, quality: 3, awakenings: 2, tags: ["Nap"],               note: "2h nap made bedtime hard."),
            Night(daysAgo: 25, bedH: 0,  bedM: 20, wakeH: 7,  wakeM: 40, quality: 3, awakenings: 1, tags: ["Late screen"],       note: ""),
            Night(daysAgo: 26, bedH: 22, bedM: 50, wakeH: 6,  wakeM: 45, quality: 5, awakenings: 0, tags: ["Exercise"],          note: "Perfect."),
            Night(daysAgo: 27, bedH: 23, bedM: 10, wakeH: 7,  wakeM: 5,  quality: 4, awakenings: 1, tags: [],                    note: ""),
            Night(daysAgo: 28, bedH: 23, bedM: 55, wakeH: 7,  wakeM: 30, quality: 3, awakenings: 2, tags: ["Alcohol"],           note: ""),
            Night(daysAgo: 29, bedH: 23, bedM: 25, wakeH: 6,  wakeM: 55, quality: 4, awakenings: 0, tags: [],                    note: ""),
            Night(daysAgo: 30, bedH: 2,  bedM: 10, wakeH: 7,  wakeM: 45, quality: 2, awakenings: 4, tags: ["Stress","Caffeine","Late screen"], note: "All-nighter adjacent."),
            Night(daysAgo: 31, bedH: 23, bedM: 0,  wakeH: 7,  wakeM: 0,  quality: 4, awakenings: 1, tags: [],                    note: ""),
            Night(daysAgo: 32, bedH: 22, bedM: 40, wakeH: 6,  wakeM: 30, quality: 5, awakenings: 0, tags: ["Exercise"],          note: ""),
            Night(daysAgo: 33, bedH: 23, bedM: 30, wakeH: 7,  wakeM: 20, quality: 3, awakenings: 2, tags: ["Late screen"],       note: ""),
            Night(daysAgo: 34, bedH: 0,  bedM: 5,  wakeH: 7,  wakeM: 50, quality: 3, awakenings: 1, tags: ["Nap"],               note: ""),
            Night(daysAgo: 35, bedH: 23, bedM: 15, wakeH: 6,  wakeM: 45, quality: 4, awakenings: 0, tags: [],                    note: ""),
            Night(daysAgo: 36, bedH: 23, bedM: 50, wakeH: 7,  wakeM: 35, quality: 4, awakenings: 1, tags: ["Exercise"],          note: ""),
            Night(daysAgo: 37, bedH: 1,  bedM: 0,  wakeH: 8,  wakeM: 15, quality: 2, awakenings: 3, tags: ["Alcohol","Stress"],  note: ""),
            Night(daysAgo: 38, bedH: 22, bedM: 55, wakeH: 6,  wakeM: 40, quality: 5, awakenings: 0, tags: ["Exercise"],          note: ""),
            Night(daysAgo: 39, bedH: 23, bedM: 20, wakeH: 7,  wakeM: 10, quality: 4, awakenings: 1, tags: [],                    note: ""),
            Night(daysAgo: 40, bedH: 0,  bedM: 30, wakeH: 7,  wakeM: 55, quality: 3, awakenings: 2, tags: ["Late screen"],       note: ""),
        ]

        for night in nights {
            guard let wakeDay = calendar.date(byAdding: .day, value: -night.daysAgo, to: today) else { continue }

            // wakeTime on wakeDay
            guard let wakeTime = calendar.date(bySettingHour: night.wakeH,
                                               minute: night.wakeM,
                                               second: 0,
                                               of: wakeDay) else { continue }

            // bedTime: if bedH >= 20, same calendar day as wake (i.e. night before)
            // We compute it as wakeDay minus one day for hour < 12, or wakeDay for hour >= 20
            let bedDayOffset = night.bedH < 12 ? 0 : -1
            guard let bedDay = calendar.date(byAdding: .day, value: bedDayOffset, to: wakeDay),
                  let bedTime = calendar.date(bySettingHour: night.bedH,
                                              minute: night.bedM,
                                              second: 0,
                                              of: bedDay) else { continue }

            // Safety check
            guard wakeTime > bedTime else { continue }

            let log = SleepLog(
                bedTime: bedTime,
                wakeTime: wakeTime,
                quality: night.quality,
                awakenings: night.awakenings,
                tags: night.tags,
                note: night.note,
                createdAt: wakeTime
            )
            context.insert(log)
        }

        try? context.save()
    }
}
