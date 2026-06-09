import Foundation

/// One discrete step in a guided session: a count-in, an exercise (optionally a
/// single side), a rest, or the final "done" marker. `durationSec == 0` means the
/// step is rep-based and waits for the user to tap "Done".
struct WorkoutStep: Identifiable {
    enum StepKind {
        case countIn
        case exercise
        case restExercise
        case restRound
        case done
    }

    let id = UUID()
    var kind: StepKind
    var title: String
    var subtitle: String
    var durationSec: Int        // 0 = manual / rep-based
    var isTimed: Bool
    var roundIndex: Int         // 0-based; for `done`/`countIn` this is the last/first round
    var totalRounds: Int

    var symbol: String

    var isRest: Bool { kind == .restExercise || kind == .restRound }
}

/// Pure expansion of a `Workout` into an ordered list of steps the player walks
/// through, plus a duration estimate. No state, no side effects.
enum WorkoutEngine {

    /// Builds the full ordered sequence for a workout.
    /// countIn → for each round { for each item { exercise (+ per-side split),
    /// restExercise between items } restRound between rounds } → done.
    static func steps(for workout: Workout, countInSeconds: Int) -> [WorkoutStep] {
        let items = workout.orderedItems
        let rounds = max(1, workout.rounds)
        let total = rounds
        var out: [WorkoutStep] = []

        if items.isEmpty {
            out.append(WorkoutStep(kind: .done, title: "Done", subtitle: "Add some moves first",
                                   durationSec: 0, isTimed: false, roundIndex: 0,
                                   totalRounds: total, symbol: "checkmark.circle.fill"))
            return out
        }

        let countIn = max(0, countInSeconds)
        if countIn > 0 {
            out.append(WorkoutStep(kind: .countIn, title: "Get ready",
                                   subtitle: "Starting \(items.first?.exerciseName ?? "soon")",
                                   durationSec: countIn, isTimed: true, roundIndex: 0,
                                   totalRounds: total, symbol: "hourglass"))
        }

        for round in 0..<rounds {
            for (itemIdx, item) in items.enumerated() {
                appendExercise(item, round: round, total: total, into: &out)

                let isLastItem = itemIdx == items.count - 1
                if !isLastItem, workout.restBetweenExercisesSec > 0 {
                    let next = items[itemIdx + 1].exerciseName
                    out.append(WorkoutStep(kind: .restExercise, title: "Rest",
                                           subtitle: "Next: \(next)",
                                           durationSec: workout.restBetweenExercisesSec,
                                           isTimed: true, roundIndex: round,
                                           totalRounds: total, symbol: "pause.circle"))
                }
            }

            let isLastRound = round == rounds - 1
            if !isLastRound, workout.restBetweenRoundsSec > 0 {
                out.append(WorkoutStep(kind: .restRound, title: "Round rest",
                                       subtitle: "Round \(round + 2) of \(total) next",
                                       durationSec: workout.restBetweenRoundsSec,
                                       isTimed: true, roundIndex: round,
                                       totalRounds: total, symbol: "figure.cooldown"))
            }
        }

        out.append(WorkoutStep(kind: .done, title: "Workout complete",
                               subtitle: "Nice work", durationSec: 0, isTimed: false,
                               roundIndex: rounds - 1, totalRounds: total,
                               symbol: "checkmark.circle.fill"))
        return out
    }

    private static func appendExercise(_ item: WorkoutItem, round: Int, total: Int,
                                       into out: inout [WorkoutStep]) {
        let timed = item.kind == .timed
        let dur = timed ? item.durationSec : 0
        let baseSub = item.kind == .reps ? "\(item.reps) reps" : "\(item.durationSec)s"

        if item.perSide {
            for side in ["Left", "Right"] {
                out.append(WorkoutStep(kind: .exercise,
                                       title: item.exerciseName,
                                       subtitle: "\(side) · \(baseSub)",
                                       durationSec: dur, isTimed: timed,
                                       roundIndex: round, totalRounds: total,
                                       symbol: item.symbol))
            }
        } else {
            out.append(WorkoutStep(kind: .exercise,
                                   title: item.exerciseName,
                                   subtitle: baseSub,
                                   durationSec: dur, isTimed: timed,
                                   roundIndex: round, totalRounds: total,
                                   symbol: item.symbol))
        }
    }

    /// Rough total time. Rep-based moves are estimated at ~3s per rep so the
    /// "~N min" estimate is meaningful even though they aren't strictly timed.
    static func estimatedSeconds(for workout: Workout) -> Int {
        let items = workout.orderedItems
        guard !items.isEmpty else { return 0 }
        let rounds = max(1, workout.rounds)

        var perRound = 0
        for item in items {
            let sides = item.perSide ? 2 : 1
            switch item.kind {
            case .timed: perRound += item.durationSec * sides
            case .reps:  perRound += Int(Double(item.reps) * 3.0) * sides
            }
        }
        // Rest between exercises within a round (count of gaps = items - 1).
        perRound += max(0, items.count - 1) * workout.restBetweenExercisesSec

        var total = perRound * rounds
        // Rest between rounds (count of gaps = rounds - 1).
        total += max(0, rounds - 1) * workout.restBetweenRoundsSec
        return total
    }
}
