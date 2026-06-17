import Foundation
import SwiftData

/// At most one in-progress board, persisted so the player can resume on relaunch.
/// Paths are stored as JSON so SwiftData only needs primitive types.
@Model
final class SavedBoard {
    var puzzleId: String
    var pathsJSON: String
    var elapsedSeconds: Int
    var moveCount: Int
    var savedAt: Date

    init(puzzleId: String, pathsJSON: String, elapsedSeconds: Int, moveCount: Int, savedAt: Date = .now) {
        self.puzzleId = puzzleId
        self.pathsJSON = pathsJSON
        self.elapsedSeconds = elapsedSeconds
        self.moveCount = moveCount
        self.savedAt = savedAt
    }
}

/// Codable bridge for serializing the engine's path map to JSON.
struct SavedPaths: Codable {
    /// Map from color rawValue to its list of cells.
    var entries: [Entry]

    struct Entry: Codable {
        var colorRaw: Int
        var cells: [Cell]
    }

    init(from paths: [PipeColor: [Cell]]) {
        entries = paths.map { Entry(colorRaw: $0.key.rawValue, cells: $0.value) }
    }

    /// Reconstruct a path map, dropping any unknown color values defensively.
    func toPaths() -> [PipeColor: [Cell]] {
        var out: [PipeColor: [Cell]] = [:]
        for entry in entries {
            if let color = PipeColor(rawValue: entry.colorRaw) {
                out[color] = entry.cells
            }
        }
        return out
    }

    /// Encode to a JSON string; returns "{}" fallback if encoding somehow fails.
    func jsonString() -> String {
        guard let data = try? JSONEncoder().encode(self),
              let str = String(data: data, encoding: .utf8) else {
            return "{\"entries\":[]}"
        }
        return str
    }

    /// Decode from a JSON string; returns empty on any failure (never throws to UI).
    static func decode(_ json: String) -> SavedPaths {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(SavedPaths.self, from: data) else {
            return SavedPaths(entries: [])
        }
        return decoded
    }

    init(entries: [Entry]) {
        self.entries = entries
    }
}
