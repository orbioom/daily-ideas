import SwiftUI

struct BoardView: View {
    @Bindable var vm: GameViewModel
    @Query private var allPrefs: [ScribePrefs]
    @Environment(\.modelContext) private var context
    @State private var showExchangeSheet = false
    @State private var exchangeSelection = IndexSet()
    @State private var showNewGameAlert = false

    private var prefs: ScribePrefs {
        if let p = allPrefs.first { return p }
        let p = ScribePrefs(); context.insert(p); return p
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                scoreHeader
                boardGrid
                rackSection
                actionButtons
            }
            .navigationTitle("Scribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New") { showNewGameAlert = true }
                }
            }
            .alert("New Game?", isPresented: $showNewGameAlert) {
                Button("Start New", role: .destructive) { vm.startNewGame() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Current game progress will be lost.")
            }
            .overlay {
                if vm.showMessage {
                    ToastView(message: vm.message)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                vm.showMessage = false
                            }
                        }
                }
            }
            .sheet(isPresented: $vm.isGameOver) {
                GameOverSheet(vm: vm)
            }
        }
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Score").font(.caption).foregroundStyle(.secondary)
                Text("\(vm.score)").font(.title.bold())
            }
            Spacer()
            VStack(alignment: .center) {
                Text("Bag").font(.caption).foregroundStyle(.secondary)
                Text("\(vm.bag.count)").font(.title3.bold())
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Turn").font(.caption).foregroundStyle(.secondary)
                Text("\(vm.turn)").font(.title3.bold())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var boardGrid: some View {
        GeometryReader { geo in
            let cellSize = geo.size.width / CGFloat(BoardLayout.size)
            Canvas { ctx, size in
                for r in 0..<BoardLayout.size {
                    for c in 0..<BoardLayout.size {
                        let sq = vm.board[r][c]
                        let rect = CGRect(x: CGFloat(c) * cellSize, y: CGFloat(r) * cellSize, width: cellSize, height: cellSize)
                        let fillColor = squareColor(sq)
                        ctx.fill(Path(rect), with: .color(fillColor))
                        ctx.stroke(Path(rect), with: .color(.black.opacity(0.15)), lineWidth: 0.5)
                        if let tile = sq.tile {
                            var attrs = AttributedString(String(tile.letter))
                            attrs.font = .system(size: cellSize * 0.52, weight: .bold)
                            attrs.foregroundColor = .black
                            ctx.draw(Text(attrs), at: CGPoint(x: rect.midX, y: rect.midY - cellSize * 0.08))
                            var pts = AttributedString("\(tile.points)")
                            pts.font = .system(size: cellSize * 0.25)
                            pts.foregroundColor = .black.opacity(0.6)
                            ctx.draw(Text(pts), at: CGPoint(x: rect.midX + cellSize * 0.28, y: rect.midY + cellSize * 0.22))
                        } else if sq.type != .normal {
                            var label = AttributedString(sq.type.rawValue)
                            label.font = .system(size: cellSize * 0.28, weight: .semibold)
                            label.foregroundColor = .white.opacity(0.9)
                            ctx.draw(Text(label), at: CGPoint(x: rect.midX, y: rect.midY))
                        }
                    }
                }
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let col = Int(value.location.x / cellSize)
                        let row = Int(value.location.y / cellSize)
                        guard row >= 0, row < BoardLayout.size, col >= 0, col < BoardLayout.size else { return }
                        vm.placeTile(row: row, col: col)
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color(hex: "#5c8a3e"))
    }

    private func squareColor(_ sq: BoardSquare) -> Color {
        if sq.tile != nil {
            let isNew = vm.placedThisTurn.contains { $0.row == sq.row && $0.col == sq.col }
            return isNew ? Color(hex: "#ffe180") : Color(hex: "#f5deb3")
        }
        switch sq.type {
        case .tripleWord: return Color(hex: "#c0392b")
        case .doubleWord: return Color(hex: "#e8705a")
        case .center: return Color(hex: "#e8705a")
        case .tripleLetter: return Color(hex: "#2471a3")
        case .doubleLetter: return Color(hex: "#5dade2")
        case .normal: return Color(hex: "#4a7a2e")
        }
    }

    private var rackSection: some View {
        HStack(spacing: 6) {
            ForEach(vm.playerRack.indices, id: \.self) { idx in
                let tile = vm.playerRack[idx]
                let isSelected = vm.selectedTileIndex == idx
                Button {
                    vm.selectRackTile(at: idx)
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.yellow : Color(hex: "#f5deb3"))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? Color.orange : Color.black.opacity(0.3), lineWidth: isSelected ? 2 : 1))
                        VStack(spacing: 0) {
                            Text(String(tile.letter))
                                .font(.title2.bold())
                                .foregroundStyle(.black)
                        }
                        if prefs.showTileValues {
                            Text("\(tile.points)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.black.opacity(0.7))
                                .padding(2)
                        }
                    }
                    .frame(width: 42, height: 48)
                }
                .scaleEffect(isSelected ? 1.12 : 1)
                .animation(.spring(response: 0.2), value: isSelected)
                .accessibilityLabel("\(String(tile.letter)), \(tile.points) points\(isSelected ? ", selected" : "")")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.bar)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button { vm.recallTiles() } label: {
                Label("Recall", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)

            Button { vm.passTurn() } label: {
                Label("Pass", systemImage: "arrow.forward")
            }
            .buttonStyle(.bordered)

            Button {
                if vm.playWord() { }
            } label: {
                Label("Play", systemImage: "checkmark.circle.fill")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.bar)
    }
}

private struct ToastView: View {
    let message: String
    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(.subheadline.bold())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .padding(.bottom, 200)
        }
    }
}

private struct GameOverSheet: View {
    let vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
            Text("Game Over!")
                .font(.largeTitle.bold())
            Text("Final Score: \(vm.score)")
                .font(.title2)
            if let best = vm.playedWords.max(by: { $0.score < $1.score }) {
                Text("Best Word: \(best.word) (\(best.score) pts)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button("Play Again") {
                vm.startNewGame()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
    }
}

extension Color {
    init(hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8) & 0xFF) / 255
        let b = Double(val & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
