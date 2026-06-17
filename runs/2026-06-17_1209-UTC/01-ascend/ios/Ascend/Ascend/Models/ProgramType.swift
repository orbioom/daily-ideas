import Foundation

/// Shape of a training program. Stored as rawValue on `Program`.
enum ProgramType: String, CaseIterable, Identifiable, Codable {
    case linear5x5
    case pushPullLegs
    case upperLower
    case fullBody3
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .linear5x5: return "Linear 5×5"
        case .pushPullLegs: return "Push / Pull / Legs"
        case .upperLower: return "Upper / Lower"
        case .fullBody3: return "Full Body 3×"
        case .custom: return "Custom"
        }
    }

    var blurb: String {
        switch self {
        case .linear5x5: return "Two alternating full-body days, 5 sets of 5. Add weight every session."
        case .pushPullLegs: return "Push, pull, and leg days on a six-day rotation."
        case .upperLower: return "Upper- and lower-body splits, four days a week."
        case .fullBody3: return "Three balanced full-body sessions per week."
        case .custom: return "Your own days, exercises, and progression."
        }
    }

    var symbol: String {
        switch self {
        case .linear5x5: return "square.grid.2x2.fill"
        case .pushPullLegs: return "arrow.triangle.2.circlepath"
        case .upperLower: return "rectangle.split.1x2.fill"
        case .fullBody3: return "circle.grid.cross.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    /// Custom programs are a Pro feature.
    var requiresPro: Bool { self == .custom }
}
