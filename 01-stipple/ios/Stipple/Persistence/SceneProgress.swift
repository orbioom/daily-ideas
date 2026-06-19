import Foundation
import SwiftData

@Model
final class SceneProgress {
    var sceneId: String
    var coloredData: Data    // JSON-encoded [Int] of user-chosen palette indices per cell (-1 = unfilled)
    var completedAt: Date?
    var lastModified: Date

    init(sceneId: String, cellCount: Int) {
        self.sceneId = sceneId
        self.coloredData = (try? JSONEncoder().encode([Int](repeating: -1, count: cellCount))) ?? Data()
        self.completedAt = nil
        self.lastModified = .now
    }

    func loadCells() -> [Int] {
        (try? JSONDecoder().decode([Int].self, from: coloredData)) ?? []
    }

    func saveCells(_ cells: [Int]) {
        coloredData = (try? JSONEncoder().encode(cells)) ?? Data()
        lastModified = .now
    }
}

@Model
final class StipplePrefs {
    var hasSeenOnboarding: Bool
    var hapticsEnabled: Bool
    var autoFillAdjacent: Bool
    var showGridLines: Bool
    var isPro: Bool

    init() {
        hasSeenOnboarding = false
        hapticsEnabled = true
        autoFillAdjacent = false
        showGridLines = true
        isPro = false
    }
}
