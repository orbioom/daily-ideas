import Foundation

enum PlanLibrary {

    static let all: [RunPlan] = [couchTo5K, easyStart]

    static func plan(id: String) -> RunPlan {
        all.first { $0.id == id } ?? couchTo5K
    }

    // MARK: builders

    private static func wu() -> Segment { Segment(kind: .warmup, seconds: 300) }
    private static func cd() -> Segment { Segment(kind: .cooldown, seconds: 300) }

    /// reps of (run, walk). Optionally drop the final walk so the session ends on effort.
    private static func intervals(run: Int, walk: Int, reps: Int, dropLastWalk: Bool = true) -> [Segment] {
        var segs: [Segment] = []
        for i in 0..<reps {
            segs.append(Segment(kind: .run, seconds: run))
            if !(dropLastWalk && i == reps - 1) {
                segs.append(Segment(kind: .walk, seconds: walk))
            }
        }
        return segs
    }

    private static func workout(_ middle: [Segment]) -> Workout {
        Workout(segments: [wu()] + middle + [cd()])
    }

    private static func same(_ n: Int, _ note: String, _ w: Workout) -> WeekPlan {
        WeekPlan(number: n, note: note, sessions: [w, w, w])
    }

    // MARK: Couch to 5K (classic 9-week)

    static let couchTo5K: RunPlan = {
        let w1 = same(1, "Easy does it — short bursts with plenty of recovery.",
                      workout(intervals(run: 60, walk: 90, reps: 8)))
        let w2 = same(2, "A touch longer on the running.",
                      workout(intervals(run: 90, walk: 120, reps: 6)))
        let w3 = same(3, "Mixing 90-second and 3-minute runs.",
                      workout([Segment(kind: .run, seconds: 90), Segment(kind: .walk, seconds: 90),
                               Segment(kind: .run, seconds: 180), Segment(kind: .walk, seconds: 180),
                               Segment(kind: .run, seconds: 90), Segment(kind: .walk, seconds: 90),
                               Segment(kind: .run, seconds: 180)]))
        let w4 = same(4, "Your first 5-minute run lives here.",
                      workout([Segment(kind: .run, seconds: 180), Segment(kind: .walk, seconds: 90),
                               Segment(kind: .run, seconds: 300), Segment(kind: .walk, seconds: 150),
                               Segment(kind: .run, seconds: 180), Segment(kind: .walk, seconds: 90),
                               Segment(kind: .run, seconds: 300)]))
        let w5 = WeekPlan(number: 5, note: "Three different sessions — building to 20 minutes nonstop.",
                          sessions: [
                            workout(intervals(run: 300, walk: 180, reps: 3)),
                            workout([Segment(kind: .run, seconds: 480), Segment(kind: .walk, seconds: 300),
                                     Segment(kind: .run, seconds: 480)]),
                            workout([Segment(kind: .run, seconds: 1200)])
                          ])
        let w6 = WeekPlan(number: 6, note: "Consolidating — then 25 minutes straight.",
                          sessions: [
                            workout([Segment(kind: .run, seconds: 300), Segment(kind: .walk, seconds: 180),
                                     Segment(kind: .run, seconds: 480), Segment(kind: .walk, seconds: 180),
                                     Segment(kind: .run, seconds: 300)]),
                            workout([Segment(kind: .run, seconds: 600), Segment(kind: .walk, seconds: 180),
                                     Segment(kind: .run, seconds: 600)]),
                            workout([Segment(kind: .run, seconds: 1500)])
                          ])
        let w7 = same(7, "Settle into a steady 25-minute run.",
                      workout([Segment(kind: .run, seconds: 1500)]))
        let w8 = same(8, "Stretching it out to 28 minutes.",
                      workout([Segment(kind: .run, seconds: 1680)]))
        let w9 = same(9, "The finish line: 30 minutes, you're a runner.",
                      workout([Segment(kind: .run, seconds: 1800)]))
        return RunPlan(id: "c25k", name: "Couch to 5K",
                       subtitle: "9 weeks · 3 runs a week",
                       blurb: "The classic run-walk plan that has made millions of people into runners. Three sessions a week, building from 60-second jogs to a full 30-minute run.",
                       weeks: [w1, w2, w3, w4, w5, w6, w7, w8, w9])
    }()

    // MARK: Easy Start (gentler 8-week ramp)

    static let easyStart: RunPlan = {
        func w(_ n: Int, _ note: String, run: Int, walk: Int, reps: Int) -> WeekPlan {
            same(n, note, workout(intervals(run: run, walk: walk, reps: reps)))
        }
        return RunPlan(id: "easy", name: "Easy Start",
                       subtitle: "8 weeks · gentle ramp",
                       blurb: "Most beginners quit Couch to 5K at the week-2 jump. Easy Start ramps up in smaller steps — 30-second jogs to begin — so the plan grows with you instead of ahead of you.",
                       weeks: [
                        w(1, "Tiny jogs, long walks. Just show up.", run: 30, walk: 90, reps: 10),
                        w(2, "A few more seconds of jogging.", run: 45, walk: 90, reps: 8),
                        w(3, "One full minute at a time.", run: 60, walk: 90, reps: 8),
                        w(4, "Run and walk now match.", run: 90, walk: 90, reps: 6),
                        w(5, "Two-minute runs — you've got this.", run: 120, walk: 90, reps: 5),
                        w(6, "Three minutes, shorter recoveries.", run: 180, walk: 90, reps: 4),
                        w(7, "Five-minute runs, twice the confidence.", run: 300, walk: 120, reps: 3),
                        w(8, "Bridging to a continuous run.", run: 600, walk: 180, reps: 2)
                       ])
    }()
}
