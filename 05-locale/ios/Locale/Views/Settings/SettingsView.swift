import SwiftUI
import SwiftData

struct LocaleSettingsView: View {
    @Query private var allPrefs: [LocalePrefs]
    @Environment(\.modelContext) private var context
    @State private var showProAlert = false

    private var prefs: LocalePrefs {
        if let p = allPrefs.first { return p }
        let p = LocalePrefs(); context.insert(p); return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { prefs.hapticsEnabled },
                        set: { prefs.hapticsEnabled = $0 }
                    ))
                }

                Section {
                    if prefs.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Locale Pro — Active")
                                .fontWeight(.semibold)
                        }
                    } else {
                        Button {
                            showProAlert = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro")
                                        .fontWeight(.semibold)
                                    Text("Unlock Italian, German, Japanese & Portuguese")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("$2.99")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Locale Pro")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Languages", value: prefs.isPro ? "6" : "2 of 6")
                    LabeledContent("Phrases", value: "170+")
                }
            }
            .navigationTitle("Settings")
            .alert("Locale Pro", isPresented: $showProAlert) {
                Button("Unlock — $2.99") {
                    prefs.isPro = true
                    if prefs.hapticsEnabled {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
                Button("Restore Purchase") { prefs.isPro = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Unlock all 6 languages and 170+ phrases for a one-time purchase.")
            }
        }
    }
}
