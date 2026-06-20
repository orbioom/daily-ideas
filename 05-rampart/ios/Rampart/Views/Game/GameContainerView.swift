import SwiftUI

struct GameContainerView: View {
    let map: GameMap
    @State private var game: RampartGame
    @Environment(\.dismiss) private var dismiss

    init(map: GameMap) {
        self.map = map
        self._game = State(initialValue: RampartGame(map: map))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: game.phase != .wave)) { context in
            GameViewUpdater(game: game, timestamp: context.date.timeIntervalSinceReferenceDate) {
                GameView(game: game, onExit: { dismiss() })
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

/// A wrapper that calls game.update on each timeline tick, then renders the child
private struct GameViewUpdater<Content: View>: View {
    let game: RampartGame
    let timestamp: TimeInterval
    let content: () -> Content

    var body: some View {
        let _ = updateGame()
        content()
    }

    @discardableResult
    private func updateGame() -> Bool {
        game.update(timestamp: timestamp)
        return true
    }
}
