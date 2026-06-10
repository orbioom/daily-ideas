import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var results: [GameResult]

    @AppStorage("difficulty") private var difficultyRaw = Difficulty.medium.rawValue
    @AppStorage("duration") private var duration = 45
    @AppStorage("haptics") private var haptics = true
    @AppStorage("appearance") private var appearance = "system"
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Picker("Difficulty", selection: $difficultyRaw) {
                            ForEach(Difficulty.allCases) { d in Text(d.title).tag(d.rawValue) }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Difficulty")
                    } footer: {
                        Text("Harder settings widen the number ranges and multiply your score.")
                    }

                    Section {
                        Picker("Round length", selection: $duration) {
                            Text("30 sec").tag(30)
                            Text("45 sec").tag(45)
                            Text("60 sec").tag(60)
                            Text("90 sec").tag(90)
                        }
                    } header: {
                        Text("Round length")
                    } footer: {
                        Text("How long each timed game lasts.")
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
                        Button(role: .destructive) { showReset = true } label: {
                            Label("Reset all scores", systemImage: "trash")
                        }
                    } footer: {
                        Text("\(results.count) game results stored on this device.")
                    }

                    Section {
                        LabeledContent("Games played", value: "\(results.count)")
                        LabeledContent("Privacy", value: "On device only")
                        LabeledContent("Version", value: "1.0")
                    } header: {
                        Text("About")
                    } footer: {
                        Text("Cortex is free to train. No ads, no daily-game cap, no year-two price hike. Everything stays on your device.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .preferredColorScheme(resolvedScheme)
            .confirmationDialog("Reset all scores?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your game history and bests.")
            }
        }
    }

    private var resolvedScheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    private func reset() {
        for r in results { context.delete(r) }
        try? context.save()
        Haptics.warning()
    }
}

#Preview {
    SettingsView().modelContainer(for: GameResult.self, inMemory: true)
}
