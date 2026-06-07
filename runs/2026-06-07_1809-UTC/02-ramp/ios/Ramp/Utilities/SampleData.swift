import Foundation
import SwiftData

/// Seeds a realistic ~3-month training history so the Performance Management
/// Chart looks alive on first launch: an FTP that improves over months, build
/// weeks ramping load, a recovery week, a couple of races, and rest days.
enum SampleData {

    /// Inserts sample FTP history and rides into the context if it is empty.
    /// Safe to call repeatedly — it no-ops when data already exists.
    static func seedIfEmpty(_ context: ModelContext) {
        let rideCount = (try? context.fetch(FetchDescriptor<Ride>()).count) ?? 0
        let ftpCount = (try? context.fetch(FetchDescriptor<FTPEntry>()).count) ?? 0
        guard rideCount == 0 && ftpCount == 0 else { return }
        seed(context)
    }

    static func seed(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // MARK: FTP history — improvement over ~5 months.
        let ftpHistory: [(daysAgo: Int, watts: Int, source: FTPSource, note: String)] = [
            (150, 248, .test20min, "End-of-winter baseline."),
            (95,  255, .rampTest,  "Base block paying off."),
            (50,  262, .test20min, "Mid-build retest."),
            (12,  270, .rampTest,  "Sharpening for race season.")
        ]
        for f in ftpHistory {
            let date = cal.date(byAdding: .day, value: -f.daysAgo, to: today) ?? today
            context.insert(FTPEntry(date: date, watts: f.watts, source: f.source, notes: f.note))
        }

        // FTP applicable on a given day, mirroring LoadEngine.ftp(on:).
        func ftp(daysAgo: Int) -> Int {
            let sorted = ftpHistory.sorted { $0.daysAgo > $1.daysAgo }
            var current = 248
            for f in sorted where f.daysAgo >= daysAgo { current = f.watts }
            return current
        }

        // MARK: Rides — 95 days of structured training.
        // Plan per weekday inside repeating build/recovery cycles. Index 0 = Monday.
        // We walk day by day from 95 days ago to yesterday.
        var rng = SeededGenerator(seed: 42)

        // Define a weekly template: which day-of-week gets which session.
        // (weekdayIndex, type, baseMinutes, intensityFactorTarget)
        struct Session { let type: RideType; let minutes: Int; let ifTarget: Double; let name: String }

        func weekPlan(week: Int) -> [Int: Session] {
            // Every 4th week is a recovery week (lighter, shorter).
            let recovery = (week % 4 == 3)
            if recovery {
                return [
                    1: Session(type: .recovery,  minutes: 45, ifTarget: 0.55, name: "Easy spin"),
                    3: Session(type: .endurance, minutes: 60, ifTarget: 0.66, name: "Light endurance"),
                    5: Session(type: .recovery,  minutes: 50, ifTarget: 0.58, name: "Coffee ride"),
                    6: Session(type: .endurance, minutes: 75, ifTarget: 0.68, name: "Recovery long")
                ]
            }
            return [
                0: Session(type: .endurance, minutes: 75,  ifTarget: 0.70, name: "Zone 2 endurance"),
                2: Session(type: .vo2,       minutes: 70,  ifTarget: 0.92, name: "VO2 intervals"),
                3: Session(type: .endurance, minutes: 60,  ifTarget: 0.69, name: "Midweek spin"),
                4: Session(type: .threshold, minutes: 80,  ifTarget: 0.88, name: "Sweet spot"),
                6: Session(type: .endurance, minutes: 150, ifTarget: 0.72, name: "Long ride")
            ]
        }

        var inserted: [Ride] = []
        for daysAgo in stride(from: 95, through: 1, by: -1) {
            guard let date = cal.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let weekIndex = (95 - daysAgo) / 7
            // weekday: Monday = 0 ... Sunday = 6
            let wd = (cal.component(.weekday, from: date) + 5) % 7
            let plan = weekPlan(week: weekIndex)
            guard var session = plan[wd] else { continue } // rest day

            let snapFTP = ftp(daysAgo: daysAgo)

            // A couple of races on specific Sundays of hard weeks.
            if (daysAgo == 23 || daysAgo == 58) && wd == 6 {
                session = Session(type: .race, minutes: 120, ifTarget: 0.95, name: "Road race")
            }

            // Jitter intensity and duration for realism.
            let ifJitter = session.ifTarget + Double.random(in: -0.04...0.04, using: &rng)
            let minutes = max(20, session.minutes + Int.random(in: -10...12, using: &rng))
            let np = Int((Double(snapFTP) * ifJitter).rounded())
            // Distance roughly from duration & type (indoor sessions get 0 sometimes).
            let speedKmh = session.type == .recovery ? 26.0 : (session.type == .race ? 38.0 : 31.0)
            let isIndoor = (session.type == .vo2 || session.type == .threshold) && Bool.random(using: &rng)
            let distance = isIndoor ? 0 : (Double(minutes) / 60.0) * speedKmh

            let ride = Ride(
                date: date.addingTimeInterval(Double.random(in: 6...19, using: &rng) * 3600),
                name: session.name,
                durationMin: minutes,
                type: session.type,
                entry: .power,
                normalizedPower: np,
                ftpAtTime: snapFTP,
                tssManual: 0,
                distanceKm: (distance * 10).rounded() / 10,
                notes: session.type == .race ? "Felt strong in the final climb." : ""
            )
            inserted.append(ride)
        }

        // Add a couple of manual-entry rides (e.g. logged from a friend's computer).
        if let d = cal.date(byAdding: .day, value: -40, to: today) {
            inserted.append(Ride(date: d, name: "Group ride (manual)", durationMin: 95,
                                 type: .endurance, entry: .manual, tssManual: 78, distanceKm: 48))
        }
        if let d = cal.date(byAdding: .day, value: -8, to: today) {
            inserted.append(Ride(date: d, name: "Gravel adventure", durationMin: 180,
                                 type: .endurance, entry: .manual, tssManual: 165, distanceKm: 72,
                                 notes: "No power meter that day."))
        }

        for ride in inserted { context.insert(ride) }
        try? context.save()
    }
}

/// A tiny deterministic PRNG so seeded data is identical run-to-run.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
