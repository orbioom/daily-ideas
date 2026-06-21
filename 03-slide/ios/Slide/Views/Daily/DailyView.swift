import SwiftUI
import SwiftData

struct DailyView: View {
    @State private var puzzle: SlidePuzzle = SlideDaily.todayPuzzle()
    @State private var isSolved: Bool = false
    @Environment(\.modelContext) private var ctx
    @Query private var dailyResults: [SlideDailyResult]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var todayStr: String { SlideDaily.dateString() }
    private var todayResult: SlideDailyResult? { dailyResults.first { $0.dateString == todayStr } }
    private var streak: Int {
        var s = 0
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        var date = Date()
        while true {
            let str = fmt.string(from: date)
            guard dailyResults.contains(where: { $0.dateString == str && $0.solved }) else { break }
            s += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return s
    }

    var body: some View {
        ZStack {
            SlideTheme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                // Streak bar
                HStack {
                    Label("\(streak) day streak", systemImage: "flame.fill")
                        .foregroundStyle(SlideTheme.accent)
                        .font(.headline)
                    Spacer()
                    if let result = todayResult, result.solved {
                        Label("Solved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(SlideTheme.solved)
                    }
                }
                .padding(.horizontal)

                if let result = todayResult, result.solved {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(SlideTheme.solved)
                        Text("Today's puzzle solved!")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Solved in \(result.moves) moves")
                            .foregroundStyle(SlideTheme.textSecondary)
                        Text(String(format: "Time: %.0f seconds", result.seconds))
                            .foregroundStyle(SlideTheme.textSecondary)
                    }
                    .padding()
                    Spacer()
                } else {
                    TileGridView(
                        puzzle: $puzzle,
                        theme: .classic,
                        isSolved: $isSolved,
                        reduceMotion: reduceMotion
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
        }
        .navigationTitle("Daily Puzzle")
        .onChange(of: isSolved) { _, solved in
            if solved { saveDaily() }
        }
    }

    private func saveDaily() {
        // Only save if not already saved today
        guard todayResult == nil else { return }
        let r = SlideDailyResult(
            dateString: todayStr,
            solved: true,
            moves: puzzle.moves,
            seconds: puzzle.elapsedSeconds
        )
        ctx.insert(r)
        try? ctx.save()
    }
}
