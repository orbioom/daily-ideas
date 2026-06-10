import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var tunings: [Tuning]
    @Query private var presets: [MetronomePreset]

    @AppStorage("a4") private var a4 = 440
    @AppStorage("haptics") private var haptics = true
    @AppStorage("appearance") private var appearance = "system"
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Stepper(value: $a4, in: 415...466) {
                            HStack {
                                Text("A4 calibration")
                                Spacer()
                                Text("\(a4) Hz").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text2)
                            }
                        }
                        Button("Reset to 440 Hz") { a4 = 440 }
                            .disabled(a4 == 440)
                    } header: {
                        Text("Concert pitch")
                    } footer: {
                        Text("The reference frequency for A4. Standard is 440 Hz; some ensembles tune to 442 or 443.")
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
                            Label("Delete my custom tunings & presets", systemImage: "trash")
                        }
                    } footer: {
                        Text("\(tunings.filter { !$0.isBuiltIn }.count) custom tunings and \(presets.count) presets stored. Built-in tunings stay.")
                    }

                    Section {
                        LabeledContent("Built-in tunings", value: "\(tunings.filter { $0.isBuiltIn }.count)")
                        LabeledContent("Privacy", value: "Audio never recorded")
                        LabeledContent("Version", value: "1.0")
                    } header: {
                        Text("About")
                    } footer: {
                        Text("Pitch detects pitch on-device and never records audio. Every tuning and the metronome work fully free — no paywalled tunings, no ads.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .preferredColorScheme(resolvedScheme)
            .confirmationDialog("Delete custom data?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your custom tunings and metronome presets.")
            }
        }
    }

    private var resolvedScheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    private func reset() {
        for t in tunings where !t.isBuiltIn { context.delete(t) }
        for p in presets { context.delete(p) }
        try? context.save()
        Haptics.warning()
    }
}

#Preview {
    SettingsView().modelContainer(for: [Tuning.self, MetronomePreset.self], inMemory: true)
}
