import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("sensitivity") private var sensitivity = 14.0
    @AppStorage("appearance") private var appearance = "system"
    @Query private var sessions: [NightSession]
    @Query private var allFactors: [SleepFactor]

    @State private var showDeleteConfirm = false
    @State private var sampleLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Detection") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Sensitivity")
                            Spacer()
                            Text("\(Int(sensitivity)) dB")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $sensitivity, in: 8...24, step: 1) {
                            Text("Sensitivity")
                        }
                        Text("How far above the room's noise floor a sound must rise to count as snoring. Lower = more sensitive.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                    LabeledContent("Nights recorded", value: "\(sessions.count)")
                    Button("Load 14 sample nights") {
                        loadSampleData()
                    }
                    .disabled(sampleLoaded)
                    Button("Delete all nights", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .disabled(sessions.isEmpty)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Timber analyzes sound on your iPhone and stores only numbers — never audio. Nothing is uploaded, ever.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme))
            .navigationTitle("Settings")
            .confirmationDialog("Delete all \(sessions.count) nights?",
                                isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    for s in sessions { context.delete(s) }
                    sampleLoaded = false
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    /// Deterministic, realistic demo nights so every screen has data to show.
    private func loadSampleData() {
        var rng = SystemRandomNumberGenerator()
        let calendar = Calendar.current
        let factorsByName = Dictionary(uniqueKeysWithValues: allFactors.map { ($0.name, $0) })
        for daysAgo in 1...14 {
            guard let evening = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let start = calendar.date(bySettingHour: 23, minute: Int.random(in: 0...45, using: &rng),
                                      second: 0, of: evening) ?? evening
            let duration = TimeInterval(Int.random(in: 6 * 3600...(8 * 3600 + 1800), using: &rng))
            let end = start.addingTimeInterval(duration)

            let drank = daysAgo % 5 == 0
            let taped = daysAgo % 3 == 0
            var chosen: [SleepFactor] = []
            if drank, let f = factorsByName["Alcohol"] { chosen.append(f) }
            if taped, let f = factorsByName["Mouth tape"] { chosen.append(f) }
            if daysAgo % 4 == 0, let f = factorsByName["Slept on side"] { chosen.append(f) }

            // Heavier nights with alcohol, lighter with mouth tape.
            let episodeCount = max(0, (drank ? 9 : 4) - (taped ? 3 : 0) + Int.random(in: -2...2, using: &rng))
            var levels: [Double] = []
            let minutes = Int(duration / 60)
            for _ in 0..<minutes {
                levels.append(Double.random(in: 0.04...0.14, using: &rng))
            }
            let session = NightSession(startedAt: start, endedAt: end,
                                       levelSamples: levels,
                                       morningRating: Int.random(in: 2...5, using: &rng))
            context.insert(session)
            session.factors = chosen
            var cursor: TimeInterval = 1800
            for _ in 0..<episodeCount {
                cursor += TimeInterval(Int.random(in: 900...3200, using: &rng))
                guard cursor < duration - 600 else { break }
                let epDuration = TimeInterval(Int.random(in: 45...420, using: &rng))
                let peak = drank ? Double.random(in: -26 ... -12, using: &rng)
                                 : Double.random(in: -40 ... -22, using: &rng)
                let intensity: SnoreIntensity = peak > -18 ? .epic : peak > -30 ? .loud : .mild
                let ep = SnoreEpisode(startOffset: cursor, duration: epDuration,
                                      peakDB: peak, intensity: intensity)
                ep.session = session
                context.insert(ep)
                // Reflect the episode in the minute levels for a coherent chart.
                let startMin = Int(cursor / 60)
                let endMin = min(Int((cursor + epDuration) / 60), levels.count - 1)
                if startMin < levels.count, startMin <= endMin {
                    for m in startMin...endMin {
                        session.levelSamples[m] = min(0.95, 0.45 + Double.random(in: 0...0.35, using: &rng))
                    }
                }
                cursor += epDuration
            }
        }
        sampleLoaded = true
        Haptics.success()
    }
}
