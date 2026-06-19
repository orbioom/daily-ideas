import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [AppPreferences]
    private var pref: AppPreferences? { prefs.first }

    @State private var engine = PyramidGameEngine()
    @State private var gameStartTime: Date = .now
    @State private var showingWin = false
    @State private var showingLoss = false
    @State private var showingNewGame = false
    @State private var showingHelp = false

    private let cardW: CGFloat = 38
    private let cardH: CGFloat = 53
    private let hSpacing: CGFloat = 4

    var body: some View {
        ZStack {
            Color("FeltGreen").ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal)
                    .padding(.top, 4)

                pyramidSection
                    .padding(.top, 8)

                controlRow
                    .padding(.vertical, 10)

                Spacer()
            }

            if showingWin { winOverlay }
            if showingLoss { lossOverlay }
        }
        .onAppear {
            if engine.phase == .playing && engine.drawPile.isEmpty && engine.pyramidCards[0].isEmpty {
                startNewGame()
            }
        }
        .onChange(of: engine.phase) { _, phase in
            if phase == .won {
                saveResult(won: true)
                withAnimation(.spring()) { showingWin = true }
                triggerHaptic(.success)
            } else if phase == .lost {
                saveResult(won: false)
                withAnimation(.spring()) { showingLoss = true }
                triggerHaptic(.error)
            }
        }
        .alert("New Game?", isPresented: $showingNewGame) {
            Button("New Game", role: .destructive) { startNewGame() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Current game progress will be lost.")
        }
        .sheet(isPresented: $showingHelp) { HelpSheetView() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button { showingHelp = true } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(ApexTheme.gold)
                    }
                    Button { showingNewGame = true } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(ApexTheme.gold)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("FeltGreen").opacity(0.0), for: .navigationBar)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.apexCaption()).foregroundStyle(.white.opacity(0.6))
                Text("\(engine.score)")
                    .font(.apexTitle()).foregroundStyle(ApexTheme.gold)
            }
            Spacer()
            VStack(alignment: .center, spacing: 2) {
                Text("MOVES")
                    .font(.apexCaption()).foregroundStyle(.white.opacity(0.6))
                Text("\(engine.moves)")
                    .font(.apexTitle()).foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("PASSES LEFT")
                    .font(.apexCaption()).foregroundStyle(.white.opacity(0.6))
                Text("\(engine.passesRemaining)")
                    .font(.apexTitle()).foregroundStyle(engine.passesRemaining == 0 ? .red : .white)
            }
        }
    }

    // MARK: - Pyramid

    private var pyramidSection: some View {
        GeometryReader { geo in
            let maxWidth = geo.size.width - 16
            let baseCards = 7
            let totalCardWidth = CGFloat(baseCards) * cardW + CGFloat(baseCards - 1) * hSpacing
            let scale = min(1.0, maxWidth / totalCardWidth)
            let cw = cardW * scale
            let ch = cardH * scale
            let hs = hSpacing * scale
            let vSpacing = ch * 0.38

            VStack(spacing: -vSpacing) {
                ForEach(0..<7, id: \.self) { row in
                    HStack(spacing: hs) {
                        ForEach(0...row, id: \.self) { col in
                            pyramidCardAt(row: row, col: col, cw: cw, ch: ch)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 280)
    }

    @ViewBuilder
    private func pyramidCardAt(row: Int, col: Int, cw: CGFloat, ch: CGFloat) -> some View {
        if let card = engine.pyramidCards[safe: row]?[safe: col] ?? nil {
            let covered = !engine.isUncovered(row: row, col: col)
            let selected = engine.selectedCard == card

            CardView(card: card, isSelected: selected, isCovered: covered,
                     size: CGSize(width: cw, height: ch))
                .onTapGesture {
                    if !covered {
                        triggerHaptic(.light)
                        engine.tapPyramidCard(row: row, col: col)
                    }
                }
                .opacity(covered ? 0.65 : 1.0)
        } else {
            EmptyCardSlot(size: CGSize(width: cw, height: ch))
        }
    }

    // MARK: - Control Row (draw pile, waste, score card, undo)

    private var controlRow: some View {
        HStack(spacing: 20) {
            // Undo
            Button {
                triggerHaptic(.light)
                engine.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(engine.canUndo ? ApexTheme.gold : Color.white.opacity(0.2))
            }
            .disabled(!engine.canUndo)
            .accessibilityLabel("Undo")

            Spacer()

            // Draw pile
            ZStack {
                if !engine.drawPile.isEmpty {
                    CardView(card: engine.drawPile.last!, isCovered: true,
                             size: CGSize(width: 52, height: 72))
                } else {
                    ZStack {
                        EmptyCardSlot(size: CGSize(width: 52, height: 72))
                        if engine.passesRemaining > 0 {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 22))
                                .foregroundStyle(ApexTheme.gold)
                        } else {
                            Text("—")
                                .font(.apexTitle())
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
            }
            .onTapGesture {
                triggerHaptic(.light)
                engine.drawCard()
            }
            .accessibilityLabel(engine.drawPile.isEmpty ? "Recycle waste pile" : "Draw card")

            // Waste pile
            ZStack {
                if let waste = engine.wasteTop {
                    CardView(card: waste,
                             isSelected: engine.selectedLocation == .waste,
                             size: CGSize(width: 52, height: 72))
                        .onTapGesture {
                            triggerHaptic(.light)
                            engine.tapWaste()
                        }
                } else {
                    EmptyCardSlot(size: CGSize(width: 52, height: 72))
                }
            }
            .accessibilityLabel("Waste pile top card")

            Spacer()

            // Hint / info
            VStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.white.opacity(0.3))
                Text("HINT\nSoon")
                    .font(.apexCaption())
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Overlays

    private var winOverlay: some View {
        ZStack {
            ApexTheme.overlayBG.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("✨ Pyramid Cleared! ✨")
                    .font(.apexTitle())
                    .foregroundStyle(ApexTheme.gold)
                    .multilineTextAlignment(.center)
                Text("Score: \(engine.score)")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                Text("Moves: \(engine.moves)")
                    .font(.apexBody())
                    .foregroundStyle(.white.opacity(0.8))
                Button("New Game") {
                    showingWin = false
                    startNewGame()
                }
                .apexButtonStyle(color: ApexTheme.gold)
            }
            .padding(32)
        }
        .transition(.opacity)
    }

    private var lossOverlay: some View {
        ZStack {
            ApexTheme.overlayBG.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("No More Moves")
                    .font(.apexTitle())
                    .foregroundStyle(.white)
                Text("Score: \(engine.score)")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(ApexTheme.gold)
                HStack(spacing: 16) {
                    Button("Try Again") {
                        showingLoss = false
                        startNewGame()
                    }
                    .apexButtonStyle(color: ApexTheme.gold)
                }
            }
            .padding(32)
        }
        .transition(.opacity)
    }

    // MARK: - Helpers

    private func startNewGame() {
        engine.newGame()
        gameStartTime = .now
        showingWin = false
        showingLoss = false
    }

    private func saveResult(won: Bool) {
        let duration = Date().timeIntervalSince(gameStartTime)
        let result = GameResult(won: won, score: engine.score, moves: engine.moves, duration: duration)
        ctx.insert(result)
    }

    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard pref?.hapticEnabled != false else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard pref?.hapticEnabled != false else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension View {
    func apexButtonStyle(color: Color) -> some View {
        self
            .font(.apexBody().bold())
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HelpSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("How to Play Pyramid Solitaire")
                            .font(.apexTitle()).foregroundStyle(ApexTheme.gold)
                        Text("Goal: Remove all 28 pyramid cards by pairing cards that sum to 13.")
                            .font(.apexBody())
                        Text("Card Values").font(.headline)
                        Text("A=1, 2-10=face value, J=11, Q=12, K=13")
                        Text("Valid Pairs").font(.headline)
                        Text("A+Q • 2+J • 3+10 • 4+9 • 5+8 • 6+7\nKing can be removed alone!")
                        Text("Uncovered Cards").font(.headline)
                        Text("You can only select pyramid cards that aren't covered by cards below them.")
                        Text("Draw Pile").font(.headline)
                        Text("Tap the draw pile to flip cards to the waste pile. You can recycle the waste pile up to 2 times (3 passes total).")
                        Text("Scoring").font(.headline)
                        Text("Kings: 50 pts • Other pairs: 20-30 pts • Clearing the pyramid: +250 bonus!")
                    }
                    .foregroundStyle(.primary)
                }
                .padding()
            }
            .background(Color("FeltGreen").opacity(0.08))
            .navigationTitle("Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
