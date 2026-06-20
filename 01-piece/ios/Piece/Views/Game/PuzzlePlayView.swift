import SwiftUI
import SwiftData

struct PuzzlePlayView: View {
    let style: PuzzleArtStyle
    let difficulty: PuzzleDifficulty

    @State private var engine: PuzzleEngine
    @State private var showComplete = false
    @State private var showReference = false
    @State private var wrongSlot: String?
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("showHints") private var showHints = false
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var saves: [PuzzleSave]

    init(style: PuzzleArtStyle, difficulty: PuzzleDifficulty) {
        self.style = style
        self.difficulty = difficulty
        _engine = State(initialValue: PuzzleEngine(style: style, difficulty: difficulty))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PieceTheme.darkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    topBar

                    if engine.isLoadingArtwork {
                        Spacer()
                        ProgressView()
                            .tint(PieceTheme.amber)
                        Text("Preparing puzzle…")
                            .font(.caption)
                            .foregroundStyle(PieceTheme.subtleText)
                            .padding(.top, 8)
                        Spacer()
                    } else {
                        let boardSize = min(geo.size.width, geo.size.height * 0.55) - 32
                        let cellSize  = boardSize / CGFloat(engine.gridSize)

                        // Board
                        boardView(boardSize: boardSize, cellSize: cellSize)
                            .padding(.top, 12)

                        // Progress
                        progressBar
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        // Tray
                        trayView(cellSize: cellSize)
                            .padding(.top, 12)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadArtwork()
        }
        .onChange(of: engine.isComplete) { _, complete in
            if complete { handleComplete() }
        }
        .sheet(isPresented: $showComplete) {
            PuzzleCompleteView(
                style: style, difficulty: difficulty,
                elapsedSeconds: engine.elapsedSeconds
            ) {
                showComplete = false
                dismiss()
            }
        }
        .sheet(isPresented: $showReference) {
            referenceSheet
        }
    }

    // MARK: - Sub-views

    private var topBar: some View {
        HStack {
            Button {
                saveGame()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(PieceTheme.amber)
            }
            .padding(.leading, 16)
            .accessibilityLabel("Back to puzzle select")

            Spacer()

            VStack(spacing: 2) {
                Text(style.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                ElapsedView(engine: engine)
            }

            Spacer()

            Button {
                showReference = true
            } label: {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(PieceTheme.amber)
            }
            .padding(.trailing, 16)
            .accessibilityLabel("View reference image")
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func boardView(boardSize: CGFloat, cellSize: CGFloat) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 2), count: engine.gridSize),
            spacing: 2
        ) {
            ForEach(0..<engine.gridSize * engine.gridSize, id: \.self) { idx in
                let row = idx / engine.gridSize
                let col = idx % engine.gridSize
                let placed = engine.isPlaced(row: row, col: col)
                let isWrong = wrongSlot == "\(row),\(col)"

                BoardSlotView(
                    row: row, col: col,
                    cellSize: cellSize,
                    gridSize: engine.gridSize,
                    isPlaced: placed != nil,
                    piece: placed,
                    image: engine.artworkImage
                ) {
                    handleTap(row: row, col: col)
                }
                .offset(x: isWrong ? 4 : 0)
                .animation(
                    isWrong && !reduceMotion
                        ? .easeInOut(duration: 0.07).repeatCount(4, autoreverses: true)
                        : .default,
                    value: isWrong
                )
            }
        }
        .frame(width: boardSize, height: boardSize)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var progressBar: some View {
        let placed = engine.placedIds.count
        let total  = engine.pieces.count
        let pct    = total > 0 ? Double(placed) / Double(total) : 0

        return HStack(spacing: 8) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(PieceTheme.amber)
                        .frame(width: g.size.width * pct)
                        .animation(.spring(duration: 0.4), value: pct)
                }
            }
            .frame(height: 6)
            Text("\(placed)/\(total)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(PieceTheme.subtleText)
        }
        .accessibilityLabel("\(placed) of \(total) pieces placed")
    }

    @ViewBuilder
    private func trayView(cellSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if engine.trayPieces.isEmpty {
                HStack {
                    Spacer()
                    Label("All pieces placed!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(PieceTheme.completionGreen)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                Text("Tray — \(engine.trayPieces.count) remaining")
                    .font(.caption)
                    .foregroundStyle(PieceTheme.subtleText)
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 6) {
                        ForEach(engine.trayPieces) { piece in
                            if let img = engine.artworkImage {
                                PieceTileView(
                                    piece: piece, image: img,
                                    cellSize: max(44, cellSize),
                                    gridSize: engine.gridSize,
                                    isSelected: engine.selectedPieceId == piece.id
                                )
                                .onTapGesture {
                                    engine.selectPiece(piece.id, hapticsEnabled: hapticsEnabled)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var referenceSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                PuzzleArtworkView(style: style)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(16)
            }
            .navigationTitle("Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showReference = false }
                        .tint(PieceTheme.amber)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadArtwork() async {
        guard let geo = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first else {
            await engine.renderArtwork(boardSize: 300)
            return
        }
        let boardSize = min(geo.bounds.width, geo.bounds.height * 0.55) - 32
        await engine.renderArtwork(boardSize: max(100, boardSize))
    }

    private func handleTap(row: Int, col: Int) {
        let correct = engine.attemptPlace(row: row, col: col, hapticsEnabled: hapticsEnabled)
        if !correct && engine.selectedPieceId == nil {
            let key = "\(row),\(col)"
            wrongSlot = key
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                wrongSlot = nil
            }
        }
    }

    private func handleComplete() {
        saveResult()
        if !reduceMotion { HapticsManager.success() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showComplete = true
        }
    }

    private func saveGame() {
        if let existing = saves.first(where: {
            $0.puzzleStyleId == style.rawValue && $0.difficultyId == difficulty.rawValue
        }) {
            engine.writeTo(save: existing)
        } else {
            let save = PuzzleSave(style: style, difficulty: difficulty, pieces: engine.pieces)
            ctx.insert(save)
            engine.writeTo(save: save)
        }
        try? ctx.save()
    }

    private func saveResult() {
        let result = PuzzleResult(style: style, difficulty: difficulty, elapsedSeconds: engine.elapsedSeconds)
        ctx.insert(result)
        try? ctx.save()
        // Remove the save (puzzle complete)
        if let existing = saves.first(where: {
            $0.puzzleStyleId == style.rawValue && $0.difficultyId == difficulty.rawValue
        }) {
            ctx.delete(existing)
            try? ctx.save()
        }
    }
}

// MARK: - Elapsed Timer View

private struct ElapsedView: View {
    let engine: PuzzleEngine
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let s = engine.elapsedSeconds
            Text(String(format: "%d:%02d", s / 60, s % 60))
                .font(.caption.monospacedDigit())
                .foregroundStyle(PieceTheme.subtleText)
        }
    }
}
