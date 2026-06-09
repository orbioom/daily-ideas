import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [DrillSession]
    @Query private var stats: [ItemStat]

    @AppStorage("tonic.onboarded") private var onboarded = true
    @AppStorage("tonic.haptics") private var haptics = true
    @AppStorage("tonic.volume") private var volume = 0.8
    @AppStorage("tonic.noteDuration") private var noteDuration = 0.6
    @AppStorage("tonic.waveform") private var waveform = Waveform.sine.rawValue
    @AppStorage("tonic.defaultRootMode") private var defaultRootMode = RootMode.fixedC.rawValue

    @State private var showResetConfirm = false

    var body: some View {
        Form {
            Section("Sound") {
                Button {
                    ToneSynth.shared.previewTone()
                    Haptics.tap()
                } label: {
                    Label("Play test tone", systemImage: "play.circle")
                }
                VStack(alignment: .leading) {
                    Text("Volume").font(.subheadline)
                    Slider(value: $volume, in: 0.1...1.0)
                        .accessibilityLabel("Volume")
                        .accessibilityValue("\(Int(volume * 100)) percent")
                }
                VStack(alignment: .leading) {
                    Text("Note length").font(.subheadline)
                    Slider(value: $noteDuration, in: 0.3...1.2)
                        .accessibilityLabel("Note length")
                        .accessibilityValue(String(format: "%.1f seconds", noteDuration))
                    Text(String(format: "%.1fs per note", noteDuration))
                        .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                }
                Picker("Waveform", selection: $waveform) {
                    ForEach(Waveform.allCases) { Text($0.label).tag($0.rawValue) }
                }
            }

            Section("Practice") {
                Picker("Default root", selection: $defaultRootMode) {
                    ForEach(RootMode.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Toggle("Interface haptics", isOn: $haptics)
            }

            Section("Your training") {
                LabeledContent("Sessions", value: "\(sessions.count)")
                LabeledContent("Items practiced", value: "\(stats.filter { $0.attempts > 0 }.count)")
            }

            Section {
                Button {
                    onboarded = false
                    Haptics.tap()
                } label: {
                    Label("Replay onboarding", systemImage: "arrow.counterclockwise")
                }
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Delete all data", systemImage: "trash")
                }
            } footer: {
                Text("Removes every session and mastery stat. Drills are kept. Everything stays on this device.")
            }

            Section {
                LabeledContent("Tonic", value: "1.0")
            } footer: {
                Text("Conjured, not just coded. Tones are synthesized on-device — no audio files, no downloads.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Delete all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete data", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every session and mastery stat. Drills are untouched.")
        }
    }

    private func deleteAll() {
        for s in sessions { context.delete(s) }
        for s in stats { context.delete(s) }
        try? context.save()
        Haptics.warning()
    }
}
