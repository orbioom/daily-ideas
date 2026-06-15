import SwiftUI

/// One-time "Quill Pro" unlock. Simulated locally via `@AppStorage("isPro")`.
/// In production this would be backed by StoreKit 2 (a non-consumable product).
enum Pro {
    /// Display price for the one-time unlock.
    static let priceLabel = "$5.99"

    /// Free tier may hold at most this many notebooks.
    static let freeNotebookLimit = 3

    /// Whether creating another notebook is allowed for a free user.
    static func canCreateNotebook(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeNotebookLimit
    }

    /// Whether folders are available.
    static func foldersUnlocked(isPro: Bool) -> Bool { isPro }

    /// Whether PDF export is available.
    static func exportUnlocked(isPro: Bool) -> Bool { isPro }

    /// The benefits list shown on the paywall.
    static let benefits: [(symbol: String, title: String, detail: String)] = [
        ("books.vertical.fill", "Unlimited notebooks", "Create as many notebooks and pages as you like."),
        ("square.grid.3x3.fill", "Every paper template", "Grid and dotted paper, alongside blank and ruled."),
        ("paintpalette.fill", "Full color palette", "The complete set of ink and cover colors."),
        ("folder.fill", "Folders", "Organize notebooks into colored folders."),
        ("square.and.arrow.up.fill", "PDF export", "Export any notebook to a shareable PDF.")
    ]
}

/// Why the paywall was presented — drives tailored copy.
enum PaywallReason: Identifiable {
    case notebookLimit
    case lockedTemplate(PaperTemplate)
    case lockedColor
    case folders
    case export
    case general

    var id: String {
        switch self {
        case .notebookLimit: return "notebookLimit"
        case .lockedTemplate(let t): return "template-\(t.rawValue)"
        case .lockedColor: return "lockedColor"
        case .folders: return "folders"
        case .export: return "export"
        case .general: return "general"
        }
    }

    var headline: String {
        switch self {
        case .notebookLimit: return "Room for every idea"
        case .lockedTemplate: return "Unlock all paper"
        case .lockedColor: return "The full palette"
        case .folders: return "Stay organized"
        case .export: return "Share as PDF"
        case .general: return "Quill Pro"
        }
    }

    var message: String {
        switch self {
        case .notebookLimit:
            return "You've reached the free limit of \(Pro.freeNotebookLimit) notebooks. Quill Pro unlocks unlimited notebooks and pages."
        case .lockedTemplate(let t):
            return "\(t.title) paper is part of Quill Pro, along with every other template and the full toolkit."
        case .lockedColor:
            return "This color is part of Quill Pro's full ink and cover palette."
        case .folders:
            return "Folders are part of Quill Pro. Group notebooks by subject, project, or mood."
        case .export:
            return "PDF export is part of Quill Pro. Turn any notebook into a polished, shareable document."
        case .general:
            return "A one-time purchase. No subscription, no account, no ads — Quill is yours for good."
        }
    }
}
