import SwiftUI
import SwiftData

struct GameView: View {
    let theme: CardTheme
    let gridSize: GridSize
    let isDaily: Bool
    let seed: UInt64?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [PairSettings]

    @State private var engine = FlipEngine()
    @State private var startDate: Date = Date()
    @State private var showWin = false
    @State private var finalDuration: Double = 0

    private var settings: PairSettings? { settingsList.first }

    init(theme: CardTheme, gridSize: GridSize, isDaily: Bool = false, seed: UInt64? = nil) {
        self.theme = theme
        self.gridSize = gridSize
        self.isDaily = isDaily
        self.seed = seed
    }

    var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(PairTheme.cardSize(for: gridSize)), spacing: 8), count: gridSize.columns)
    }

    var body: some View {
        ZStack {
            PairTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(engine.cards) { card in
                            CardView(
                                card: card,
                                theme: theme,
                                gridSize: gridSize,
                                hapticEnabled: settings?.hapticEnabled ?? true,
                                colorBlindMode: settings?.colorBlindMode ?? false,
                                onTap: { engine.flip(card: card) }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startGame()
        }
        .onChange(of: engine.isComplete) { _, complete in
            if complete {
                finalDuration = Date().timeIntervalSince(startDate)
                saveResult()
                withAnimation(.spring(duration: 0.5)) {
                    showWin = true
                }
            }
        }
        .sheet(isPresented: $showWin) {
            WinView(
                moves: engine.moves,
                duration: finalDuration,
                isDaily: isDaily,
                theme: theme,
                gridSize: gridSize,
                onPlayAgain: {
                    showWin = false
                    startGame()
                },
                onClose: {
                    showWin = false
                    dismiss()
                }
            )
            .presentationDetents([.medium])
            .presentationBackground(PairTheme.background)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(PairTheme.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                if isDaily {
                    Label("Daily", systemImage: "calendar")
                        .font(.caption.bold())
                        .foregroundStyle(PairTheme.accent)
                }
                Text(theme.displayName)
                    .font(.headline)
                    .foregroundStyle(PairTheme.textPrimary)
            }

            Spacer()

            HStack(spacing: 16) {
                VStack(spacing: 0) {
                    TimelineView(.animation(minimumInterval: 0.1)) { _ in
                        Text(formatDuration(Date().timeIntervalSince(startDate)))
                            .font(.system(.callout, design: .monospaced).bold())
                            .foregroundStyle(PairTheme.accent)
                    }
                    Text("time")
                        .font(.caption2)
                        .foregroundStyle(PairTheme.textSecondary)
                }

                VStack(spacing: 0) {
                    Text("\(engine.moves)")
                        .font(.system(.callout, design: .monospaced).bold())
                        .foregroundStyle(PairTheme.textPrimary)
                    Text("moves")
                        .font(.caption2)
                        .foregroundStyle(PairTheme.textSecondary)
                }

                Button {
                    startGame()
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title2)
                        .foregroundStyle(PairTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private func startGame() {
        engine.setupGame(theme: theme, gridSize: gridSize, seed: seed)
        startDate = Date()
        showWin = false
    }

    private func saveResult() {
        let result = PairResult(
            theme: theme.rawValue,
            gridSize: gridSize.rawValue,
            moves: engine.moves,
            durationSeconds: finalDuration,
            isDaily: isDaily
        )
        modelContext.insert(result)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = Int(seconds)
        let m = s / 60
        return String(format: "%d:%02d", m, s % 60)
    }
}

struct WinView: View {
    let moves: Int
    let duration: Double
    let isDaily: Bool
    let theme: CardTheme
    let gridSize: GridSize
    let onPlayAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .font(.system(size: 64))

            Text("You did it!")
                .font(.largeTitle.bold())
                .foregroundStyle(PairTheme.textPrimary)

            HStack(spacing: 32) {
                statItem(value: "\(moves)", label: "Moves", icon: "arrow.left.arrow.right")
                statItem(value: formatDuration(duration), label: "Time", icon: "clock")
            }

            if isDaily {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundStyle(PairTheme.accent)
                    Text("Daily Challenge Complete!")
                        .font(.subheadline.bold())
                        .foregroundStyle(PairTheme.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(PairTheme.accent.opacity(0.15))
                .clipShape(Capsule())
            }

            HStack(spacing: 16) {
                Button("Play Again", action: onPlayAgain)
                    .font(.headline)
                    .foregroundStyle(PairTheme.background)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(PairTheme.accent)
                    .clipShape(Capsule())

                Button("Done", action: onClose)
                    .font(.headline)
                    .foregroundStyle(PairTheme.textPrimary)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(PairTheme.surfaceSecondary)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(PairTheme.accent)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(PairTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(PairTheme.textSecondary)
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .background(PairTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = Int(seconds)
        let m = s / 60
        return String(format: "%d:%02d", m, s % 60)
    }
}

#Preview {
    NavigationStack {
        GameView(theme: .animals, gridSize: .easy)
    }
    .modelContainer(for: [PairResult.self, PairSettings.self], inMemory: true)
}
