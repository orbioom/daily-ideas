import SwiftUI

/// The state of a ladder rung relative to the user's current position.
enum LevelState {
    case cleared    // below current level
    case current    // the level being trained
    case upcoming   // above current, reachable
    case locked     // Pro-gated and not unlocked

    var color: Color {
        switch self {
        case .cleared: return Theme.good
        case .current: return Theme.accent
        case .upcoming: return Theme.inkFaint
        case .locked: return Theme.inkFaint
        }
    }
    var icon: String {
        switch self {
        case .cleared: return "checkmark.circle.fill"
        case .current: return "location.circle.fill"
        case .upcoming: return "circle"
        case .locked: return "lock.fill"
        }
    }
    var label: String {
        switch self {
        case .cleared: return "Cleared"
        case .current: return "Current"
        case .upcoming: return "Upcoming"
        case .locked: return "Pro"
        }
    }
}

/// Decide a level's state for a given current position and Pro status.
func levelState(level: ProgressionLevel, currentLevel: Int, isPro: Bool) -> LevelState {
    if level.isPro && !isPro { return .locked }
    if level.index < currentLevel { return .cleared }
    if level.index == currentLevel { return .current }
    return .upcoming
}

/// A compact icon + name header for an exercise.
struct ExerciseGlyph: View {
    let exercise: Exercise
    var size: CGFloat = 40
    var body: some View {
        Image(systemName: exercise.icon)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(Theme.accent)
            .frame(width: size, height: size)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// A small "target" summary like "3 × 12 reps · 75s rest".
func targetSummary(_ exercise: Exercise, _ level: ProgressionLevel) -> String {
    "\(level.targetSets) × \(level.target) \(exercise.unit.short) · \(Fmt.duration(level.restSeconds)) rest"
}
