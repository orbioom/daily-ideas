import SwiftUI
import SwiftData

struct SpriteSettingsView: View {
    @Query private var allPrefs: [SpritePrefs]
    @Environment(\.modelContext) private var context
    @State private var showProAlert = false

    private var prefs: SpritePrefs {
        if let p = allPrefs.first { return p }
        let p = SpritePrefs(); context.insert(p); return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Canvas") {
                    Toggle("Show Grid Lines", isOn: Binding(get: { prefs.showGrid }, set: { prefs.showGrid = $0 }))
                    Toggle("Haptic Feedback", isOn: Binding(get: { prefs.hapticsEnabled }, set: { prefs.hapticsEnabled = $0 }))
                }

                Section {
                    if prefs.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            Text("Sprite Pro — Active").fontWeight(.semibold)
                        }
                    } else {
                        Button { showProAlert = true } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro").fontWeight(.semibold)
                                    Text("64×64 canvas, custom palettes & animation frames").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("$2.99").fontWeight(.bold).foregroundStyle(.indigo)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: { Text("Sprite Pro") }

                Section("Export") {
                    LabeledContent("Format", value: "PNG (transparent)")
                    LabeledContent("Scale", value: "512px output")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Canvas Sizes", value: prefs.isPro ? "8, 16, 32, 64" : "8, 16, 32")
                }
            }
            .navigationTitle("Settings")
            .alert("Sprite Pro", isPresented: $showProAlert) {
                Button("Unlock — $2.99") {
                    prefs.isPro = true
                    if prefs.hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                }
                Button("Restore Purchase") { prefs.isPro = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Unlock 64×64 canvas, custom palette management, and animation frame support.")
            }
        }
    }
}
