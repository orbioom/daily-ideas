import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var prefs: [StipplePrefs]
    @Environment(\.modelContext) private var ctx
    @State private var showProAlert = false

    private var pref: StipplePrefs {
        if let p = prefs.first { return p }
        let p = StipplePrefs(); ctx.insert(p); return p
    }

    var body: some View {
        Form {
            Section("Coloring") {
                Toggle("Haptic Feedback", isOn: Binding(
                    get: { pref.hapticsEnabled },
                    set: { pref.hapticsEnabled = $0 }
                ))

                Toggle("Show Grid Lines", isOn: Binding(
                    get: { pref.showGridLines },
                    set: { pref.showGridLines = $0 }
                ))
                .accessibilityHint("Outlines each cell on the canvas")

                Toggle("Auto-Fill Adjacent", isOn: Binding(
                    get: { pref.autoFillAdjacent },
                    set: { pref.autoFillAdjacent = $0 }
                ))
                .accessibilityHint("Flood-fills all connected cells of the same color when you tap")
            }

            Section("Stipple Pro — $4.99") {
                if pref.isPro {
                    Label("Pro Unlocked — Thank you!", systemImage: "star.fill")
                        .foregroundStyle(Color("StippleAccent"))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Unlock 10 more scenes across all categories")
                            .font(.subheadline)
                        Text("Beach, Owl, Strawberry, Christmas Tree,\nRainbow, Balloon, Apple, Snowman, Pizza + more")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button("Unlock Stipple Pro") { showProAlert = true }
                        .foregroundStyle(Color("StippleAccent"))
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Scenes", value: "\(SceneLibrary.all.count) total")
                Link("Privacy", destination: URL(string: "https://orbioom.com/privacy")!)
            }
        }
        .navigationTitle("Settings")
        .alert("Stipple Pro", isPresented: $showProAlert) {
            Button("Purchase $4.99") { pref.isPro = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Unlock all 15 scenes and future content additions.\n(Simulated purchase for demo)")
        }
    }
}
