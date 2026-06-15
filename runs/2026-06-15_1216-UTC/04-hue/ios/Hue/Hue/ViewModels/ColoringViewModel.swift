import SwiftUI

/// Drives the interactive coloring canvas: selection, hit-testing, fills, undo,
/// by-number validation, progress, and autosave back into the bound Artwork.
/// Used only from the main thread (SwiftUI views), but left non-isolated so it can
/// be touched freely from gesture/closure callbacks without isolation friction.
final class ColoringViewModel: ObservableObject {
    let page: ColoringPage

    @Published var fills: [Int: String]
    @Published var selectedColorIndex: Int = 0
    @Published var byNumberMode: Bool
    @Published var palette: Palette
    @Published var highlightedRegion: Int?
    @Published var recentColorIndices: [Int] = []
    /// Set true momentarily when the page reaches 100% so the view can celebrate.
    @Published var justCompleted = false
    /// Gentle nudge message when a by-number tap uses the wrong color.
    @Published var nudge: String?

    private var undoStack: [[Int: String]] = []
    private let maxUndo = 60

    init(page: ColoringPage, palette: Palette, fills: [Int: String], byNumberMode: Bool) {
        self.page = page
        self.palette = palette
        self.fills = fills
        self.byNumberMode = byNumberMode
    }

    // MARK: - Derived state

    var filledCount: Int { fills.count }
    var totalRegions: Int { page.regions.count }

    var progress: Double {
        guard totalRegions > 0 else { return 0 }
        return Double(filledCount) / Double(totalRegions)
    }

    var isComplete: Bool { totalRegions > 0 && filledCount >= totalRegions }

    var selectedColor: Color { palette.color(at: selectedColorIndex) }

    /// The by-number target for a region is its suggested palette index + 1.
    func requiredNumber(for region: Region) -> Int { region.suggestedColorIndex + 1 }

    // MARK: - Selection

    func selectColor(_ index: Int) {
        guard !palette.colorHexes.isEmpty else { return }
        let clamped = ((index % palette.colorHexes.count) + palette.colorHexes.count) % palette.colorHexes.count
        selectedColorIndex = clamped
    }

    // MARK: - Hit testing

    /// Given a tap in normalized page space (0...1), return the topmost matching region id.
    /// Iterates in reverse so later-drawn (visually on top) regions win ties.
    func regionID(atNormalized p: CGPoint) -> Int? {
        for region in page.regions.reversed() {
            if Geometry.contains(polygon: region.points, point: p) {
                return region.id
            }
        }
        return nil
    }

    // MARK: - Filling

    /// Apply a tap. Returns a result so the view can fire haptics / celebrate.
    @discardableResult
    func handleTap(atNormalized p: CGPoint, hapticsEnabled: Bool) -> TapResult {
        guard let rid = regionID(atNormalized: p), let region = page.region(withID: rid) else {
            return .missed
        }
        return fill(region: region, hapticsEnabled: hapticsEnabled)
    }

    @discardableResult
    func fill(region: Region, hapticsEnabled: Bool) -> TapResult {
        nudge = nil
        if byNumberMode {
            // Only allow the correct color.
            let required = region.suggestedColorIndex
            if selectedColorIndex != required {
                nudge = "That region wants color #\(required + 1)."
                Haptics.warning(enabled: hapticsEnabled)
                return .wrongNumber(required: required + 1)
            }
        }
        let hex = palette.hex(at: selectedColorIndex)
        // No-op if already that exact color (avoids polluting undo).
        if fills[region.id] == hex { return .noChange }

        pushUndo()
        fills[region.id] = hex
        highlightedRegion = region.id
        noteRecent(selectedColorIndex)
        Haptics.tap(enabled: hapticsEnabled)

        if isComplete {
            justCompleted = true
            Haptics.success(enabled: hapticsEnabled)
            return .completedPage
        }
        return .filled(regionID: region.id)
    }

    /// Fill every still-unfilled region whose suggested number matches the selected color.
    func fillAllMatching(hapticsEnabled: Bool) {
        let targets = page.regions.filter {
            $0.suggestedColorIndex == selectedColorIndex && fills[$0.id] != palette.hex(at: selectedColorIndex)
        }
        guard !targets.isEmpty else {
            nudge = "No regions match #\(selectedColorIndex + 1)."
            return
        }
        pushUndo()
        let hex = palette.hex(at: selectedColorIndex)
        for r in targets { fills[r.id] = hex }
        noteRecent(selectedColorIndex)
        Haptics.tap(enabled: hapticsEnabled)
        if isComplete {
            justCompleted = true
            Haptics.success(enabled: hapticsEnabled)
        }
    }

    func clearRegion(_ id: Int, hapticsEnabled: Bool) {
        guard fills[id] != nil else { return }
        pushUndo()
        fills.removeValue(forKey: id)
        Haptics.selection(enabled: hapticsEnabled)
    }

    // MARK: - Undo

    var canUndo: Bool { !undoStack.isEmpty }

    func undo(hapticsEnabled: Bool) {
        guard let prev = undoStack.popLast() else { return }
        fills = prev
        Haptics.selection(enabled: hapticsEnabled)
    }

    private func pushUndo() {
        undoStack.append(fills)
        if undoStack.count > maxUndo { undoStack.removeFirst(undoStack.count - maxUndo) }
    }

    private func noteRecent(_ index: Int) {
        recentColorIndices.removeAll { $0 == index }
        recentColorIndices.insert(index, at: 0)
        if recentColorIndices.count > 6 { recentColorIndices.removeLast() }
    }

    // MARK: - Palette switching (keeps fills; remaps colors stay literal hex)

    func switchPalette(_ new: Palette) {
        palette = new
        if selectedColorIndex >= new.colorHexes.count {
            selectedColorIndex = 0
        }
    }
}

enum TapResult: Equatable {
    case filled(regionID: Int)
    case completedPage
    case wrongNumber(required: Int)
    case noChange
    case missed
}
