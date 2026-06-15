import Foundation

/// The bundled, static catalog of guided eye-exercise routines.
/// Pure value data — no persistence. Routines and exercises are deterministic and stable.
enum RoutineCatalog {

    /// The single starter routine that is always free. Everything else is Pro-gated.
    static let freeRoutineID = "relax-soft-reset"

    static let routines: [EyeRoutine] = [
        // MARK: - Relax (free starter)
        EyeRoutine(
            id: freeRoutineID,
            name: "Soft Reset",
            summary: "A gentle two-minute wind-down for tired, tense eyes.",
            exercises: [
                EyeExercise(id: "sr-1", name: "Slow Blinks",
                            instruction: "Blink slowly and fully. Close, hold for a beat, then open. Let your eyes moisten.",
                            seconds: 25, type: .blinking),
                EyeExercise(id: "sr-2", name: "Side to Side",
                            instruction: "Keep your head still and sweep your gaze gently left, then right.",
                            seconds: 25, type: .focusShift),
                EyeExercise(id: "sr-3", name: "Palming Rest",
                            instruction: "Cup your palms over closed eyes. Rest in the warm dark and breathe.",
                            seconds: 35, type: .palming),
                EyeExercise(id: "sr-4", name: "One More Blink",
                            instruction: "Finish with a few more slow, deliberate blinks to settle your eyes.",
                            seconds: 20, type: .blinking)
            ],
            category: .relax
        ),

        // MARK: - Relax (Pro)
        EyeRoutine(
            id: "relax-deep-calm",
            name: "Deep Calm",
            summary: "A longer restful sequence to fully release eye strain.",
            exercises: [
                EyeExercise(id: "dc-1", name: "Settle In",
                            instruction: "Soften your gaze on a far, neutral point. Let your shoulders drop.",
                            seconds: 25, type: .focusShift),
                EyeExercise(id: "dc-2", name: "Slow Blinks",
                            instruction: "Blink slowly and fully, letting each blink spread a fresh tear film.",
                            seconds: 30, type: .blinking),
                EyeExercise(id: "dc-3", name: "Gentle Circles",
                            instruction: "Roll your gaze slowly in a wide circle, then reverse direction.",
                            seconds: 30, type: .rolling),
                EyeExercise(id: "dc-4", name: "Palming Rest",
                            instruction: "Cup your palms over closed eyes and rest in the dark for a full minute.",
                            seconds: 45, type: .palming),
                EyeExercise(id: "dc-5", name: "Ease Out",
                            instruction: "Open slowly, blink a few times, and return to a soft, far focus.",
                            seconds: 20, type: .blinking)
            ],
            category: .relax
        ),

        // MARK: - Strengthen (Pro)
        EyeRoutine(
            id: "strengthen-muscle-tune",
            name: "Muscle Tune",
            summary: "Train the small muscles that aim and move your eyes.",
            exercises: [
                EyeExercise(id: "mt-1", name: "Horizontal Sweeps",
                            instruction: "Move your eyes smoothly side to side, reaching a little further each time.",
                            seconds: 30, type: .focusShift),
                EyeExercise(id: "mt-2", name: "Figure Eight",
                            instruction: "Trace a slow, large figure-eight with your eyes. Keep it smooth.",
                            seconds: 35, type: .figure8),
                EyeExercise(id: "mt-3", name: "Wide Circles",
                            instruction: "Roll your gaze in a big circle one way, then the other.",
                            seconds: 30, type: .rolling),
                EyeExercise(id: "mt-4", name: "Figure Eight Reverse",
                            instruction: "Trace the figure-eight again, the opposite direction.",
                            seconds: 35, type: .figure8),
                EyeExercise(id: "mt-5", name: "Cool Down",
                            instruction: "Close your eyes and rest. Let the muscles relax.",
                            seconds: 25, type: .palming)
            ],
            category: .strengthen
        ),

        // MARK: - Focus (Pro)
        EyeRoutine(
            id: "focus-near-far",
            name: "Near & Far",
            summary: "Sharpen the focusing flexibility that screens dull.",
            exercises: [
                EyeExercise(id: "nf-1", name: "Thumb Focus",
                            instruction: "Hold your thumb up close and focus on it sharply.",
                            seconds: 20, type: .nearFar),
                EyeExercise(id: "nf-2", name: "Far Focus",
                            instruction: "Now shift to a distant point and let it come into focus.",
                            seconds: 20, type: .nearFar),
                EyeExercise(id: "nf-3", name: "Near to Far",
                            instruction: "Alternate smoothly between thumb and distance, pausing on each.",
                            seconds: 35, type: .nearFar),
                EyeExercise(id: "nf-4", name: "Quick Shifts",
                            instruction: "Pick two points and flick focus between them, near then far.",
                            seconds: 30, type: .focusShift),
                EyeExercise(id: "nf-5", name: "Settle",
                            instruction: "Rest your gaze far away and blink slowly to finish.",
                            seconds: 20, type: .blinking)
            ],
            category: .focus
        ),

        // MARK: - Dry Eye (Pro)
        EyeRoutine(
            id: "dryeye-moisture",
            name: "Moisture Reset",
            summary: "Restore a healthy blink rhythm and ease dryness.",
            exercises: [
                EyeExercise(id: "me-1", name: "Full Blinks",
                            instruction: "Blink fully and completely — many screen blinks are partial.",
                            seconds: 30, type: .blinking),
                EyeExercise(id: "me-2", name: "Squeeze & Release",
                            instruction: "Gently close your eyes tight for a moment, then release softly.",
                            seconds: 25, type: .blinking),
                EyeExercise(id: "me-3", name: "Palming Warmth",
                            instruction: "Cup warm palms over closed eyes to soothe the lids.",
                            seconds: 35, type: .palming),
                EyeExercise(id: "me-4", name: "Slow Blink Rhythm",
                            instruction: "Find a calm, steady blinking rhythm and keep it going.",
                            seconds: 30, type: .blinking)
            ],
            category: .dryEye
        ),

        // MARK: - Focus (Pro, short)
        EyeRoutine(
            id: "focus-screen-break",
            name: "Screen Break Plus",
            summary: "A quick focus-shifting reset between work blocks.",
            exercises: [
                EyeExercise(id: "sb-1", name: "Look Away",
                            instruction: "Lift your eyes to the farthest point you can see and hold.",
                            seconds: 20, type: .nearFar),
                EyeExercise(id: "sb-2", name: "Side Sweeps",
                            instruction: "Sweep your gaze gently left and right a few times.",
                            seconds: 25, type: .focusShift),
                EyeExercise(id: "sb-3", name: "Near & Far",
                            instruction: "Alternate focus between something close and something far.",
                            seconds: 30, type: .nearFar),
                EyeExercise(id: "sb-4", name: "Blink Finish",
                            instruction: "Close with slow, full blinks before returning to your screen.",
                            seconds: 20, type: .blinking)
            ],
            category: .focus
        )
    ]

    static func routine(id: String) -> EyeRoutine? {
        routines.first { $0.id == id }
    }

    static func isFree(_ routine: EyeRoutine) -> Bool {
        routine.id == freeRoutineID
    }

    static var freeRoutine: EyeRoutine? {
        routine(id: freeRoutineID)
    }

    static func routines(in category: RoutineCategory) -> [EyeRoutine] {
        routines.filter { $0.category == category }
    }

    /// A simple recommendation: rotate the recommended routine by day-of-year for variety.
    static func recommended(for date: Date = .now) -> EyeRoutine {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        let list = routines
        guard !list.isEmpty else {
            // Unreachable: catalog is non-empty by construction; safe fallback avoids force-unwrap.
            return EyeRoutine(id: "empty", name: "Soft Reset", summary: "", exercises: [], category: .relax)
        }
        return list[day % list.count]
    }
}
