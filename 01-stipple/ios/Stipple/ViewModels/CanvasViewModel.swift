import SwiftUI
import SwiftData

@Observable
final class CanvasViewModel {
    let scene: PixelSceneData
    var userCells: [Int]       // -1 = unfilled, 0+ = palette index chosen by user
    var selectedColorIndex: Int = 0
    var progress: SceneProgress?
    var isComplete: Bool = false
    var autoFillAdjacent: Bool = false

    init(scene: PixelSceneData, progress: SceneProgress?, prefs: StipplePrefs?) {
        self.scene = scene
        self.progress = progress
        self.autoFillAdjacent = prefs?.autoFillAdjacent ?? false
        if let prog = progress {
            let saved = prog.loadCells()
            self.userCells = saved.count == scene.cells.count ? saved : [Int](repeating: -1, count: scene.cells.count)
        } else {
            self.userCells = [Int](repeating: -1, count: scene.cells.count)
        }
        checkComplete()
    }

    var filledCount: Int { userCells.filter { $0 >= 0 }.count }
    var totalCells: Int { scene.cells.count }
    var progressFraction: Double { totalCells == 0 ? 0 : Double(filledCount) / Double(totalCells) }

    // MARK: - Actions

    func tap(cellIndex: Int) {
        guard cellIndex >= 0 && cellIndex < scene.cells.count else { return }
        let targetColor = scene.cells[cellIndex]
        if autoFillAdjacent {
            floodFill(startIndex: cellIndex, targetColor: targetColor)
        } else {
            userCells[cellIndex] = scene.cells[cellIndex]
        }
        persistAndCheck()
    }

    func colorAll(matchingIndex paletteIndex: Int) {
        for i in 0..<scene.cells.count where scene.cells[i] == paletteIndex {
            userCells[i] = paletteIndex
        }
        persistAndCheck()
    }

    func clearCell(_ idx: Int) {
        guard idx >= 0 && idx < userCells.count else { return }
        userCells[idx] = -1
        persistAndCheck()
    }

    func reset() {
        userCells = [Int](repeating: -1, count: scene.cells.count)
        isComplete = false
        persistAndCheck()
    }

    // MARK: - Cell Color

    func displayColor(for idx: Int) -> Color {
        let userChoice = userCells[safe: idx] ?? -1
        if userChoice >= 0 && userChoice < scene.palette.count {
            return scene.palette[userChoice]
        }
        return Color(.systemGray5)
    }

    func isCorrectlyFilled(_ idx: Int) -> Bool {
        guard let uc = userCells[safe: idx] else { return false }
        return uc == scene.cells[safe: idx]
    }

    // Target color for a cell (what it SHOULD be)
    func targetColor(for idx: Int) -> Color {
        guard let ci = scene.cells[safe: idx], ci < scene.palette.count else { return .gray }
        return scene.palette[ci]
    }

    func paletteIndex(for idx: Int) -> Int {
        scene.cells[safe: idx] ?? 0
    }

    // MARK: - Private

    private func floodFill(startIndex: Int, targetColor: Int) {
        var visited = Set<Int>()
        var queue = [startIndex]
        let w = scene.width
        while !queue.isEmpty {
            let idx = queue.removeFirst()
            guard !visited.contains(idx) && idx >= 0 && idx < scene.cells.count else { continue }
            guard scene.cells[idx] == targetColor else { continue }
            visited.insert(idx)
            userCells[idx] = targetColor
            // Neighbors: left, right, up, down
            let x = idx % w, y = idx / w
            if x > 0 { queue.append(idx - 1) }
            if x < w - 1 { queue.append(idx + 1) }
            if y > 0 { queue.append(idx - w) }
            if y < scene.height - 1 { queue.append(idx + w) }
        }
    }

    private func checkComplete() {
        isComplete = userCells.enumerated().allSatisfy { idx, uc in uc == scene.cells[idx] }
    }

    private func persistAndCheck() {
        checkComplete()
        progress?.saveCells(userCells)
        if isComplete && progress?.completedAt == nil {
            progress?.completedAt = .now
        }
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
