import SwiftUI

/// The animated target style an exercise asks the eyes to follow.
/// Each style has a Reduce-Motion-safe static fallback in the player.
enum ExerciseType: String, Codable {
    case focusShift   // shift focus between two on-screen points
    case nearFar      // alternate near (thumb) and far focus
    case palming      // cover eyes, rest in darkness
    case figure8      // trace a slow figure-eight with the eyes
    case blinking     // slow, full, deliberate blinks
    case rolling      // roll the gaze in a circle

    var symbol: String {
        switch self {
        case .focusShift: return "arrow.left.and.right.circle"
        case .nearFar: return "arrow.up.left.and.down.right.magnifyingglass"
        case .palming: return "hand.raised"
        case .figure8: return "infinity"
        case .blinking: return "eye"
        case .rolling: return "arrow.clockwise.circle"
        }
    }

    /// Short text guidance shown both in normal mode and as the Reduce-Motion fallback.
    var motionFreeCue: String {
        switch self {
        case .focusShift: return "Gently shift your gaze left, then right, in slow even sweeps."
        case .nearFar: return "Focus on your thumb up close, then a point across the room. Alternate slowly."
        case .palming: return "Rest your palms gently over closed eyes and breathe in the warm dark."
        case .figure8: return "Imagine a large figure-eight and trace it slowly with your eyes."
        case .blinking: return "Blink slowly and fully — close, hold a beat, open. Let your eyes moisten."
        case .rolling: return "Slowly roll your gaze in a wide circle, one direction then the other."
        }
    }
}

/// A single timed eye exercise within a routine. Pure value type from the bundled catalog.
struct EyeExercise: Identifiable, Hashable {
    let id: String
    let name: String
    let instruction: String
    let seconds: Int
    let type: ExerciseType
}

/// The mood/goal a routine serves.
enum RoutineCategory: String, CaseIterable, Identifiable {
    case relax = "Relax"
    case strengthen = "Strengthen"
    case focus = "Focus"
    case dryEye = "Dry Eye"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .relax: return "leaf"
        case .strengthen: return "dumbbell"
        case .focus: return "scope"
        case .dryEye: return "drop"
        }
    }

    var blurb: String {
        switch self {
        case .relax: return "Wind down tired, tense eyes."
        case .strengthen: return "Train the muscles that aim and focus."
        case .focus: return "Sharpen near-to-far flexibility."
        case .dryEye: return "Restore moisture and blink rhythm."
        }
    }
}

/// A grouped, ordered set of exercises.
struct EyeRoutine: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let exercises: [EyeExercise]
    let category: RoutineCategory

    /// Total guided time across all exercises (guarded — empty routines return 0).
    var totalSeconds: Int {
        exercises.reduce(0) { $0 + max(0, $1.seconds) }
    }

    var totalMinutesLabel: String {
        let m = Double(totalSeconds) / 60.0
        if m < 1 { return "\(totalSeconds)s" }
        return String(format: "%.0f min", m.rounded())
    }
}
