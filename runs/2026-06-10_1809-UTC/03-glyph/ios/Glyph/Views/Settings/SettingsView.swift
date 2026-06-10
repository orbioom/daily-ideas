import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var games: [SudokuGame]

    @AppStorage("highlightConflicts") private var highlightConflicts = true
    @AppStorage("autoRemoveNotes") private var autoRemoveNotes = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("appearance") private var appearance = "system"
    @State private var showClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Toggle("Highlight conflicts", isOn: $highlightConflicts)
                            .tint(Brand.live)
                        Toggle("Auto-remove pencil notes", isOn: $autoRemoveNotes)
                            .tint(Brand.live)
                    } header: {
                        Text("Gameplay")
                    } footer: {
                        Text("Conflicts mark a cell red when its number repeats in a row, column, or box. Auto-remove clears matching notes when you place a number.")
                    }

                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                            .tint(Brand.live)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                    }

                    Section {
                        Button(role: .destructive) { showClear = true } label: {
                            Label("Clear finished puzzles", systemImage: "trash")
                        }
                    } footer: {
                        Text("\(games.filter { $0.isComplete }.count) finished, \(games.filter { !$0.isComplete }.count) in progress. Clearing keeps your in-progress games.")
                    }

                    Section {
                        LabeledContent("Puzzles", value: "\(games.count)")
                        LabeledContent("Privacy", value: "On device only")
                        LabeledContent("Version", value: "1.0")
                    } header: {
                        Text("About")
                    } footer: {
                        Text("Glyph generates every puzzle on your device with a guaranteed-unique solution. No ads, no internet required.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .preferredColorScheme(resolvedScheme)
            .confirmationDialog("Clear finished puzzles?", isPresented: $showClear, titleVisibility: .visible) {
                Button("Clear", role: .destructive) { clearFinished() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes solved puzzles and their times from your stats.")
            }
        }
    }

    private var resolvedScheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    private func clearFinished() {
        for g in games where g.isComplete { context.delete(g) }
        try? context.save()
        Haptics.warning()
    }
}

#Preview {
    SettingsView().modelContainer(for: SudokuGame.self, inMemory: true)
}
