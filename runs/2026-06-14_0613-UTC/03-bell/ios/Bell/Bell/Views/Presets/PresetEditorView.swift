import SwiftUI
import SwiftData

/// Create or edit a custom preset. Includes a "ring bell" preview that uses a
/// short-lived SoundEngine, degrading to a haptic when audio is unavailable.
struct PresetEditorView: View {
    let preset: Preset?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var name = ""
    @State private var durationMin = 20
    @State private var warmupSec = 30
    @State private var intervalMin = 0
    @State private var bell: BellTone = .bowl
    @State private var ambient: Ambient = .none
    @State private var paywall: Pro.Reason?

    // Preview engine kept alive for the lifetime of the editor.
    @State private var previewSound = SoundEngine()

    private let durations = [0, 5, 10, 15, 20, 25, 30, 45, 60, 90]
    private var isEditing: Bool { preset != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Preset name", text: $name)
                }

                Section("Length") {
                    Picker("Duration", selection: $durationMin) {
                        ForEach(durations, id: \.self) { d in
                            Text(d == 0 ? "Open-ended" : "\(d) min").tag(d)
                        }
                    }
                    Stepper("Warmup: \(warmupSec)s", value: $warmupSec, in: 0...120, step: 5)
                    if durationMin > 0 {
                        Picker("Interval bell", selection: $intervalMin) {
                            Text("None").tag(0)
                            ForEach([5, 10, 15, 20], id: \.self) { Text("Every \($0) min").tag($0) }
                        }
                    }
                }

                Section("Bell") {
                    Picker("Bell", selection: $bell) {
                        ForEach(BellTone.allCases) { tone in
                            HStack {
                                Text(tone.displayName)
                                if tone.isPro && !isPro { Text("PRO").font(.caption2) }
                            }.tag(tone)
                        }
                    }
                    .onChange(of: bell) { _, new in
                        if new.isPro && !isPro { bell = .bowl; paywall = .bell }
                    }
                    Button {
                        previewBell()
                    } label: {
                        Label("Preview bell", systemImage: "bell")
                    }
                }

                Section("Soundscape") {
                    Picker("Ambient", selection: $ambient) {
                        ForEach(Ambient.allCases) { amb in
                            HStack {
                                Text(amb.displayName)
                                if amb.isPro && !isPro { Text("PRO").font(.caption2) }
                            }.tag(amb)
                        }
                    }
                    .onChange(of: ambient) { _, new in
                        if new.isPro && !isPro { ambient = .none; paywall = .ambient }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Preset" : "New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndClose() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
            .onAppear(perform: load)
            .onDisappear { previewSound.stop() }
        }
    }

    private func load() {
        guard let preset else { return }
        name = preset.name
        durationMin = preset.durationMin
        warmupSec = preset.warmupSec
        intervalMin = preset.intervalMin
        bell = preset.bellValue
        ambient = preset.ambientValue
    }

    private func previewBell() {
        Haptics.impact(.soft, enabled: settings.hapticsEnabled)
        let ok = previewSound.start()
        if ok && settings.soundEnabled {
            previewSound.ringBell(bell)
        } else {
            Haptics.bellCue(enabled: settings.hapticsEnabled)
        }
    }

    private func saveAndClose() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let preset {
            preset.name = trimmed
            preset.durationMin = durationMin
            preset.warmupSec = warmupSec
            preset.intervalMin = durationMin > 0 ? intervalMin : 0
            preset.ambientValue = ambient
            preset.bellValue = bell
        } else {
            let new = Preset(
                name: trimmed,
                durationMin: durationMin,
                warmupSec: warmupSec,
                intervalMin: durationMin > 0 ? intervalMin : 0,
                ambient: ambient,
                bellSound: bell,
                isBuiltIn: false,
                sortOrder: 100 + Int(Date().timeIntervalSince1970) % 100000
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}
