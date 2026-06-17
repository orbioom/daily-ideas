import Foundation
import SwiftData

/// A saved sequencer pattern. The grid is encoded to `Data` (JSON) so the
/// schema stays simple and migration-free.
@Model
final class Pattern {
    var name: String
    var bpm: Double
    var swing: Double          // 0...1 (fraction of a step that odd steps are delayed)
    var kitID: String
    var stepCount: Int
    var gridData: Data         // encoded StepGrid
    var isBuiltIn: Bool
    var createdAt: Date

    init(
        name: String,
        bpm: Double,
        swing: Double,
        kitID: String,
        grid: StepGrid,
        isBuiltIn: Bool = false,
        createdAt: Date = .now
    ) {
        self.name = name
        self.bpm = bpm
        self.swing = swing
        self.kitID = kitID
        self.stepCount = grid.stepCount
        self.gridData = Pattern.encode(grid)
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }

    /// Decoded grid, falling back to an empty grid of the stored step count.
    var grid: StepGrid {
        get {
            if let decoded = try? JSONDecoder().decode(StepGrid.self, from: gridData) {
                return decoded
            }
            return StepGrid(stepCount: stepCount)
        }
        set {
            gridData = Pattern.encode(newValue)
            stepCount = newValue.stepCount
        }
    }

    static func encode(_ grid: StepGrid) -> Data {
        (try? JSONEncoder().encode(grid)) ?? Data()
    }
}
