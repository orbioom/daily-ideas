import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var mixes: [Mix]

    @AppStorage("hush.haptics") private var haptics = true
    @AppStorage("hush.masterVolume") private var masterVolume = 0.9
    @AppStorage("hush.defaultLayerVolume") private var defaultLayerVolume = 0.7
    @AppStorage("hush.defaultFade") private var defaultFade = 30.0

    @State private var showResetConfirm = false

    private var customCount: Int { mixes.filter { !$0.isBuiltIn }.count }

    var body: some View {
        Form {
            Section("Volume") {
                VStack(alignment: .leading) {
                    Text("Master volume").font(.subheadline)
                    Slider(value: $masterVolume, in: 0...1)
                        .accessibilityLabel("Master volume")
                        .accessibilityValue(Format.percent(masterVolume))
                }
                VStack(alignment: .leading) {
                    Text("Default layer volume").font(.subheadline)
                    Slider(value: $defaultLayerVolume, in: 0.1...1)
                        .accessibilityLabel("Default layer volume")
                        .accessibilityValue(Format.percent(defaultLayerVolume))
                }
            }

            Section {
                VStack(alignment: .leading) {
                    Text("Fade-out length: \(Int(defaultFade)) s").font(.subheadline)
                    Slider(value: $defaultFade, in: 5...120, step: 5)
                        .accessibilityLabel("Sleep timer fade length")
                        .accessibilityValue("\(Int(defaultFade)) seconds")
                }
                Toggle("Interface haptics", isOn: $haptics)
            } header: {
                Text("Sleep timer")
            } footer: {
                Text("When the timer ends, the mix fades to silence over this many seconds.")
            }

            Section("Library") {
                LabeledContent("Saved mixes", value: "\(customCount)")
                LabeledContent("Built-in sounds", value: "\(SoundType.allCases.count)")
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Delete my saved mixes", systemImage: "trash")
                }
                .disabled(customCount == 0)
            } footer: {
                Text("Removes the mixes you've saved. Curated mixes are kept.")
            }

            Section {
                LabeledContent("Hush", value: "1.0")
            } footer: {
                Text("All sound is generated on-device. No streaming, no account, no ads. Conjured, not just coded.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Delete saved mixes?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete \(customCount) mix\(customCount == 1 ? "" : "es")", role: .destructive) {
                deleteCustom()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the mixes you created. Curated mixes stay.")
        }
    }

    private func deleteCustom() {
        for mix in mixes where !mix.isBuiltIn { context.delete(mix) }
        try? context.save()
        Haptics.warning()
    }
}
