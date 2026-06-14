import SwiftUI
import SwiftData

/// Quick one-off sit configuration that produces an in-memory preset to launch.
struct SessionSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Binding var activePreset: Preset?

    @State private var durationMin = 20
    @State private var warmupSec = 30
    @State private var intervalMin = 0
    @State private var bell: BellTone = .bowl
    @State private var ambient: Ambient = .none
    @State private var paywall: Pro.Reason?

    private let durations = [0, 5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        NavigationStack {
            Form {
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
                            ForEach([5, 10, 15], id: \.self) { Text("Every \($0) min").tag($0) }
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
            .navigationTitle("New Sit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Begin") { begin() }
                }
            }
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
            .onAppear { ambient = settings.defaultAmbientValue }
        }
    }

    private func begin() {
        let preset = Preset(
            name: durationMin == 0 ? "Open Sit" : "\(durationMin) min Sit",
            durationMin: durationMin,
            warmupSec: warmupSec,
            intervalMin: intervalMin,
            ambient: ambient,
            bellSound: bell,
            isBuiltIn: false,
            sortOrder: 999
        )
        dismiss()
        // Defer so the sheet finishes dismissing before the cover presents.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            activePreset = preset
        }
    }
}
