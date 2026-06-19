import SwiftUI
import SwiftData

struct ScribeSettingsView: View {
    @Query private var allPrefs: [ScribePrefs]
    @Environment(\.modelContext) private var context
    @State private var showProAlert = false

    private var prefs: ScribePrefs {
        if let p = allPrefs.first { return p }
        let p = ScribePrefs(); context.insert(p); return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Haptic Feedback", isOn: Binding(get: { prefs.hapticsEnabled }, set: { prefs.hapticsEnabled = $0 }))
                    Toggle("Show Tile Values", isOn: Binding(get: { prefs.showTileValues }, set: { prefs.showTileValues = $0 }))
                }

                Section {
                    if prefs.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            Text("Scribe Pro — Active").fontWeight(.semibold)
                        }
                    } else {
                        Button {
                            showProAlert = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro").fontWeight(.semibold)
                                    Text("Extended word list & daily challenges").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("$3.99").fontWeight(.bold).foregroundStyle(.blue)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: { Text("Scribe Pro") }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Dictionary", value: "500+ words")
                    LabeledContent("Board", value: "15×15 Standard")
                }
            }
            .navigationTitle("Settings")
            .alert("Scribe Pro", isPresented: $showProAlert) {
                Button("Unlock — $3.99") {
                    prefs.isPro = true
                    if prefs.hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                }
                Button("Restore Purchase") { prefs.isPro = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Unlock an extended dictionary and daily challenges for a one-time purchase.")
            }
        }
    }
}
