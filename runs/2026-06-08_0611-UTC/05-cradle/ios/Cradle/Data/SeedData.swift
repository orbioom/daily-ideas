import Foundation
import SwiftData

/// Seeds two babies with 7 days of realistic newborn data (well over 50 events).
enum SeedData {

    static func seed(context: ModelContext) {
        // Guard: only seed if no babies exist
        let descriptor = FetchDescriptor<Baby>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let now = Date()

        // Baby 1 — ~3 months old
        guard let birth1 = cal.date(byAdding: .day, value: -95, to: now) else { return }
        let baby1 = Baby(
            name: "Mia",
            birthDate: birth1,
            sex: .girl,
            symbol: "star.fill",
            colorHex: 0xC0553E,
            order: 0
        )
        context.insert(baby1)

        // Baby 2 — ~6 weeks old
        guard let birth2 = cal.date(byAdding: .day, value: -42, to: now) else { return }
        let baby2 = Baby(
            name: "Leo",
            birthDate: birth2,
            sex: .boy,
            symbol: "moon.fill",
            colorHex: 0x4E6BA8,
            order: 1
        )
        context.insert(baby2)

        // Generate 7 days of events for baby1
        seedBabyEvents(baby: baby1, context: context, cal: cal, now: now, daysBack: 7)
        // Generate 5 days for baby2
        seedBabyEvents(baby: baby2, context: context, cal: cal, now: now, daysBack: 5)
    }

    // swiftlint:disable function_body_length
    private static func seedBabyEvents(
        baby: Baby,
        context: ModelContext,
        cal: Calendar,
        now: Date,
        daysBack: Int
    ) {
        for dayOffset in 0..<daysBack {
            let isToday = dayOffset == 0
            guard let dayBase = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            guard let midnight = cal.date(bySettingHour: 0, minute: 0, second: 0, of: dayBase) else { continue }

            // Feed schedule: roughly every 2.5-3h starting at 00:30
            // 8 feeds per day
            let feedMinutes = [30, 180, 300, 480, 660, 840, 1020, 1200]
            for (idx, feedMin) in feedMinutes.enumerated() {
                guard let start = cal.date(byAdding: .minute, value: feedMin, to: midnight) else { continue }
                if start > now { continue }

                // Alternate breast sides, occasionally bottle
                let isBottle = idx % 5 == 3
                let side: Side = idx % 2 == 0 ? .left : .right
                let dur = Double.random(in: 8...22) * 60
                guard let end = cal.date(byAdding: .second, value: Int(dur), to: start) else { continue }

                let event = CareEvent(
                    kind: .feed,
                    startTime: start,
                    endTime: isToday && idx == feedMinutes.count - 1 ? nil : end,
                    feedType: isBottle ? .bottle : .breast,
                    amountML: isBottle ? Double(Int.random(in: 60...120)) : nil,
                    breastSide: isBottle ? nil : side,
                    baby: baby
                )
                context.insert(event)
                baby.events.append(event)
            }

            // Sleep schedule: 4 sleeps/day
            // Morning nap, afternoon nap, evening nap, overnight
            let sleepSchedule: [(start: Int, duration: Int)] = [
                (90, 45),    // 01:30 overnight continues
                (450, 90),   // 07:30 morning nap
                (780, 60),   // 13:00 afternoon nap
                (990, 45),   // 16:30 evening nap
            ]
            for (idx, nap) in sleepSchedule.enumerated() {
                guard let start = cal.date(byAdding: .minute, value: nap.start, to: midnight) else { continue }
                if start > now { continue }
                let durMin = nap.duration + Int.random(in: -10...20)
                guard let end = cal.date(byAdding: .minute, value: max(10, durMin), to: start) else { continue }

                // Leave one ongoing sleep for today's last nap to show the live banner
                let leaveOngoing = isToday && idx == sleepSchedule.count - 1 && dayOffset == 0
                let event = CareEvent(
                    kind: .sleep,
                    startTime: start,
                    endTime: leaveOngoing ? nil : (end > now ? nil : end),
                    baby: baby
                )
                context.insert(event)
                baby.events.append(event)
            }

            // Diaper schedule: 6 per day
            let diaperMinutes = [60, 240, 420, 600, 810, 1050]
            let diaperTypes: [DiaperType] = [.wet, .wet, .dirty, .wet, .mixed, .wet]
            for (idx, diaperMin) in diaperMinutes.enumerated() {
                guard let start = cal.date(byAdding: .minute, value: diaperMin, to: midnight) else { continue }
                if start > now { continue }
                let dType = diaperTypes[idx % diaperTypes.count]
                let event = CareEvent(
                    kind: .diaper,
                    startTime: start,
                    endTime: start, // instant event
                    diaperType: dType,
                    baby: baby
                )
                context.insert(event)
                baby.events.append(event)
            }

            // Pump once per day (morning)
            if !isToday {
                guard let pumpStart = cal.date(byAdding: .hour, value: 6, to: midnight) else { continue }
                guard let pumpEnd = cal.date(byAdding: .minute, value: 15, to: pumpStart) else { continue }
                let pumpEvent = CareEvent(
                    kind: .pump,
                    startTime: pumpStart,
                    endTime: pumpEnd,
                    amountML: Double(Int.random(in: 80...150)),
                    baby: baby
                )
                context.insert(pumpEvent)
                baby.events.append(pumpEvent)
            }

            // Note once every other day
            if dayOffset % 2 == 0 {
                let noteTexts = [
                    "Seemed fussier than usual after the evening feed.",
                    "Slept well through the night, barely woke.",
                    "Noticed some congestion, keeping an eye on it.",
                    "Good latch today, longer feeds."
                ]
                guard let noteTime = cal.date(byAdding: .hour, value: 20, to: midnight) else { continue }
                if noteTime <= now {
                    let noteEvent = CareEvent(
                        kind: .note,
                        startTime: noteTime,
                        endTime: noteTime,
                        note: noteTexts[dayOffset % noteTexts.count],
                        baby: baby
                    )
                    context.insert(noteEvent)
                    baby.events.append(noteEvent)
                }
            }
        }
    }
    // swiftlint:enable function_body_length
}
