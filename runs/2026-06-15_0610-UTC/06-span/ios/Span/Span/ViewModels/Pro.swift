import Foundation

/// Free-tier limits and Pro gating. Free: the full life grid, all stats, and up to 3 chapters.
/// Pro (one-time) unlocks unlimited chapters/milestones/goals, premium palettes & dot styles,
/// and the high-res poster export.
enum Pro {
    static let priceLabel = "$3.99"

    /// Free users may keep this many chapters; Pro is unlimited.
    static let freeChapterLimit = 3
    /// Free users may keep this many milestones; Pro is unlimited.
    static let freeMilestoneLimit = 3
    /// Free users may keep this many future goals; Pro is unlimited.
    static let freeGoalLimit = 2

    static func canAddChapter(count: Int, isPro: Bool) -> Bool {
        isPro || count < freeChapterLimit
    }

    static func canAddMilestone(count: Int, isPro: Bool) -> Bool {
        isPro || count < freeMilestoneLimit
    }

    static func canAddGoal(count: Int, isPro: Bool) -> Bool {
        isPro || count < freeGoalLimit
    }
}

/// Reasons the paywall is presented — drives its headline & copy.
enum PaywallReason: Identifiable {
    case chapters
    case milestones
    case goals
    case palettes
    case poster
    case general

    var id: String {
        switch self {
        case .chapters: return "chapters"
        case .milestones: return "milestones"
        case .goals: return "goals"
        case .palettes: return "palettes"
        case .poster: return "poster"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .chapters: return "Color your whole life"
        case .milestones: return "Pin every milestone"
        case .goals: return "Count down to anything"
        case .palettes: return "Unlock premium palettes"
        case .poster: return "Export your life poster"
        case .general: return "Unlock Span Pro"
        }
    }

    var blurb: String {
        switch self {
        case .chapters:
            return "Free Span includes \(Pro.freeChapterLimit) chapters. Go Pro to map every era of your life — childhood, cities, careers, and all the ones still ahead."
        case .milestones:
            return "Free Span pins \(Pro.freeMilestoneLimit) milestones. Pro lets you mark every moment that mattered, on the exact week it happened."
        case .goals:
            return "Free Span tracks \(Pro.freeGoalLimit) future goals. Pro gives you unlimited live countdowns to the moments you're waiting for."
        case .palettes:
            return "Span Pro adds hand-tuned color palettes — Dusk, Garden, and Tide — so your chapters look exactly how you imagine them."
        case .poster:
            return "Span Pro renders your life calendar into a gorgeous, high-resolution poster you can save and share."
        case .general:
            return "One purchase unlocks unlimited chapters, milestones and goals, every premium palette and dot style, and the shareable life poster."
        }
    }

    var symbol: String {
        switch self {
        case .chapters: return "paintpalette.fill"
        case .milestones: return "mappin.and.ellipse"
        case .goals: return "hourglass"
        case .palettes: return "swatchpalette.fill"
        case .poster: return "square.and.arrow.up.on.square.fill"
        case .general: return "crown.fill"
        }
    }
}
