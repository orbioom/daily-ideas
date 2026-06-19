import SwiftUI
import SwiftData

struct StampSettingsView: View {
    @Query private var allPrefs: [StampPrefs]
    @Environment(\.modelContext) private var context
    @State private var showProAlert = false

    private var prefs: StampPrefs {
        if let p = allPrefs.first { return p }
        let p = StampPrefs(); context.insert(p); return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Haptic Feedback", isOn: Binding(get: { prefs.hapticsEnabled }, set: { prefs.hapticsEnabled = $0 }))
                }

                Section {
                    if prefs.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            Text("Stamp Pro — Active").fontWeight(.semibold)
                        }
                    } else {
                        Button { showProAlert = true } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro").fontWeight(.semibold)
                                    Text("Batch export, custom backgrounds & more").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("$1.99").fontWeight(.bold).foregroundStyle(.purple)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: { Text("Stamp Pro") }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Export", value: "PNG with transparency")
                }
            }
            .navigationTitle("Settings")
            .alert("Stamp Pro", isPresented: $showProAlert) {
                Button("Unlock — $1.99") {
                    prefs.isPro = true
                    if prefs.hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                }
                Button("Restore Purchase") { prefs.isPro = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Unlock batch export, custom background colors, and premium border styles.")
            }
        }
    }
}
