import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var games: [WordGame]

    @AppStorage("hardMode") private var hardMode = false
    @AppStorage("haptics") private var haptics = true
    @AppStorage("appearance") private var appearance = "system"
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Toggle("Hard mode", isOn: $hardMode)
                            .tint(Brand.danger)
                    } header: {
                        Text("Challenge")
                    } footer: {
                        Text("In hard mode, any revealed hints must be used in your following guesses. Applies to new games.")
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

                    Section("How to play") {
                        bullet("Guess the five-letter word in six tries.")
                        bullet("🟩 Green: right letter, right spot.")
                        bullet("🟨 Yellow: right letter, wrong spot.")
                        bullet("⬛️ Gray: letter isn't in the word.")
                    }

                    Section {
                        Button(role: .destructive) { showReset = true } label: {
                            Label("Reset statistics", systemImage: "trash")
                        }
                    } footer: {
                        Text("\(games.count) games stored on this device. Resetting also clears your daily history.")
                    }

                    Section {
                        LabeledContent("Words", value: "\(WordList.words.count)")
                        LabeledContent("Privacy", value: "On device only")
                        LabeledContent("Version", value: "1.0")
                    } header: {
                        Text("About")
                    } footer: {
                        Text("Lexic is free, ad-free, and works offline. Play as many words as you like — no paywall on the puzzle.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .preferredColorScheme(resolvedScheme)
            .confirmationDialog("Reset statistics?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all your games and stats.")
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(Brand.text3)
            Text(text).font(.subheadline).foregroundStyle(Brand.text2)
        }
    }

    private var resolvedScheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    private func reset() {
        for g in games { context.delete(g) }
        try? context.save()
        Haptics.warning()
    }
}

#Preview {
    SettingsView().modelContainer(for: WordGame.self, inMemory: true)
}
