import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$2.99"
    static let productTitle = "Tetra Pro"

    /// Free players may play the classic 4×4 board only.
    static let freeBoardSizes: [Int] = [4]
    /// Board sizes unlocked by Pro.
    static let proBoardSizes: [Int] = [5, 6]
    /// Free players get a limited number of undos per game.
    static let freeUndosPerGame = 3

    static func boardSizeIsFree(_ size: Int) -> Bool { freeBoardSizes.contains(size) }

    static let unlocks: [String] = [
        "Bigger 5×5 and 6×6 boards for longer, deeper runs",
        "Unlimited undo — never lose a game to a slip",
        "Daily Challenge archive: replay any past day's seeded board",
        "Every tile-color theme, including future drops",
        "Support a calm, ad-free, one-time-purchase game"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case biggerBoards
    case unlimitedUndo
    case dailyArchive
    case themes
    case general

    var id: String {
        switch self {
        case .biggerBoards: return "biggerBoards"
        case .unlimitedUndo: return "unlimitedUndo"
        case .dailyArchive: return "dailyArchive"
        case .themes: return "themes"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .biggerBoards: return "Unlock bigger boards"
        case .unlimitedUndo: return "Undo without limits"
        case .dailyArchive: return "Replay the Daily archive"
        case .themes: return "Unlock every theme"
        case .general: return "Unlock Tetra Pro"
        }
    }

    var message: String {
        switch self {
        case .biggerBoards:
            return "The 5×5 and 6×6 boards give your merges more room to breathe — and a far higher ceiling. They're part of Tetra Pro."
        case .unlimitedUndo:
            return "You've used your free undos for this game. Tetra Pro gives you unlimited undo so one wrong swipe never ends a great run."
        case .dailyArchive:
            return "Every day brings a new seeded board everyone plays. Pro lets you go back and replay any day you missed."
        case .themes:
            return "Unlock every tile-color theme — and all future drops — with a single one-time purchase."
        case .general:
            return "One fair, one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
