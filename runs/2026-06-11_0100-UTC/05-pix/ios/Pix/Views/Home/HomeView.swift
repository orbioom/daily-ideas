import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var allProgress: [PuzzleProgress]
    @State private var activePuzzle: NonogramPuzzle?
    @State private var activeVM: PixPuzzleViewModel?

    private var todayPuzzle: NonogramPuzzle { NonogramPuzzle.daily() }

    private var todayProgress: PuzzleProgress? {
        allProgress.first { $0.puzzleId == todayPuzzle.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    todayCard
                    statsRow
                    recentSection
                }
                .padding()
            }
            .navigationTitle("Pix")
            .background(Color(.systemGroupedBackground))
            .fullScreenCover(isPresented: Binding(
                get: { activeVM != nil },
                set: { if !$0 { activeVM = nil; activePuzzle = nil } }
            )) {
                if let vm = activeVM {
                    PuzzleView(vm: vm) { activeVM = nil; activePuzzle = nil }
                }
            }
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Pix")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(1)
                    Text(todayPuzzle.name)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    HStack(spacing: 6) {
                        Text("\(todayPuzzle.size)×\(todayPuzzle.size)")
                            .font(.caption.bold())
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(difficultyLabel(todayPuzzle.difficulty))
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(PixTheme.accent.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: todayProgress?.solved == true ? "checkmark.seal.fill" : "square.grid.3x3.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(PixTheme.accent)
                }
            }

            if let p = todayProgress, !p.solved {
                ProgressView(value: min(1.0, p.elapsedSeconds / 300))
                    .tint(PixTheme.accent)
                    .accessibilityLabel("Puzzle in progress")
            }

            Button(todayButtonLabel) {
                launchPuzzle(todayPuzzle)
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(todayProgress?.solved == true ? Color(.systemFill) : PixTheme.accent)
            .foregroundStyle(todayProgress?.solved == true ? Color.primary : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(todayProgress?.solved == true)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var todayButtonLabel: String {
        if todayProgress?.solved == true { return "Solved ✓" }
        if todayProgress != nil { return "Continue" }
        return "Play"
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(solvedCount)", label: "Solved")
            statTile(value: "\(streakCount)", label: "Streak")
            statTile(value: "\(PixPuzzleBank.all.count)", label: "Total")
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All Puzzles")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .padding(.horizontal, 4)

            ForEach(PixPuzzleBank.all) { puzzle in
                let prog = allProgress.first { $0.puzzleId == puzzle.id }
                puzzleRow(puzzle: puzzle, progress: prog)
            }
        }
    }

    private func puzzleRow(puzzle: NonogramPuzzle, progress: PuzzleProgress?) -> some View {
        Button {
            launchPuzzle(puzzle)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(puzzle.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("\(puzzle.size)×\(puzzle.size) · \(difficultyLabel(puzzle.difficulty))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if progress?.solved == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(PixTheme.accent)
                } else if progress != nil {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(PixTheme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var solvedCount: Int {
        Set(allProgress.filter { $0.solved }.map { $0.puzzleId }).count
    }

    private var streakCount: Int {
        var streak = 0
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: Date())
        while true {
            let dayPuzzle = NonogramPuzzle.puzzleForDate(date)
            let solved = allProgress.first { $0.puzzleId == dayPuzzle.id }?.solved == true
            if solved { streak += 1 } else { break }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }

    private func difficultyLabel(_ d: Int) -> String {
        switch d {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        default: return "Medium"
        }
    }

    private func launchPuzzle(_ puzzle: NonogramPuzzle) {
        let prog = allProgress.first { $0.puzzleId == puzzle.id }
        activeVM = PixPuzzleViewModel(puzzle: puzzle, progress: prog)
        activePuzzle = puzzle
    }
}
