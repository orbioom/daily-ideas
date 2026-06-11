import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("targetWPMLow") private var targetLow = 120.0
    @AppStorage("targetWPMHigh") private var targetHigh = 160.0
    @AppStorage("appearance") private var appearance = "system"
    @Query private var sessions: [SpeechSession]

    @State private var confirmDelete = false
    @State private var sampleLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Pace target") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Lower bound")
                            Spacer()
                            Text("\(Int(targetLow)) wpm")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $targetLow, in: 90...140, step: 5) { Text("Lower bound") }
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Upper bound")
                            Spacer()
                            Text("\(Int(targetHigh)) wpm")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $targetHigh, in: 145...190, step: 5) { Text("Upper bound") }
                    }
                    Text("Conversational presentations sit around 120–160 wpm. Live and post-take pace feedback uses this band.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Experience") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    Picker("Appearance", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section("Data") {
                    LabeledContent("Saved sessions", value: "\(sessions.count)")
                    Button("Load sample sessions") { loadSample() }
                        .disabled(sampleLoaded)
                    Button("Delete all sessions", role: .destructive) { confirmDelete = true }
                        .disabled(sessions.isEmpty)
                }
                Section("Privacy") {
                    Text("Podium requests on-device speech recognition whenever your iPhone supports it. Transcripts and scores never leave your device. There is no account and no analytics.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    LabeledContent("Version", value: "1.0")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme))
            .navigationTitle("Settings")
            .confirmationDialog("Delete all \(sessions.count) sessions?",
                                isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    for s in sessions { context.delete(s) }
                    sampleLoaded = false
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    /// Ten believable practice sessions showing improvement over two weeks.
    private func loadSample() {
        let calendar = Calendar.current
        let samples: [(daysAgo: Int, prompt: String, words: Int, seconds: Double,
                       fillers: [String: Int], score: Int)] = [
            (14, "Tell me about yourself", 148, 95, ["um": 9, "like": 6, "you know": 3], 38),
            (12, "Free talk", 210, 120, ["um": 7, "uh": 4, "basically": 2], 47),
            (11, "A hard problem", 180, 105, ["um": 6, "like": 4], 55),
            (9, "Pitch your idea", 235, 118, ["um": 4, "actually": 3], 62),
            (8, "The pause swap", 110, 62, ["um": 2], 71),
            (6, "Quarterly update", 198, 96, ["um": 3, "you know": 1], 69),
            (5, "Tell me about yourself", 162, 92, ["um": 2, "like": 1], 78),
            (3, "Wedding toast", 145, 80, ["um": 1], 84),
            (2, "Best advice you've received", 175, 88, ["like": 2], 81),
            (1, "Tell me about yourself", 158, 86, ["um": 1], 88),
        ]
        for s in samples {
            let date = calendar.date(byAdding: .day, value: -s.daysAgo, to: Date()) ?? Date()
            let wpm = Double(s.words) / (s.seconds / 60)
            let session = SpeechSession(
                date: date, duration: s.seconds,
                transcript: "Sample take — record your own to see a real transcript with fillers highlighted.",
                promptTitle: s.prompt, wordCount: s.words,
                fillerCount: s.fillers.values.reduce(0, +),
                wordsPerMinute: wpm,
                vocabularyDiversity: Double.random(in: 0.45...0.62),
                score: s.score, fillerBreakdown: s.fillers)
            context.insert(session)
        }
        sampleLoaded = true
        Haptics.success()
    }
}
