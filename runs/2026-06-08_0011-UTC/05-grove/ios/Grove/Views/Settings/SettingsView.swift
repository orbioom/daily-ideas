import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [FocusSession]

    @AppStorage("grove.haptics") private var haptics = true
    @AppStorage("grove.strict") private var strict = true
    @AppStorage("grove.keepAwake") private var keepAwake = true

    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Focus") {
                        Toggle("Strict mode (leaving withers tree)", isOn: $strict)
                        Toggle("Keep screen awake", isOn: $keepAwake)
                        Toggle("Haptics", isOn: $haptics)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                    }
                    Section("Data") {
                        HStack { Text("Sessions stored"); Spacer()
                            Text("\(sessions.count)").foregroundStyle(Brand.text2) }
                        Button(role: .destructive) { confirmReset = true } label: {
                            Label("Clear the grove", systemImage: "trash")
                        }
                    }
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Grove 1.0").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                            Text("Strict mode wilts your tree only if you fully leave Grove during a session. Everything stays on your device.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Clear the grove?", isPresented: $confirmReset) {
                Button("Delete", role: .destructive) {
                    for s in sessions { context.delete(s) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This removes every planted tree and your focus history. Tags are kept.") }
        }
    }
}
