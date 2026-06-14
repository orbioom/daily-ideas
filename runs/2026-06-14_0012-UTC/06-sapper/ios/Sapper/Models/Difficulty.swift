import Foundation

/// The four difficulty presets. Custom carries its own dimensions via the
/// associated `BoardConfig`; the enum itself is used for labels and stats keys.
enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case beginner
    case intermediate
    case expert
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .expert: return "Expert"
        case .custom: return "Custom"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: return "9 × 9 · 10 mines"
        case .intermediate: return "16 × 16 · 40 mines"
        case .expert: return "16 × 30 · 99 mines"
        case .custom: return "Your own board"
        }
    }

    var systemImage: String {
        switch self {
        case .beginner: return "leaf"
        case .intermediate: return "flame"
        case .expert: return "bolt"
        case .custom: return "slider.horizontal.3"
        }
    }

    /// Preset config for the fixed difficulties. `custom` returns its default
    /// starting point; callers should supply explicit values for real custom games.
    var preset: BoardConfig {
        switch self {
        case .beginner: return BoardConfig(rows: 9, cols: 9, mines: 10)
        case .intermediate: return BoardConfig(rows: 16, cols: 16, mines: 40)
        case .expert: return BoardConfig(rows: 16, cols: 30, mines: 99)
        case .custom: return BoardConfig(rows: 12, cols: 12, mines: 24)
        }
    }
}

/// Board dimensions + mine count. Self-validating: clamps into legal ranges.
struct BoardConfig: Equatable, Codable {
    var rows: Int
    var cols: Int
    var mines: Int

    static let minDim = 5
    static let maxRows = 24
    static let maxCols = 30

    init(rows: Int, cols: Int, mines: Int) {
        let r = max(BoardConfig.minDim, min(BoardConfig.maxRows, rows))
        let c = max(BoardConfig.minDim, min(BoardConfig.maxCols, cols))
        self.rows = r
        self.cols = c
        // First click clears a 3×3 region, so the maximum legal mine count is
        // cells - 9. Keep at least 1 mine.
        let maxMines = max(1, r * c - 9)
        self.mines = max(1, min(maxMines, mines))
    }

    var cellCount: Int { rows * cols }
    var maxMines: Int { max(1, cellCount - 9) }

    /// Validate raw user input for a custom board without clamping, returning a
    /// human-readable reason if invalid.
    static func validationError(rows: Int, cols: Int, mines: Int) -> String? {
        if rows < minDim || rows > maxRows {
            return "Rows must be between \(minDim) and \(maxRows)."
        }
        if cols < minDim || cols > maxCols {
            return "Columns must be between \(minDim) and \(maxCols)."
        }
        let maxM = rows * cols - 9
        if mines < 1 {
            return "You need at least one mine."
        }
        if mines > maxM {
            return "Too many mines — keep it below \(maxM + 1) for this size."
        }
        return nil
    }
}
