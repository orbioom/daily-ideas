import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsAll: [DaubSettings]
    @Query private var progressList: [PuzzleProgress]
    @Environment(\.modelContext) private var context

    @State private var showClearAlert = false

    var settings: DaubSettings {
        if let s = settingsAll.first { return s }
        let s = DaubSettings()
        context.insert(s)
        return s
    }

    var completedCount: Int { progressList.filter { $0.isCompleted }.count }
    var startedCount: Int { progressList.filter { !$0.isCompleted && $0.completionFraction(for: PuzzleCatalog.puzzle(id: $0.puzzleId) ?? PuzzleCatalog.all[0]) > 0 }.count }
    var totalTime: Int { progressList.reduce(0) { $0 + $1.timeSpentSeconds } }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Show Numbers in Cells", isOn: Binding(
                        get: { settings.showNumbers },
                        set: { v in settings.showNumbers = v; try? context.save() }
                    ))
                    Toggle("Highlight Selected Color", isOn: Binding(
                        get: { settings.highlightSelected },
                        set: { v in settings.highlightSelected = v; try? context.save() }
                    ))
                }

                Section("Haptics") {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { v in settings.hapticsEnabled = v; try? context.save() }
                    ))
                }

                Section("Your Progress") {
                    LabeledContent("Completed", value: "\(completedCount) / \(PuzzleCatalog.all.count)")
                    LabeledContent("In Progress", value: "\(startedCount)")
                    LabeledContent("Time Painting", value: formatTime(totalTime))
                }

                Section("Data") {
                    Button("Reset All Puzzle Progress", role: .destructive) {
                        showClearAlert = true
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Daub is a calming color-by-number app. No ads. No timers. No pressure. Your data stays on your device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Progress?", isPresented: $showClearAlert) {
                Button("Reset", role: .destructive) {
                    for p in progressList { context.delete(p) }
                    try? context.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All painting progress will be erased. This cannot be undone.")
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
