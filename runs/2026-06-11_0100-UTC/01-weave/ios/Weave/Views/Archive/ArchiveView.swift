import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Query private var attempts: [PuzzleAttempt]
    @Environment(\.modelContext) private var modelContext

    private let totalPuzzles = PuzzleBank.all.count

    var body: some View {
        List {
            Section {
                statsRow
            }
            Section("All Puzzles") {
                ForEach(0..<totalPuzzles, id: \.self) { id in
                    NavigationLink(destination: PuzzleView(puzzleId: id)) {
                        ArchiveRowView(
                            puzzleId: id,
                            attempt: attempts.first(where: { $0.puzzleId == id })
                        )
                    }
                }
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.large)
    }

    private var statsRow: some View {
        let solved = attempts.filter(\.solved).count
        let played = attempts.count
        return HStack(spacing: 24) {
            StatChip(label: "Played", value: "\(played)")
            StatChip(label: "Solved", value: "\(solved)")
            StatChip(label: "Win %",
                     value: played > 0 ? "\(Int(Double(solved)/Double(played)*100))%" : "—")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct ArchiveRowView: View {
    let puzzleId: Int
    let attempt: PuzzleAttempt?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Puzzle #\(puzzleId + 1)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                if let a = attempt {
                    Text(a.solved ? "Solved · \(4 - a.mistakesUsed)/4 mistakes left" :
                                   a.gaveUp ? "Gave up" : "In progress")
                        .font(.caption)
                        .foregroundStyle(a.solved ? WeaveTheme.green : .secondary)
                } else {
                    Text("Not played")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            statusIcon
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if let a = attempt {
            Image(systemName: a.solved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(a.solved ? WeaveTheme.green : .secondary)
        } else {
            Image(systemName: "circle")
                .foregroundStyle(.tertiary)
        }
    }
}

private struct StatChip: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .black, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
