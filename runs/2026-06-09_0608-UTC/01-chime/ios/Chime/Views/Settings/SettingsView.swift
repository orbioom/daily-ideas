import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [MeditationSession]

    @AppStorage("chime.haptics") private var haptics = true
    @AppStorage("chime.hapticsOnBell") private var hapticsOnBell = true
    @AppStorage("chime.keepAwake") private var keepAwake = true
    @AppStorage("chime.bellVolume") private var bellVolume = 0.8
    @AppStorage("chime.previewBell") private var previewBellRaw = BellTone.bowl.rawValue

    @State private var showResetConfirm = false

    private var previewBell: BellTone {
        get { BellTone(rawValue: previewBellRaw) ?? .bowl }
        set { previewBellRaw = newValue.rawValue }
    }

    var body: some View {
        Form {
            Section("Bells") {
                Picker("Preview tone", selection: Binding(
                    get: { previewBell },
                    set: { previewBellRaw = $0.rawValue })) {
                    ForEach(BellTone.allCases) { Text($0.label).tag($0) }
                }
                Button {
                    BellPlayer.shared.play(previewBell)
                    Haptics.tap()
                } label: {
                    Label("Play preview", systemImage: "play.circle")
                }
                VStack(alignment: .leading) {
                    Text("Bell volume").font(.subheadline)
                    Slider(value: $bellVolume, in: 0.1...1.0)
                        .accessibilityLabel("Bell volume")
                        .accessibilityValue("\(Int(bellVolume * 100)) percent")
                }
            }

            Section("Session") {
                Toggle("Keep screen awake", isOn: $keepAwake)
                Toggle("Haptic on each bell", isOn: $hapticsOnBell)
                Toggle("Interface haptics", isOn: $haptics)
            }

            Section("Practice") {
                LabeledContent("Total sits", value: "\(sessions.count)")
                LabeledContent("Total time",
                               value: Format.duration(sessions.reduce(0) { $0 + $1.actualSeconds }))
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Clear all history", systemImage: "trash")
                }
            } footer: {
                Text("Removes logged sits. Presets are kept. Everything stays on this device.")
            }

            Section {
                LabeledContent("Chime", value: "1.0")
            } footer: {
                Text("Conjured, not just coded. All data is stored on-device.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Clear all history?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Clear history", role: .destructive) { clearHistory() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every logged sit. Presets are untouched.")
        }
    }

    private func clearHistory() {
        for s in sessions { context.delete(s) }
        try? context.save()
        Haptics.warning()
    }
}
