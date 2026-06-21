import Foundation
import SwiftData

@Model
final class PuzzleRecord {
    var date: Date
    var category: String
    var difficulty: String
    var wordsFound: Int
    var totalWords: Int
    var timeSeconds: Int
    var completed: Bool

    init(date: Date = .now, category: String, difficulty: String,
         wordsFound: Int, totalWords: Int, timeSeconds: Int, completed: Bool) {
        self.date = date
        self.category = category
        self.difficulty = difficulty
        self.wordsFound = wordsFound
        self.totalWords = totalWords
        self.timeSeconds = timeSeconds
        self.completed = completed
    }

    var formattedTime: String {
        let m = timeSeconds / 60
        let s = timeSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

@Model
final class SeekSettings {
    var hasCompletedOnboarding: Bool
    var preferredDifficulty: String
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var showTimer: Bool
    var isPro: Bool
    var colorScheme: String

    init() {
        self.hasCompletedOnboarding = false
        self.preferredDifficulty = PuzzleDifficulty.medium.rawValue
        self.soundEnabled = true
        self.hapticsEnabled = true
        self.showTimer = true
        self.isPro = false
        self.colorScheme = "Ocean"
    }
}

struct GridCell: Identifiable, Hashable {
    let id: Int
    let row: Int
    let col: Int
    var letter: Character
    var foundWordIndex: Int? = nil
    var isSelected: Bool = false
}

struct PlacedWord {
    let word: String
    let startRow: Int
    let startCol: Int
    let direction: Direction
    var isFound: Bool = false
    var foundColorIndex: Int = 0

    var cells: [(row: Int, col: Int)] {
        var result: [(Int, Int)] = []
        let (dr, dc) = direction.delta
        for i in 0..<word.count {
            result.append((startRow + dr * i, startCol + dc * i))
        }
        return result
    }
}

enum Direction: CaseIterable {
    case right, down, diagonal, leftDiag, up, left, upLeft, upRight

    var delta: (Int, Int) {
        switch self {
        case .right: return (0, 1)
        case .down: return (1, 0)
        case .diagonal: return (1, 1)
        case .leftDiag: return (1, -1)
        case .up: return (-1, 0)
        case .left: return (0, -1)
        case .upLeft: return (-1, -1)
        case .upRight: return (-1, 1)
        }
    }
}

struct PuzzleState {
    var grid: [[Character]]
    var placedWords: [PlacedWord]
    let size: Int
    let category: WordCategory
    let difficulty: PuzzleDifficulty

    var foundCount: Int { placedWords.filter { $0.isFound }.count }
    var isComplete: Bool { foundCount == placedWords.count }

    init(category: WordCategory, difficulty: PuzzleDifficulty) {
        self.category = category
        self.difficulty = difficulty
        self.size = difficulty.gridSize
        var g = Array(repeating: Array(repeating: Character(" "), count: difficulty.gridSize), count: difficulty.gridSize)
        var placed: [PlacedWord] = []

        let wordList = category.words.shuffled().prefix(difficulty.wordCount).map { $0.uppercased() }
        for word in wordList {
            if let pw = PuzzleState.placeWord(word, in: &g, size: difficulty.gridSize) {
                placed.append(pw)
            }
        }
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for r in 0..<difficulty.gridSize {
            for c in 0..<difficulty.gridSize {
                if g[r][c] == Character(" ") {
                    g[r][c] = letters.randomElement()!
                }
            }
        }
        self.grid = g
        self.placedWords = placed
    }

    static func placeWord(_ word: String, in grid: inout [[Character]], size: Int) -> PlacedWord? {
        let chars = Array(word)
        let directions = Direction.allCases.shuffled()
        for _ in 0..<100 {
            let dir = directions.randomElement()!
            let (dr, dc) = dir.delta
            let maxR = size - 1
            let maxC = size - 1
            let len = chars.count - 1
            let minR = max(0, -dr * len)
            let maxStartR = min(maxR, maxR - dr * len)
            let minC = max(0, -dc * len)
            let maxStartC = min(maxC, maxC - dc * len)
            guard minR <= maxStartR, minC <= maxStartC else { continue }
            let r0 = Int.random(in: minR...maxStartR)
            let c0 = Int.random(in: minC...maxStartC)
            var canPlace = true
            for i in 0..<chars.count {
                let r = r0 + dr * i
                let c = c0 + dc * i
                if grid[r][c] != Character(" ") && grid[r][c] != chars[i] {
                    canPlace = false; break
                }
            }
            if canPlace {
                for i in 0..<chars.count {
                    grid[r0 + dr * i][c0 + dc * i] = chars[i]
                }
                return PlacedWord(word: word, startRow: r0, startCol: c0, direction: dir)
            }
        }
        return nil
    }
}
