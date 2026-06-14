import Foundation
import SwiftData

/// The single active in-progress classic game, persisted so it resumes on relaunch.
/// The grid and offered pieces are Codable values encoded to JSON strings (we never store
/// raw `[[Int]]` in SwiftData). All decode paths are guarded — a corrupt blob falls back
/// to a fresh game rather than crashing.
@Model
final class SavedGame {
    @Attribute(.unique) var id: UUID
    var gridBlob: String        // JSON of [[Int]]
    var piecesBlob: String      // JSON of [PieceDTO] — the currently-offered pieces (with nil for used)
    var score: Int
    var combo: Int
    var longestCombo: Int
    var linesCleared: Int
    var piecesPlaced: Int
    var seed: UInt64
    var batchesDealt: Int
    var modeRaw: String
    var dateKey: String
    var updatedAt: Date

    init(id: UUID = UUID(),
         gridBlob: String,
         piecesBlob: String,
         score: Int = 0,
         combo: Int = 0,
         longestCombo: Int = 0,
         linesCleared: Int = 0,
         piecesPlaced: Int = 0,
         seed: UInt64,
         batchesDealt: Int = 0,
         mode: GameMode = .classic,
         dateKey: String = "",
         updatedAt: Date = Date()) {
        self.id = id
        self.gridBlob = gridBlob
        self.piecesBlob = piecesBlob
        self.score = max(0, score)
        self.combo = max(0, combo)
        self.longestCombo = max(0, longestCombo)
        self.linesCleared = max(0, linesCleared)
        self.piecesPlaced = max(0, piecesPlaced)
        self.seed = seed
        self.batchesDealt = max(0, batchesDealt)
        self.modeRaw = mode.rawValue
        self.dateKey = dateKey
        self.updatedAt = updatedAt
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .classic }
}

/// A Codable transfer object for a single offered piece slot. `nil` cells means the slot
/// was already used this batch.
struct PieceDTO: Codable {
    var cells: [Coord]?
    var colorIndex: Int

    init(piece: Piece?) {
        if let piece {
            self.cells = piece.cells
            self.colorIndex = piece.colorIndex
        } else {
            self.cells = nil
            self.colorIndex = 0
        }
    }

    /// Rebuild a Piece, or nil for a used slot. Guards against empty cell arrays.
    func toPiece() -> Piece? {
        guard let cells, !cells.isEmpty else { return nil }
        return Piece(cells: cells, colorIndex: colorIndex)
    }
}

/// Codec helpers — all decode is `try?` with a fresh-game fallback at the call site.
enum GameCodec {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func encodeGrid(_ grid: [[Int]]) -> String {
        guard let data = try? encoder.encode(grid),
              let s = String(data: data, encoding: .utf8) else { return "[]" }
        return s
    }

    static func decodeGrid(_ blob: String) -> [[Int]]? {
        guard let data = blob.data(using: .utf8),
              let grid = try? decoder.decode([[Int]].self, from: data) else { return nil }
        return BlockEngine.normalized(grid)
    }

    static func encodePieces(_ pieces: [Piece?]) -> String {
        let dtos = pieces.map { PieceDTO(piece: $0) }
        guard let data = try? encoder.encode(dtos),
              let s = String(data: data, encoding: .utf8) else { return "[]" }
        return s
    }

    static func decodePieces(_ blob: String) -> [Piece?]? {
        guard let data = blob.data(using: .utf8),
              let dtos = try? decoder.decode([PieceDTO].self, from: data) else { return nil }
        return dtos.map { $0.toPiece() }
    }
}
