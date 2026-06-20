import SwiftUI
import SwiftData
import Observation

@Observable
final class PuzzleEngine {
    var style: PuzzleArtStyle
    var difficulty: PuzzleDifficulty
    var pieces: [PuzzlePiece]           // scrambled tray order
    var placedIds: Set<UUID> = []
    var selectedPieceId: UUID?
    var artworkImage: UIImage?
    var isLoadingArtwork = true

    private var startDate: Date = .now
    private var extraElapsed: Int = 0
    var elapsedSeconds: Int {
        Int(Date().timeIntervalSince(startDate)) + extraElapsed
    }

    var isComplete: Bool { placedIds.count == pieces.count }
    var trayPieces: [PuzzlePiece] { pieces.filter { !placedIds.contains($0.id) } }

    var gridSize: Int { difficulty.gridSize }

    init(style: PuzzleArtStyle, difficulty: PuzzleDifficulty) {
        self.style = style
        self.difficulty = difficulty
        let gs = difficulty.gridSize
        var all: [PuzzlePiece] = []
        for r in 0..<gs { for c in 0..<gs {
            all.append(PuzzlePiece(id: UUID(), correctRow: r, correctCol: c))
        }}
        self.pieces = all.shuffled()
    }

    // Restore from saved game
    init(save: PuzzleSave) {
        self.style = PuzzleArtStyle(rawValue: save.puzzleStyleId) ?? .mountainSunset
        self.difficulty = PuzzleDifficulty(rawValue: save.difficultyId) ?? .beginner
        let saved = save.decodeOrder()
        self.pieces = saved.isEmpty ? [] : saved
        self.placedIds = save.decodePlaced()
        self.extraElapsed = save.elapsedSeconds
    }

    // MARK: - Game actions

    func selectPiece(_ id: UUID, hapticsEnabled: Bool) {
        if selectedPieceId == id {
            selectedPieceId = nil
        } else {
            selectedPieceId = id
            if hapticsEnabled { HapticsManager.selection() }
        }
    }

    /// Returns true if correctly placed
    func attemptPlace(row: Int, col: Int, hapticsEnabled: Bool) -> Bool {
        guard let selId = selectedPieceId,
              let piece = pieces.first(where: { $0.id == selId }) else { return false }
        if piece.correctRow == row && piece.correctCol == col {
            placedIds.insert(selId)
            selectedPieceId = nil
            if hapticsEnabled { HapticsManager.medium() }
            return true
        }
        selectedPieceId = nil
        if hapticsEnabled { HapticsManager.error() }
        return false
    }

    func isPlaced(row: Int, col: Int) -> PuzzlePiece? {
        pieces.first { $0.correctRow == row && $0.correctCol == col && placedIds.contains($0.id) }
    }

    // MARK: - Artwork rendering

    @MainActor
    func renderArtwork(boardSize: CGFloat) async {
        isLoadingArtwork = true
        let artView = PuzzleArtworkView(style: style)
            .frame(width: boardSize, height: boardSize)
        let renderer = ImageRenderer(content: artView)
        renderer.scale = 2.0
        artworkImage = renderer.uiImage
        isLoadingArtwork = false
    }

    // MARK: - Persistence helpers

    func writeTo(save: PuzzleSave) {
        save.elapsedSeconds = elapsedSeconds
        save.encodePlaced(placedIds)
    }

    func pause() {
        extraElapsed = elapsedSeconds
        startDate = .now
    }

    func resume() {
        startDate = .now
    }
}
