import SwiftData
import Foundation

// A color-by-number puzzle definition (baked-in, not user-created)
struct PuzzleDefinition: Identifiable, Sendable {
    let id: Int
    let title: String
    let category: PuzzleCategory
    let gridWidth: Int
    let gridHeight: Int
    // Flat array: row-major, value 0 = background (no paint), 1...N = palette index
    let cells: [Int]
    // Hex strings for each palette entry (index 0 = color #1)
    let palette: [String]

    func cell(row: Int, col: Int) -> Int {
        guard row >= 0, row < gridHeight, col >= 0, col < gridWidth else { return 0 }
        return cells[row * gridWidth + col]
    }
}

enum PuzzleCategory: String, CaseIterable, Codable {
    case animals = "Animals"
    case nature = "Nature"
    case food = "Food"
    case objects = "Objects"
    case patterns = "Patterns"

    var icon: String {
        switch self {
        case .animals: return "pawprint.fill"
        case .nature: return "leaf.fill"
        case .food: return "fork.knife"
        case .objects: return "star.fill"
        case .patterns: return "square.grid.3x3.fill"
        }
    }
}

@Model
final class PuzzleProgress {
    var puzzleId: Int
    // JSON-encoded [Int] — same flat layout as PuzzleDefinition.cells, but 0=not-painted
    var paintedCellsJSON: Data
    var isCompleted: Bool
    var startedAt: Date
    var completedAt: Date?
    var timeSpentSeconds: Int

    init(puzzleId: Int, cellCount: Int) {
        self.puzzleId = puzzleId
        let empty = [Int](repeating: 0, count: cellCount)
        self.paintedCellsJSON = (try? JSONEncoder().encode(empty)) ?? Data()
        self.isCompleted = false
        self.startedAt = Date()
        self.completedAt = nil
        self.timeSpentSeconds = 0
    }

    var paintedCells: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: paintedCellsJSON)) ?? [] }
        set { paintedCellsJSON = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}

@Model
final class DaubSettings {
    var id: UUID
    var hasSeenOnboarding: Bool
    var hapticsEnabled: Bool
    var showNumbers: Bool
    var highlightSelected: Bool

    init() {
        self.id = UUID()
        self.hasSeenOnboarding = false
        self.hapticsEnabled = true
        self.showNumbers = true
        self.highlightSelected = true
    }
}
