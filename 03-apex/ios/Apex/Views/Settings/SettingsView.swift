import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var prefs: [AppPreferences]
    @Environment(\.modelContext) private var ctx
    private var pref: AppPreferences {
        if let p = prefs.first { return p }
        let p = AppPreferences()
        ctx.insert(p)
        return p
    }

    @State private var showProUpgrade = false

    var body: some View {
        Form {
            Section("Gameplay") {
                Toggle("Haptic Feedback", isOn: Binding(
                    get: { pref.hapticEnabled },
                    set: { pref.hapticEnabled = $0 }
                ))

                Toggle("Show Card Numbers", isOn: Binding(
                    get: { pref.showCardNumbers },
                    set: { pref.showCardNumbers = $0 }
                ))
                .accessibilityHint("Shows the numeric value on face cards for clarity")
            }

            Section("Appearance") {
                Picker("Table Theme", selection: Binding(
                    get: { pref.theme },
                    set: { pref.theme = $0 }
                )) {
                    Text("Classic Green").tag("classic")
                    Text("Midnight Blue").tag("midnight")
                    Text("Aged Burgundy").tag("burgundy")
                }
            }

            Section("Apex Pro") {
                if pref.isPro {
                    HStack {
                        Image(systemName: "star.fill").foregroundStyle(ApexTheme.gold)
                        Text("Apex Pro — Unlocked")
                            .foregroundStyle(ApexTheme.gold)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Unlock Apex Pro")
                            .font(.headline)
                        Text("• Extra table themes (Midnight, Burgundy)\n• Detailed per-game breakdown\n• Unlimited undo during play")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Unlock for $1.99") {
                        showProUpgrade = true
                    }
                    .foregroundStyle(ApexTheme.gold)
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Games Supported", value: "Pyramid Solitaire")
                Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Apex Pro", isPresented: $showProUpgrade) {
            Button("Purchase $1.99") { pref.isPro = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Unlock extra themes, detailed stats, and unlimited undo.\n(Simulated purchase for demo)")
        }
    }
}
