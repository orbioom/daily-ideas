import SwiftUI
import SwiftData

/// Today's deterministic daily puzzle, a streak calendar, and a Pro-gated
/// archive of past dailies.
struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false
    @AppStorage("haptics") private var haptics = true
    @AppStorage("mistakeLimit") private var mistakeLimit = 0
    @AppStorage("highlightConflicts") private var highlightConflicts = true
    @AppStorage("highlightRelated") private var highlightRelated = true
    @AppStorage("autoRemoveNotes") private var autoRemoveNotes = true
    @AppStorage("checkMistakes") private var checkMistakes = true
    @AppStorage("showTimer") private var showTimer = true

    @Query(sort: \PuzzleResult.date, order: .reverse) private var results: [PuzzleResult]
    @Query(filter: #Predicate<SavedGame> { $0.isDaily }) private var dailySaves: [SavedGame]

    @State private var game = GameViewModel()
    @State private var playingKey: String? = nil
    @State private var showingPaywall = false

    private let todayKey = DateKey.today
    private let calendarKeys = DateKey.recentKeys(count: 28)

    private var completedDailyKeys: Set<String> {
        Set(results.filter { $0.isDaily && $0.won }.map { $0.dateKey })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let key = playingKey {
                    dailyGame(for: key)
                } else {
                    overview
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Daily")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if playingKey != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            persistDaily()
                            game.stopTimer()
                            playingKey = nil
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    // MARK: Overview

    private var overview: some View {
        ScrollView {
            VStack(spacing: 18) {
                todayCard
                streakCard
                calendarCard
                archiveCard
            }
            .padding(20)
        }
    }

    private var todayCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Today", systemImage: "sun.max.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text(displayDate(todayKey))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                let diff = Difficulty.daily(for: Date())
                Text("\(diff.displayName) · \(diff.size)×\(diff.size)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("One puzzle a day, the same for everyone. Build your streak.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                if completedDailyKeys.contains(todayKey) {
                    Label("Completed today", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.success)
                } else {
                    Button {
                        startDaily(for: todayKey)
                    } label: {
                        Label("Play Today's Puzzle", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    private var streakCard: some View {
        let (current, best) = StatsCalculator.dailyStreaks(results)
        return Card {
            HStack(spacing: 0) {
                streakStat(value: current, label: "Current streak", icon: "flame.fill")
                Divider().frame(height: 44)
                streakStat(value: best, label: "Best streak", icon: "trophy.fill")
            }
        }
    }

    private func streakStat(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var calendarCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 4 weeks")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(calendarKeys, id: \.self) { key in
                        calendarCell(key)
                    }
                }
            }
        }
    }

    private func calendarCell(_ key: String) -> some View {
        let done = completedDailyKeys.contains(key)
        let isToday = key == todayKey
        let day = dayNumber(key)
        return RoundedRectangle(cornerRadius: 8)
            .fill(done ? Theme.accent : Theme.surfaceElevated)
            .frame(height: 34)
            .overlay(
                Text("\(day)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(done ? .white : Theme.textSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Theme.accent : .clear, lineWidth: 2)
            )
            .accessibilityLabel("\(displayDate(key)): \(done ? "completed" : "not completed")")
    }

    private var archiveCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Archive")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    if !isPro { ProBadge() }
                    Spacer()
                }
                Text("Replay any past daily puzzle.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                let pastKeys = calendarKeys.reversed().filter { $0 != todayKey }
                if pastKeys.isEmpty {
                    Text("Past dailies will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(Array(pastKeys.prefix(7)), id: \.self) { key in
                        archiveRow(key)
                    }
                    if !isPro {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Unlock the full archive", systemImage: "lock.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func archiveRow(_ key: String) -> some View {
        let done = completedDailyKeys.contains(key)
        let diff = Difficulty.daily(for: DateKey.date(from: key) ?? Date())
        return Button {
            if isPro {
                startDaily(for: key)
            } else {
                showingPaywall = true
            }
        } label: {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? Theme.success : Theme.textSecondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(displayDate(key))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(diff.displayName) · \(diff.size)×\(diff.size)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: isPro ? "chevron.right" : "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(displayDate(key)) daily, \(diff.displayName)\(done ? ", completed" : "")\(isPro ? "" : ", locked")")
    }

    // MARK: Daily game

    @ViewBuilder
    private func dailyGame(for key: String) -> some View {
        switch game.phase {
        case .generating, .idle:
            GeneratingView(message: "Loading the daily puzzle…")
        default:
            PlayView(
                game: game,
                haptics: haptics,
                highlightConflicts: highlightConflicts,
                highlightRelated: highlightRelated,
                autoRemoveNotes: autoRemoveNotes,
                checkMistakes: checkMistakes,
                showTimer: showTimer,
                onPersist: persistDaily,
                onRecordResult: { won in recordDaily(key: key, won: won) },
                onNewPuzzle: {
                    persistDaily()
                    game.stopTimer()
                    playingKey = nil
                }
            )
        }
    }

    // MARK: Actions

    private func startDaily(for key: String) {
        playingKey = key
        // Resume an existing daily save if present, else generate.
        if let saved = dailySaves.first(where: { $0.dateKey == key }), !saved.isCompleted {
            game.resume(from: saved, mistakeLimit: mistakeLimit)
            return
        }
        Task {
            let difficulty = Difficulty.daily(for: DateKey.date(from: key) ?? Date())
            let seed = SplitMix64.seed(forDateKey: key)
            await game.startNew(
                difficulty: difficulty,
                isDaily: true,
                dateKey: key,
                seed: seed,
                mistakeLimit: mistakeLimit
            )
            persistDaily()
        }
    }

    private func persistDaily() {
        guard let puzzle = game.puzzle, game.isDaily, game.phase != .generating else { return }
        let key = game.dateKey
        // Fetch directly to avoid duplicate inserts across rapid persist() calls.
        let descriptor = FetchDescriptor<SavedGame>(
            predicate: #Predicate { $0.isDaily && $0.dateKey == key }
        )
        let existing = (try? modelContext.fetch(descriptor))?.first
        let isCompleted = (game.phase == .won)
        if let existing {
            existing.stateData = PuzzleService.encode(game.cells)
            existing.elapsedSeconds = game.elapsedSeconds
            existing.mistakes = game.mistakes
            existing.hintsUsed = game.hintsUsed
            existing.isCompleted = isCompleted
            existing.updatedAt = Date()
        } else {
            let saved = SavedGame(
                id: game.savedGameID,
                puzzleData: PuzzleService.encode(puzzle),
                stateData: PuzzleService.encode(game.cells),
                size: puzzle.size,
                difficulty: game.difficulty,
                elapsedSeconds: game.elapsedSeconds,
                mistakes: game.mistakes,
                hintsUsed: game.hintsUsed,
                isDaily: true,
                dateKey: key,
                isCompleted: isCompleted
            )
            modelContext.insert(saved)
        }
        try? modelContext.save()
    }

    private func recordDaily(key: String, won: Bool) {
        guard let puzzle = game.puzzle else { return }
        // Avoid duplicate result rows for the same daily.
        if results.contains(where: { $0.isDaily && $0.dateKey == key && $0.won }) {
            persistDaily()
            return
        }
        let result = PuzzleResult(
            size: puzzle.size,
            difficulty: game.difficulty,
            durationSeconds: game.elapsedSeconds,
            mistakes: game.mistakes,
            hintsUsed: game.hintsUsed,
            won: won,
            isDaily: true,
            dateKey: key
        )
        modelContext.insert(result)
        persistDaily()
        try? modelContext.save()
    }

    // MARK: Date helpers

    private func displayDate(_ key: String) -> String {
        guard let date = DateKey.date(from: key) else { return key }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func dayNumber(_ key: String) -> Int {
        guard let date = DateKey.date(from: key) else { return 0 }
        return Calendar(identifier: .gregorian).component(.day, from: date)
    }
}
