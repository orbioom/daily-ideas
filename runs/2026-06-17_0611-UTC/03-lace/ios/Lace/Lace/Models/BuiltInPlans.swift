import Foundation

/// The built-in, code-defined training plans. Durations mirror the genuine,
/// well-known Couch-to-5K progression plus a gentler Easy Start ramp and a
/// 5K→10K bridge. Nothing here is user-editable.
enum BuiltInPlans {

    static let couchTo5K = makeCouchTo5K()
    static let easyStart = makeEasyStart()
    static let bridge10K = makeBridge10K()

    /// All built-in plans in display order.
    static let all: [TrainingPlan] = [couchTo5K, easyStart, bridge10K]

    /// Look up a built-in plan by id.
    static func plan(id: String) -> TrainingPlan? {
        all.first { $0.id == id }
    }

    // Shared blocks.
    private static let warm = Interval.warmup(5 * 60)   // 5-min brisk-walk warmup
    private static let cool = Interval.cooldown(5 * 60) // 5-min cooldown

    /// Build a session of alternating run/walk reps, framed by warmup & cooldown.
    private static func alternating(id: String, run: Int, walk: Int, reps: Int) -> PlanSession {
        var intervals: [Interval] = [warm]
        for i in 0..<reps {
            intervals.append(.run(run))
            // No trailing walk after the final rep — go straight to cooldown.
            if i < reps - 1 { intervals.append(.walk(walk)) }
        }
        intervals.append(cool)
        return PlanSession(id: id, intervals: intervals)
    }

    /// Build a session from an explicit ordered list of (kind, seconds) blocks,
    /// framed by warmup & cooldown.
    private static func custom(id: String, blocks: [(IntervalKind, Int)]) -> PlanSession {
        var intervals: [Interval] = [warm]
        for (kind, secs) in blocks {
            intervals.append(Interval(kind: kind, durationSeconds: secs))
        }
        intervals.append(cool)
        return PlanSession(id: id, intervals: intervals)
    }

    /// A continuous run session (warmup, one run, cooldown).
    private static func continuousRun(id: String, minutes: Int) -> PlanSession {
        PlanSession(id: id, intervals: [warm, .run(minutes * 60), cool])
    }

    // MARK: - Couch to 5K (classic, 9 weeks × 3)

    private static func makeCouchTo5K() -> TrainingPlan {
        let p = "c25k"
        func sid(_ w: Int, _ s: Int) -> String { "\(p)-w\(w)-s\(s)" }

        var weeks: [PlanWeek] = []

        // Week 1: 60s run / 90s walk × 8.
        weeks.append(PlanWeek(id: 1, focus: "Find your rhythm", sessions: (0..<3).map {
            alternating(id: sid(1, $0), run: 60, walk: 90, reps: 8)
        }))

        // Week 2: 90s run / 120s walk × 6.
        weeks.append(PlanWeek(id: 2, focus: "Build the habit", sessions: (0..<3).map {
            alternating(id: sid(2, $0), run: 90, walk: 120, reps: 6)
        }))

        // Week 3: (run 90s, walk 90s, run 180s, walk 180s) × 2.
        let w3blocks: [(IntervalKind, Int)] = [
            (.run, 90), (.walk, 90), (.run, 180), (.walk, 180),
            (.run, 90), (.walk, 90), (.run, 180)
        ]
        weeks.append(PlanWeek(id: 3, focus: "Stretch the runs", sessions: (0..<3).map {
            custom(id: sid(3, $0), blocks: w3blocks)
        }))

        // Week 4: run 180s, walk 90s, run 300s, walk 150s, run 180s, walk 90s, run 300s.
        let w4blocks: [(IntervalKind, Int)] = [
            (.run, 180), (.walk, 90), (.run, 300), (.walk, 150),
            (.run, 180), (.walk, 90), (.run, 300)
        ]
        weeks.append(PlanWeek(id: 4, focus: "Longer efforts", sessions: (0..<3).map {
            custom(id: sid(4, $0), blocks: w4blocks)
        }))

        // Week 5: three distinct sessions.
        let w5s0: [(IntervalKind, Int)] = [(.run, 300), (.walk, 180), (.run, 300), (.walk, 180), (.run, 300)]
        let w5s1: [(IntervalKind, Int)] = [(.run, 480), (.walk, 300), (.run, 480)]
        let w5s2: [(IntervalKind, Int)] = [(.run, 20 * 60)] // 20-min continuous
        weeks.append(PlanWeek(id: 5, focus: "The first long run", sessions: [
            custom(id: sid(5, 0), blocks: w5s0),
            custom(id: sid(5, 1), blocks: w5s1),
            custom(id: sid(5, 2), blocks: w5s2)
        ]))

        // Week 6: three distinct sessions.
        let w6s0: [(IntervalKind, Int)] = [(.run, 300), (.walk, 180), (.run, 480), (.walk, 180), (.run, 300)]
        let w6s1: [(IntervalKind, Int)] = [(.run, 600), (.walk, 180), (.run, 600)]
        let w6s2: [(IntervalKind, Int)] = [(.run, 25 * 60)] // 25-min continuous
        weeks.append(PlanWeek(id: 6, focus: "Lengthen with confidence", sessions: [
            custom(id: sid(6, 0), blocks: w6s0),
            custom(id: sid(6, 1), blocks: w6s1),
            custom(id: sid(6, 2), blocks: w6s2)
        ]))

        // Week 7: 25-min continuous × 3.
        weeks.append(PlanWeek(id: 7, focus: "Steady state", sessions: (0..<3).map {
            continuousRun(id: sid(7, $0), minutes: 25)
        }))

        // Week 8: 28-min continuous × 3.
        weeks.append(PlanWeek(id: 8, focus: "Almost there", sessions: (0..<3).map {
            continuousRun(id: sid(8, $0), minutes: 28)
        }))

        // Week 9: 30-min continuous × 3 — graduation.
        weeks.append(PlanWeek(id: 9, focus: "Graduate · run 5K", sessions: (0..<3).map {
            continuousRun(id: sid(9, $0), minutes: 30)
        }))

        return TrainingPlan(
            id: p,
            title: "Couch to 5K",
            subtitle: "9 weeks · the classic run/walk plan",
            symbol: "figure.run",
            isPro: false,
            weeks: weeks
        )
    }

    // MARK: - Easy Start (gentler, 12 weeks)

    private static func makeEasyStart() -> TrainingPlan {
        let p = "easy-start"
        func sid(_ w: Int, _ s: Int) -> String { "\(p)-w\(w)-s\(s)" }

        // Kinder ramp: shorter runs, more walk recovery, more weeks to 30 min.
        // (run seconds, walk seconds, reps) per week.
        let table: [(run: Int, walk: Int, reps: Int, focus: String)] = [
            (30, 120, 8, "Gentle first steps"),
            (45, 120, 8, "Easing in"),
            (60, 120, 7, "Settle the breathing"),
            (75, 120, 6, "A little longer"),
            (90, 120, 6, "Find a steady pace"),
            (120, 120, 5, "Two-minute runs"),
            (150, 120, 5, "Building stamina"),
            (180, 120, 4, "Three-minute runs"),
            (240, 120, 4, "Four-minute runs"),
            (300, 150, 3, "Five-minute runs"),
            (480, 180, 2, "Long efforts"),
            (600, 0, 1, "Run ten minutes — and beyond")
        ]

        var weeks: [PlanWeek] = []
        for (i, row) in table.enumerated() {
            let w = i + 1
            let sessions = (0..<3).map { s -> PlanSession in
                if row.reps <= 1 {
                    // Continuous run week.
                    return continuousRun(id: sid(w, s), minutes: max(1, row.run / 60))
                }
                return alternating(id: sid(w, s), run: row.run, walk: row.walk, reps: row.reps)
            }
            weeks.append(PlanWeek(id: w, focus: row.focus, sessions: sessions))
        }

        return TrainingPlan(
            id: p,
            title: "Easy Start",
            subtitle: "12 weeks · the kindest possible ramp",
            symbol: "figure.walk.motion",
            isPro: true,
            weeks: weeks
        )
    }

    // MARK: - 5K to 10K bridge (6 weeks)

    private static func makeBridge10K() -> TrainingPlan {
        let p = "bridge-10k"
        func sid(_ w: Int, _ s: Int) -> String { "\(p)-w\(w)-s\(s)" }

        // For graduates: continuous runs that grow toward ~60 minutes / 10K.
        let minutesByWeek: [(a: Int, b: Int, c: Int, focus: String)] = [
            (30, 32, 35, "Hold your 5K base"),
            (35, 38, 40, "Add five minutes"),
            (40, 42, 45, "Toward 45 minutes"),
            (45, 48, 50, "Half-hour feels easy now"),
            (50, 52, 55, "Approaching an hour"),
            (55, 58, 60, "Run 10K")
        ]

        var weeks: [PlanWeek] = []
        for (i, row) in minutesByWeek.enumerated() {
            let w = i + 1
            weeks.append(PlanWeek(id: w, focus: row.focus, sessions: [
                continuousRun(id: sid(w, 0), minutes: row.a),
                continuousRun(id: sid(w, 1), minutes: row.b),
                continuousRun(id: sid(w, 2), minutes: row.c)
            ]))
        }

        return TrainingPlan(
            id: p,
            title: "5K to 10K Bridge",
            subtitle: "6 weeks · double your distance",
            symbol: "flag.checkered",
            isPro: true,
            weeks: weeks
        )
    }
}
