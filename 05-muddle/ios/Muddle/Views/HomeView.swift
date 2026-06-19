import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \DailyResult.timestamp, order: .reverse) private var results: [DailyResult]

    @State private var engine = MuddleEngine()
    @State private var todayEntry: WordEntry?
    @State private var alreadySolved = false
    @State private var showSolvedSheet = false

    var todayKey: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let entry = todayEntry {
                        if alreadySolved, let r = results.first(where: { $0.dayKey == todayKey }) {
                            solvedBanner(result: r)
                        } else {
                            categoryBadge(entry: entry)
                            hintBox
                            guessDisplay
                            tileGrid
                            controlRow
                        }
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Today's Muddle")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: setup)
            .sheet(isPresented: $showSolvedSheet) {
                if let entry = todayEntry {
                    SolvedSheet(entry: entry, engine: engine) {
                        showSolvedSheet = false
                        alreadySolved = true
                        saveResult(solved: true)
                    }
                }
            }
            .onChange(of: engine.state) { _, new in
                if new == .solved { showSolvedSheet = true }
            }
        }
    }

    // MARK: - Sub-views

    private func categoryBadge(entry: WordEntry) -> some View {
        HStack {
            Text(entry.category.emoji)
            Text(entry.category.label)
                .fontWeight(.semibold)
            Spacer()
            difficultyTag(entry.difficulty)
        }
        .padding(.horizontal)
    }

    private func difficultyTag(_ d: Difficulty) -> some View {
        let color: Color = d == .easy ? .green : d == .medium ? .orange : .red
        return Text(d.label)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color, in: Capsule())
    }

    @ViewBuilder
    private var hintBox: some View {
        if engine.hintsUsed > 0 {
            HStack {
                Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                Text("Starts with: \(engine.revealedPrefix)")
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var guessDisplay: some View {
        HStack(spacing: 8) {
            ForEach(0..<engine.targetWord.count, id: \.self) { i in
                let filled = i < engine.selectedIndices.count
                Text(filled ? String(engine.currentGuess[engine.currentGuess.index(engine.currentGuess.startIndex, offsetBy: i)]) : "_")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .frame(width: 40, height: 48)
                    .background(filled ? Color.purple.opacity(0.15) : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(filled ? .purple : .secondary)
            }
        }
    }

    private var tileGrid: some View {
        let cols = engine.scrambledLetters.count <= 6 ? 6 : 8
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(cols, engine.scrambledLetters.count)), spacing: 10) {
            ForEach(engine.scrambledLetters.indices, id: \.self) { i in
                let selected = engine.selectedIndices.contains(i)
                Button {
                    withAnimation(.spring(response: 0.2)) { engine.tap(index: i) }
                } label: {
                    Text(engine.scrambledLetters[i])
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .frame(width: 52, height: 52)
                        .background(selected ? Color.purple : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(selected ? .white : .primary)
                        .shadow(color: selected ? .purple.opacity(0.3) : .clear, radius: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
    }

    private var controlRow: some View {
        HStack(spacing: 16) {
            Button { withAnimation { engine.clear() } } label: {
                Label("Clear", systemImage: "xmark")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color(.systemGray5), in: Capsule())
            }
            .buttonStyle(.plain)

            Button { withAnimation { engine.shuffle() } } label: {
                Label("Shuffle", systemImage: "shuffle")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color(.systemGray5), in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                let _ = engine.useHint()
            } label: {
                Label("Hint (\(engine.hintsUsed)/\(engine.targetWord.count))", systemImage: "lightbulb")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func solvedBanner(result: DailyResult) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Already solved today!")
                .font(.title2.weight(.bold))
            Text("Word: \(result.word)")
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(spacing: 24) {
                statPill(label: "Time", value: formatTime(result.timeElapsed))
                statPill(label: "Hints", value: "\(result.hintsUsed)")
            }
            Text("Come back tomorrow for a new word!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 24))
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.weight(.bold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView("No Puzzle Today", systemImage: "puzzlepiece", description: Text("Check back soon!"))
    }

    // MARK: - Logic

    private func setup() {
        guard let entry = WordDatabase.dailyWord() else { return }
        todayEntry = entry
        alreadySolved = results.contains { $0.dayKey == todayKey }
        if !alreadySolved { engine.load(entry: entry) }
    }

    private func saveResult(solved: Bool) {
        guard let entry = todayEntry else { return }
        let r = DailyResult(
            date: Date(), word: entry.word, category: entry.category.rawValue,
            difficulty: entry.difficulty.rawValue, solved: solved,
            hintsUsed: engine.hintsUsed, timeElapsed: engine.timeElapsed
        )
        ctx.insert(r)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t)/60; let s = Int(t)%60
        return String(format: "%d:%02d", m, s)
    }
}
