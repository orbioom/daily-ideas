import SwiftUI

struct GameView: View {
    let game: RampartGame
    let onExit: () -> Void

    @State private var showSellDialog = false
    @State private var sellTarget: (col: Int, row: Int)? = nil

    var body: some View {
        ZStack(alignment: .top) {
            RampartTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                WaveHUD(game: game, onStartWave: { game.startWave() })

                GeometryReader { geo in
                    GameCanvasView(game: game)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleTap(location: location, size: geo.size)
                        }
                }

                TowerPickerView(game: game, onSelectTower: { type in
                    game.selectedTowerType = type
                })
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            Button(action: onExit) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Exit")
                }
                .font(RampartTheme.labelFont)
                .foregroundStyle(RampartTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RampartTheme.surface.opacity(0.9))
                .clipShape(Capsule())
            }
            .padding(12)
        }
        .confirmationDialog(
            "Sell Tower?",
            isPresented: $showSellDialog,
            titleVisibility: .visible
        ) {
            if let cell = sellTarget, let tower = game.hasTower(at: cell) {
                Button("Sell \(tower.type.rawValue) for \(tower.type.cost / 2)g", role: .destructive) {
                    game.sellTower(at: cell)
                    game.selectedCell = nil
                    sellTarget = nil
                }
            }
            Button("Cancel", role: .cancel) { sellTarget = nil }
        }
        .sheet(isPresented: Binding(get: { game.phase == .gameOver }, set: { _ in })) {
            GameOverView(game: game, onRestart: { game.reset() }, onExit: onExit)
        }
        .sheet(isPresented: Binding(get: { game.phase == .victory }, set: { _ in })) {
            VictoryView(game: game, onRestart: { game.reset() }, onExit: onExit)
        }
    }

    private func handleTap(location: CGPoint, size: CGSize) {
        let scaleX = 320.0 / size.width
        let scaleY = 480.0 / size.height
        let gameX = location.x * scaleX
        let gameY = location.y * scaleY
        let col = Int(gameX / 20.0)
        let row = Int(gameY / 20.0)
        let cell = (col: col, row: row)

        if let existing = game.hasTower(at: cell) {
            let _ = existing
            game.selectedCell = cell
            sellTarget = cell
            showSellDialog = true
            return
        }

        if let sel = game.selectedCell, sel.col == col, sel.row == row {
            if game.canBuild(at: cell) {
                game.placeSelectedTower(at: cell)
                game.selectedCell = nil
            }
            return
        }

        if game.canBuild(at: cell) {
            game.selectedCell = cell
        } else {
            game.selectedCell = nil
        }
    }
}
