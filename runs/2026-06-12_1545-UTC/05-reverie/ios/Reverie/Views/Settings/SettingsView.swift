import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var dreams: [Dream]
    @Query private var signs: [DreamSign]

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("serifNarrative") private var serifNarrative = true
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    Toggle("Serif dream text", isOn: $serifNarrative).tint(Theme.accent)
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled).tint(Theme.accent)
                }
                Section {
                    LabeledContent("Dreams recorded", value: "\(dreams.count)")
                    LabeledContent("Dream signs", value: "\(signs.count)")
                    LabeledContent("Lucid dreams", value: "\(DreamEngine.lucidCount(dreams))")
                } header: {
                    Text("Your journal")
                }
                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Delete all dreams & signs", systemImage: "trash")
                    }
                } footer: {
                    Text("Your dreams are deeply personal — Reverie keeps every entry on this iPhone only, never uploaded.")
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Storage", value: "On-device (SwiftData)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bgPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .confirmationDialog("Delete every dream and sign?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { wipe() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func wipe() {
        for d in dreams { context.delete(d) }
        for s in signs { context.delete(s) }
        try? context.save()
        Haptics.success()
    }
}
