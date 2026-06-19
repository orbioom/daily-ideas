import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var results: [DailyResult]
    @Query private var progresses: [PackProgress]

    var solvedCount: Int { results.filter { $0.solved }.count }
    var totalCount: Int { results.count }
    var avgHints: Double {
        guard !results.isEmpty else { return 0 }
        return Double(results.map { $0.hintsUsed }.reduce(0, +)) / Double(results.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Stats") {
                    statRow(label: "Daily Puzzles Solved", value: "\(solvedCount) / \(totalCount)")
                    statRow(label: "Average Hints Used", value: String(format: "%.1f", avgHints))
                    statRow(label: "Pack Words Completed", value: "\(packWordsCompleted)")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Words in Database", value: "\(WordDatabase.all.count)")
                    LabeledContent("Categories", value: "\(WordCategory.allCases.count)")
                }

                Section("App") {
                    Label("Muddle — Daily Word Unscramble", systemImage: "puzzlepiece.fill")
                        .foregroundStyle(.purple)
                    Text("A new word every day. Tap letter tiles to unscramble it!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var packWordsCompleted: Int {
        progresses.flatMap { $0.completedWords }.count
    }

    private func statRow(label: String, value: String) -> some View {
        LabeledContent(label, value: value)
    }
}
