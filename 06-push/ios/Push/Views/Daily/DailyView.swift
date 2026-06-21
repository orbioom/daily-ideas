import SwiftUI
import SwiftData

struct DailyView: View {
    @Query private var dailyResults: [PushDailyResult]
    @Environment(\.modelContext) private var modelContext

    @State private var showingPuzzle: Bool = false

    private var todayString: String { DailyLevelPicker.dateString() }
    private var todayLevel: SokobanLevel { DailyLevelPicker.level() }

    private var todayResult: PushDailyResult? {
        dailyResults.first(where: { $0.dateString == todayString })
    }

    private var streak: Int {
        // Count consecutive days with solved results
        let solvedDates = dailyResults
            .filter { $0.solved }
            .map { $0.dateString }
            .sorted(by: >)

        var count = 0
        var checkDate = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        for _ in 0..<365 {
            let ds = fmt.string(from: checkDate)
            if solvedDates.contains(ds) {
                count += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if ds == todayString {
                // Today not yet solved — keep checking yesterday
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date & streak header
                    headerCard

                    // Today's puzzle card
                    todayCard

                    if let result = todayResult, result.solved {
                        solvedCard(result: result)
                    }

                    // Recent history
                    if !dailyResults.isEmpty {
                        historySection
                    }
                }
                .padding(16)
            }
            .background(PushTheme.background.ignoresSafeArea())
            .navigationTitle("Daily Puzzle")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPuzzle) {
                NavigationStack {
                    DailyPuzzleWrapper(
                        level: todayLevel,
                        todayString: todayString,
                        existingResult: todayResult
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(PushTheme.wall)
                Text(dayOfWeek)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(PushTheme.wall.opacity(0.5))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak)")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundColor(PushTheme.wall)
                }
                Text("day streak")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(PushTheme.wall.opacity(0.45))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }

    // MARK: - Today card

    private var todayCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Puzzle")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(PushTheme.wall)
                    Text(todayLevel.title)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(PushTheme.wall.opacity(0.5))
                }
                Spacer()
                if todayResult?.solved == true {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(PushTheme.boxOnTarget)
                }
            }

            if todayResult?.solved != true {
                Button {
                    showingPuzzle = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Play Now")
                    }
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(PushTheme.pack5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }

    // MARK: - Solved card

    private func solvedCard(result: PushDailyResult) -> some View {
        VStack(spacing: 12) {
            Text("Completed in \(result.moves) moves")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(PushTheme.wall)

            // Share button
            ShareLink(item: shareText(moves: result.moves)) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Result")
                }
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundColor(PushTheme.pack5)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .strokeBorder(PushTheme.pack5, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(PushTheme.pack5.opacity(0.08))
        )
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(PushTheme.wall.opacity(0.5))
                .padding(.horizontal, 4)

            ForEach(dailyResults.sorted(by: { $0.dateString > $1.dateString }).prefix(7), id: \.dateString) { result in
                HStack {
                    Image(systemName: result.solved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.solved ? PushTheme.boxOnTarget : PushTheme.wall.opacity(0.3))
                    Text(result.dateString)
                        .font(.system(.callout, design: .rounded))
                        .foregroundColor(PushTheme.wall.opacity(0.7))
                    Spacer()
                    if result.solved {
                        Text("\(result.moves) moves")
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                            .foregroundColor(PushTheme.wall.opacity(0.5))
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemBackground))
                )
            }
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM d, yyyy"
        return fmt.string(from: Date())
    }

    private var dayOfWeek: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE"
        return fmt.string(from: Date())
    }

    private func shareText(moves: Int) -> String {
        "Push Daily — \(formattedDate)\nSolved in \(moves) moves!\n\nTry it: https://apps.apple.com/app/push-sokoban"
    }
}

// MARK: - Daily Puzzle Wrapper

struct DailyPuzzleWrapper: View {
    let level: SokobanLevel
    let todayString: String
    let existingResult: PushDailyResult?

    @State private var game: SokobanGame
    @State private var showWin: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var prefs: [PushPrefs]

    private var hapticsEnabled: Bool { prefs.first?.hapticsEnabled ?? true }
    private var controlScheme: String { prefs.first?.controlScheme ?? "swipe" }

    init(level: SokobanLevel, todayString: String, existingResult: PushDailyResult?) {
        self.level = level
        self.todayString = todayString
        self.existingResult = existingResult
        _game = State(initialValue: SokobanGame(level: level))
    }

    var body: some View {
        ZStack {
            PushTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    statChip(value: "\(game.moves)", label: "Moves")
                    statChip(value: "\(game.pushes)", label: "Pushes")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                GridView(game: game, onMove: handleMove)
                    .padding(.horizontal, 16)
                    .frame(maxHeight: .infinity)

                if controlScheme == "dpad" {
                    ControlPadView(
                        onMove: handleMove,
                        onUndo: { game.undo() },
                        canUndo: game.canUndo
                    )
                    .padding(.vertical, 12)
                } else {
                    HStack {
                        Spacer()
                        Button {
                            game.undo()
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                                .font(.system(.callout, design: .rounded, weight: .semibold))
                                .foregroundColor(game.canUndo ? PushTheme.accent : PushTheme.wall.opacity(0.3))
                        }
                        .disabled(!game.canUndo)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("Daily — \(level.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }
                    .foregroundColor(PushTheme.accent)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { game.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(PushTheme.accent)
                }
            }
        }
        .onChange(of: game.isSolved) { _, solved in
            if solved { handleWin() }
        }
        .sheet(isPresented: $showWin) {
            WinSheet(
                level: level,
                moves: game.moves,
                pushes: game.pushes,
                parMoves: level.parMoves,
                stars: game.stars(parMoves: level.parMoves),
                onNextLevel: { dismiss() },
                onRetry: { showWin = false; game.reset() }
            )
            .presentationDetents([.medium])
        }
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundColor(PushTheme.wall)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private func handleMove(_ direction: Direction) {
        game.move(direction)
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func handleWin() {
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        // Save daily result
        if existingResult == nil {
            let result = PushDailyResult(dateString: todayString, levelId: level.id, solved: true, moves: game.moves)
            modelContext.insert(result)
            try? modelContext.save()
        }
        showWin = true
    }
}

#Preview {
    DailyView()
        .modelContainer(for: [PushRecord.self, PushPrefs.self, PushDailyResult.self, PushOnboarding.self], inMemory: true)
}
