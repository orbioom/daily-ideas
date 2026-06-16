import SwiftUI

/// Starter column layouts offered when creating a board.
enum BoardTemplate: String, CaseIterable, Identifiable {
    case todoDoingDone
    case kanban
    case sprint
    case contentCalendar
    case blank

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todoDoingDone: return "To-Do · Doing · Done"
        case .kanban: return "Kanban"
        case .sprint: return "Sprint"
        case .contentCalendar: return "Content Calendar"
        case .blank: return "Blank"
        }
    }

    var subtitle: String {
        switch self {
        case .todoDoingDone: return "The classic three-lane flow"
        case .kanban: return "Backlog · Ready · In Progress · Review · Done"
        case .sprint: return "Plan a focused two-week push"
        case .contentCalendar: return "Idea · Drafting · Editing · Scheduled · Published"
        case .blank: return "Start with a single empty lane"
        }
    }

    var symbol: String {
        switch self {
        case .todoDoingDone: return "checklist"
        case .kanban: return "rectangle.split.3x1"
        case .sprint: return "bolt.fill"
        case .contentCalendar: return "calendar"
        case .blank: return "rectangle.dashed"
        }
    }

    /// Column names + WIP limits for each template. WIP limits are only applied
    /// when the user is Pro (handled at creation time).
    var columns: [(name: String, wip: Int)] {
        switch self {
        case .todoDoingDone:
            return [("To-Do", 0), ("Doing", 3), ("Done", 0)]
        case .kanban:
            return [("Backlog", 0), ("Ready", 0), ("In Progress", 3), ("Review", 2), ("Done", 0)]
        case .sprint:
            return [("Sprint Backlog", 0), ("In Progress", 4), ("Testing", 2), ("Done", 0)]
        case .contentCalendar:
            return [("Idea", 0), ("Drafting", 0), ("Editing", 2), ("Scheduled", 0), ("Published", 0)]
        case .blank:
            return [("To-Do", 0)]
        }
    }
}

/// Curated palette + SF Symbols used for boards, columns and labels so the app
/// stays cohesive without a free-form color picker dependency.
enum Palette {
    static let boardColors: [Int] = [
        0x2D7FF9, 0x6B5BFF, 0xE0529C, 0xF0663B,
        0xF5B845, 0x18A957, 0x00B0C7, 0x8E5BD9
    ]

    static let labelColors: [Int] = [
        0xD23B3B, 0xF0663B, 0xF5B845, 0x18A957,
        0x00B0C7, 0x2D7FF9, 0x6B5BFF, 0xE0529C, 0x5A6473
    ]

    static let columnColors: [Int] = [
        0x8E97A6, 0x2D7FF9, 0xF5B845, 0x6B5BFF, 0x18A957
    ]

    static let boardSymbols: [String] = [
        "square.stack.3d.up.fill", "briefcase.fill", "house.fill",
        "paintpalette.fill", "cart.fill", "book.fill",
        "airplane", "leaf.fill", "hammer.fill", "graduationcap.fill",
        "heart.fill", "gamecontroller.fill"
    ]
}
