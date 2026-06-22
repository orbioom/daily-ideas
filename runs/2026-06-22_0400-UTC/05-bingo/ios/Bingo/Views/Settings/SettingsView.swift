import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [BingoSettings]
    @Query(sort: \BingoGame.date, order: .reverse) private var games: [BingoGame]
    @State private var showResetAlert = false

    var settings: BingoSettings {
        if let s = settingsQuery.first { return s }
        let s = BingoSettings()
        modelContext.insert(s)
        try? modelContext.save()
        return s
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BingoTheme.navy.ignoresSafeArea()

                Form {
                    Section(header: Text("CALLER").foregroundColor(BingoTheme.gold)) {
                        Toggle(isOn: Binding(
                            get: { settings.speechEnabled },
                            set: { settings.speechEnabled = $0; save() }
                        )) {
                            Label("Voice Announcements", systemImage: "speaker.wave.2.fill")
                                .foregroundColor(.white)
                        }
                        .tint(BingoTheme.gold)
                        .listRowBackground(BingoTheme.lightNavy)

                        Toggle(isOn: Binding(
                            get: { settings.autoAdvance },
                            set: { settings.autoAdvance = $0; save() }
                        )) {
                            Label("Auto-Advance", systemImage: "timer")
                                .foregroundColor(.white)
                        }
                        .tint(BingoTheme.gold)
                        .listRowBackground(BingoTheme.lightNavy)

                        if settings.autoAdvance {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Call Delay")
                                    .foregroundColor(.white)
                                Picker("", selection: Binding(
                                    get: { settings.callDelaySeconds },
                                    set: { settings.callDelaySeconds = $0; save() }
                                )) {
                                    Text("3 seconds").tag(3.0)
                                    Text("5 seconds").tag(5.0)
                                    Text("8 seconds").tag(8.0)
                                }
                                .pickerStyle(.segmented)
                            }
                            .listRowBackground(BingoTheme.lightNavy)
                        }
                    }

                    Section(header: Text("CARDS").foregroundColor(BingoTheme.gold)) {
                        HStack {
                            Text("Cards Per Game")
                                .foregroundColor(.white)
                            Spacer()
                            Stepper("\(settings.cardCount)", value: Binding(
                                get: { settings.cardCount },
                                set: { settings.cardCount = $0; save() }
                            ), in: 1...4)
                            .foregroundColor(BingoTheme.gold)
                        }
                        .listRowBackground(BingoTheme.lightNavy)
                    }

                    Section(header: Text("WIN PATTERNS").foregroundColor(BingoTheme.gold)) {
                        ForEach(["row", "column", "diagonal", "corners", "blackout"], id: \.self) { pattern in
                            Toggle(isOn: Binding(
                                get: { settings.winPatterns.contains(pattern) },
                                set: { on in
                                    if on {
                                        if !settings.winPatterns.contains(pattern) {
                                            settings.winPatterns.append(pattern)
                                        }
                                    } else {
                                        settings.winPatterns.removeAll { $0 == pattern }
                                    }
                                    save()
                                }
                            )) {
                                Text(pattern.capitalized)
                                    .foregroundColor(.white)
                            }
                            .tint(BingoTheme.gold)
                            .listRowBackground(BingoTheme.lightNavy)
                        }
                    }

                    Section(header: Text("FEEDBACK").foregroundColor(BingoTheme.gold)) {
                        Toggle(isOn: Binding(
                            get: { settings.hapticsEnabled },
                            set: { settings.hapticsEnabled = $0; save() }
                        )) {
                            Label("Haptic Feedback", systemImage: "waveform.path")
                                .foregroundColor(.white)
                        }
                        .tint(BingoTheme.gold)
                        .listRowBackground(BingoTheme.lightNavy)
                    }

                    Section {
                        Button(role: .destructive, action: { showResetAlert = true }) {
                            Label("Reset All Stats", systemImage: "trash")
                                .foregroundColor(BingoTheme.red)
                        }
                        .listRowBackground(BingoTheme.lightNavy)
                    }

                    Section(header: Text("ABOUT").foregroundColor(BingoTheme.gold)) {
                        HStack {
                            Text("Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .listRowBackground(BingoTheme.lightNavy)

                        Text("Made with ♥ for bingo lovers everywhere")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                            .listRowBackground(BingoTheme.lightNavy)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(BingoTheme.navy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Reset Stats?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { resetStats() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all game history. This cannot be undone.")
            }
        }
    }

    private func save() {
        try? modelContext.save()
    }

    private func resetStats() {
        for game in games {
            modelContext.delete(game)
        }
        try? modelContext.save()
    }
}
