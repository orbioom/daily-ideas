import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("drawThree") private var drawThree = false
    @AppStorage("leftHandMode") private var leftHandMode = false
    @AppStorage("showScoreBar") private var showScoreBar = true
    @AppStorage("feltStyle") private var feltStyleRaw = Felt.classic.rawValue

    @State private var confirmingNewGame = false
    @State private var shakeTask: Task<Void, Never>?

    private var felt: Felt { Felt(rawValue: feltStyleRaw) ?? .classic }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 6
            let cardWidth = (geo.size.width - spacing * 8) / 7
            let cardHeight = cardWidth * 1.45

            ZStack {
                PalaceTheme.feltBackground(felt, scheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    topBar
                    pileRow(cardWidth: cardWidth, spacing: spacing)
                    ScrollView {
                        tableau(cardWidth: cardWidth, cardHeight: cardHeight, spacing: spacing)
                            .padding(.bottom, 24)
                    }
                    .scrollIndicators(.hidden)
                }
                .padding(.horizontal, spacing)

                if engine.isWon {
                    winOverlay
                }
            }
        }
        .onAppear { engine.resumeClock() }
        .onDisappear {
            engine.pauseClock()
            if !engine.isWon { GameStore.save(engine.state) }
        }
        .onChange(of: engine.pendingRecord) { _, record in
            guard let record else { return }
            modelContext.insert(GameRecord(
                won: record.won,
                score: record.score,
                moves: record.moves,
                durationSeconds: record.durationSeconds,
                drawThree: record.drawThree
            ))
            engine.pendingRecord = nil
            if record.won {
                Haptics.success()
                GameStore.clear()
            }
        }
        .onChange(of: engine.rejectedCardID) { _, id in
            guard id != nil else { return }
            Haptics.warning()
            shakeTask?.cancel()
            shakeTask = Task {
                try? await Task.sleep(nanoseconds: 450_000_000)
                if !Task.isCancelled { engine.clearRejection() }
            }
        }
        .confirmationDialog(
            "Start a new game? The current game will be recorded as a loss.",
            isPresented: $confirmingNewGame,
            titleVisibility: .visible
        ) {
            Button("New Game", role: .destructive) { startNewGame() }
            Button("Keep Playing", role: .cancel) {}
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            if showScoreBar {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack(spacing: 12) {
                        chip("Score", value: "\(engine.state.score)")
                        chip("Time", value: Format.duration(engine.elapsedSeconds(at: context.date)))
                        chip("Moves", value: "\(engine.state.moves)")
                    }
                }
            }
            Spacer()
            Button {
                Haptics.tap()
                engine.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.body.weight(.semibold))
            }
            .disabled(!engine.canUndo)
            .buttonStyle(.bordered)
            .tint(.white)
            .accessibilityLabel("Undo last move")

            Button {
                if engine.state.moves > 0 && !engine.isWon {
                    confirmingNewGame = true
                } else {
                    startNewGame()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .accessibilityLabel("New game")
        }
        .padding(.top, 4)
    }

    private func chip(_ title: String, value: String) -> some View {
        VStack(spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.callout.weight(.semibold).monospacedDigit())
                .fontDesign(.serif)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Stock / waste / foundations

    private func pileRow(cardWidth: CGFloat, spacing: CGFloat) -> some View {
        let stock = stockView(cardWidth: cardWidth)
        let waste = wasteView(cardWidth: cardWidth)
        let foundations = ForEach(0..<4, id: \.self) { i in
            foundationView(i, cardWidth: cardWidth)
        }
        return HStack(spacing: spacing) {
            if leftHandMode {
                foundations
                Spacer(minLength: 0)
                waste
                stock
            } else {
                stock
                waste
                Spacer(minLength: 0)
                foundations
            }
        }
    }

    private func stockView(cardWidth: CGFloat) -> some View {
        Group {
            if let top = engine.state.stock.last {
                CardView(card: top, width: cardWidth)
            } else {
                PilePlaceholder(width: cardWidth, glyph: engine.state.waste.isEmpty ? nil : "arrow.counterclockwise")
            }
        }
        .onTapGesture {
            Haptics.tap()
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                engine.tapStock()
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Stock, \(engine.state.stock.count) cards")
        .accessibilityHint(engine.state.stock.isEmpty ? "Recycles the waste pile" : "Draws from the stock")
        .accessibilityAddTraits(.isButton)
    }

    private func wasteView(cardWidth: CGFloat) -> some View {
        let visible = Array(engine.state.waste.suffix(engine.state.drawThree ? 3 : 1))
        return ZStack(alignment: .leading) {
            if visible.isEmpty {
                PilePlaceholder(width: cardWidth)
            }
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, card in
                CardView(card: card, width: cardWidth, shaking: engine.rejectedCardID == card.id)
                    .offset(x: CGFloat(index) * cardWidth * 0.28)
            }
        }
        .frame(width: cardWidth + cardWidth * 0.56, alignment: .leading)
        .onTapGesture {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                if engine.smartMove(from: .waste) { Haptics.tap() }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(wasteAccessibilityLabel)
        .accessibilityHint("Moves the top waste card if a move exists")
        .accessibilityAddTraits(.isButton)
    }

    private var wasteAccessibilityLabel: String {
        if let top = engine.state.waste.last {
            return "Waste, top card \(top.accessibilityName)"
        }
        return "Waste, empty"
    }

    private func foundationView(_ index: Int, cardWidth: CGFloat) -> some View {
        Group {
            if let top = engine.state.foundations[index].last {
                CardView(card: top, width: cardWidth, shaking: engine.rejectedCardID == top.id)
            } else {
                PilePlaceholder(width: cardWidth, glyph: "crown")
            }
        }
        .onTapGesture {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                if engine.smartMove(from: .foundation(index)) { Haptics.tap() }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(foundationAccessibilityLabel(index))
        .accessibilityAddTraits(.isButton)
    }

    private func foundationAccessibilityLabel(_ index: Int) -> String {
        if let top = engine.state.foundations[index].last {
            return "Foundation \(index + 1), \(top.accessibilityName)"
        }
        return "Foundation \(index + 1), empty"
    }

    // MARK: - Tableau

    private func tableau(cardWidth: CGFloat, cardHeight: CGFloat, spacing: CGFloat) -> some View {
        let downOverlap = cardHeight * 0.16
        let upOverlap = cardHeight * 0.30
        return HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<7, id: \.self) { column in
                tableauColumn(
                    column,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    downOverlap: downOverlap,
                    upOverlap: upOverlap
                )
            }
        }
        .overlay(alignment: .bottom) {
            if engine.canAutoComplete {
                Button {
                    Haptics.tap()
                    Task { await engine.autoComplete() }
                } label: {
                    Label("Finish Game", systemImage: "wand.and.stars")
                        .font(.headline)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(PalaceTheme.gold)
                .foregroundStyle(.black)
                .padding(.bottom, 8)
                .accessibilityHint("Automatically plays the remaining cards to the foundations")
            }
        }
    }

    private func tableauColumn(
        _ column: Int,
        cardWidth: CGFloat,
        cardHeight: CGFloat,
        downOverlap: CGFloat,
        upOverlap: CGFloat
    ) -> some View {
        let pile = engine.state.tableau[column]
        var offsets: [CGFloat] = []
        var y: CGFloat = 0
        for card in pile {
            offsets.append(y)
            y += card.faceUp ? upOverlap : downOverlap
        }
        let totalHeight = (offsets.last ?? 0) + cardHeight

        return ZStack(alignment: .top) {
            PilePlaceholder(width: cardWidth)
            ForEach(Array(pile.enumerated()), id: \.element.id) { index, card in
                CardView(card: card, width: cardWidth, shaking: engine.rejectedCardID == card.id)
                    .offset(y: offsets[index])
                    .onTapGesture {
                        guard card.faceUp else { return }
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                            if engine.smartMove(from: .tableau(column: column, index: index)) {
                                Haptics.tap()
                            }
                        }
                    }
                    .accessibilityAddTraits(card.faceUp ? .isButton : [])
                    .accessibilityHint(card.faceUp ? "Moves this card if a move exists" : "")
            }
        }
        .frame(width: cardWidth, height: max(totalHeight, cardHeight), alignment: .top)
    }

    // MARK: - Win overlay

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(PalaceTheme.gold)
                Text("Game Won")
                    .font(.largeTitle.weight(.semibold))
                    .fontDesign(.serif)
                VStack(spacing: 6) {
                    Text("Score \(engine.state.score)")
                    Text("\(engine.state.moves) moves · \(Format.duration(engine.elapsedSeconds()))")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                Button {
                    startNewGame()
                } label: {
                    Text("Deal Again")
                        .font(.headline)
                        .frame(maxWidth: 220)
                }
                .buttonStyle(.borderedProminent)
                .tint(PalaceTheme.gold)
                .foregroundStyle(.black)
            }
            .padding(32)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(40)
            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("You won. Score \(engine.state.score), \(engine.state.moves) moves.")
    }

    private func startNewGame() {
        Haptics.tap()
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
            engine.newGame(drawThree: drawThree)
        }
        GameStore.clear()
    }
}
