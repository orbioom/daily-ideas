import SwiftUI
import SwiftData

// MARK: - Difficulty
enum PuzzleDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case expert       = "Expert"

    var id: String { rawValue }

    var gridSize: Int {
        switch self {
        case .beginner:     return 4
        case .intermediate: return 6
        case .expert:       return 9
        }
    }

    var pieceCount: Int { gridSize * gridSize }

    var label: String { rawValue }
    var emoji: String {
        switch self {
        case .beginner:     return "🟢"
        case .intermediate: return "🟡"
        case .expert:       return "🔴"
        }
    }
}

// MARK: - Artwork Style
enum PuzzleArtStyle: String, Codable, CaseIterable, Identifiable {
    case mountainSunset  = "mountainSunset"
    case oceanWaves      = "oceanWaves"
    case geometricGrid   = "geometricGrid"
    case aurora          = "aurora"
    case floralMandala   = "floralMandala"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mountainSunset: return "Mountain Sunset"
        case .oceanWaves:     return "Ocean Waves"
        case .geometricGrid:  return "Geometric Grid"
        case .aurora:         return "Northern Lights"
        case .floralMandala:  return "Floral Mandala"
        }
    }

    var isPro: Bool {
        switch self {
        case .mountainSunset, .oceanWaves, .geometricGrid: return false
        case .aurora, .floralMandala:                       return true
        }
    }

    var accentColor: Color {
        switch self {
        case .mountainSunset: return Color(hue:0.07, saturation:0.85, brightness:0.95)
        case .oceanWaves:     return Color(hue:0.60, saturation:0.70, brightness:0.85)
        case .geometricGrid:  return Color(hue:0.30, saturation:0.70, brightness:0.65)
        case .aurora:         return Color(hue:0.40, saturation:0.75, brightness:0.75)
        case .floralMandala:  return Color(hue:0.83, saturation:0.80, brightness:0.80)
        }
    }
}

// MARK: - In-memory piece
struct PuzzlePiece: Identifiable, Equatable {
    let id: UUID
    let correctRow: Int
    let correctCol: Int
}

// MARK: - SwiftData persistence
@Model
final class PuzzleSave {
    var puzzleStyleId: String
    var difficultyId: String
    var startDate: Date
    var elapsedSeconds: Int
    // JSON-encoded [UUID: Bool] (id -> isPlaced)
    var placedIdsData: Data
    // JSON-encoded scramble order [(id,row,col)]
    var pieceOrderData: Data

    init(style: PuzzleArtStyle, difficulty: PuzzleDifficulty, pieces: [PuzzlePiece]) {
        self.puzzleStyleId  = style.rawValue
        self.difficultyId   = difficulty.rawValue
        self.startDate      = .now
        self.elapsedSeconds = 0
        self.placedIdsData  = (try? JSONEncoder().encode([String: Bool]())) ?? Data()
        let orderList = pieces.map { PieceRecord(id: $0.id.uuidString, row: $0.correctRow, col: $0.correctCol) }
        self.pieceOrderData = (try? JSONEncoder().encode(orderList)) ?? Data()
    }

    func decodeOrder() -> [PuzzlePiece] {
        guard let list = try? JSONDecoder().decode([PieceRecord].self, from: pieceOrderData) else { return [] }
        return list.compactMap { r in
            guard let uid = UUID(uuidString: r.id) else { return nil }
            return PuzzlePiece(id: uid, correctRow: r.row, correctCol: r.col)
        }
    }

    func decodePlaced() -> Set<UUID> {
        guard let dict = try? JSONDecoder().decode([String: Bool].self, from: placedIdsData) else { return [] }
        return Set(dict.compactMap { UUID(uuidString: $0.key) })
    }

    func encodePlaced(_ set: Set<UUID>) {
        var dict = [String: Bool]()
        for id in set { dict[id.uuidString] = true }
        placedIdsData = (try? JSONEncoder().encode(dict)) ?? Data()
    }

    struct PieceRecord: Codable {
        let id: String
        let row: Int
        let col: Int
    }
}

@Model
final class PuzzleResult {
    var puzzleStyleId: String
    var difficultyId: String
    var completedDate: Date
    var elapsedSeconds: Int

    init(style: PuzzleArtStyle, difficulty: PuzzleDifficulty, elapsedSeconds: Int) {
        self.puzzleStyleId  = style.rawValue
        self.difficultyId   = difficulty.rawValue
        self.completedDate  = .now
        self.elapsedSeconds = elapsedSeconds
    }

    var styleName: String {
        PuzzleArtStyle(rawValue: puzzleStyleId)?.title ?? puzzleStyleId
    }
    var difficulty: PuzzleDifficulty {
        PuzzleDifficulty(rawValue: difficultyId) ?? .beginner
    }
    var elapsedFormatted: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
