import SwiftUI
import SwiftData

struct SalvoSettingsView: View {
    @Query private var prefs: [SalvoPrefs]
    @Environment(\.modelContext) private var ctx

    private var pref: SalvoPrefs {
        if let p = prefs.first { return p }
        let p = SalvoPrefs()
        ctx.insert(p)
        return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("AI Difficulty") {
                    Picker("Difficulty", selection: Binding(
                        get: { pref.difficulty },
                        set: { pref.difficulty = $0 }
                    )) {
                        Text("Easy – Random shots").tag("Easy")
                        Text("Normal – Hunt & Target").tag("Normal")
                        Text("Hard – Checkerboard AI").tag("Hard")
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: Binding(
                        get: { pref.hapticsEnabled },
                        set: { pref.hapticsEnabled = $0 }
                    ))
                }
                Section("About") {
                    LabeledContent("Grid Size", value: "10×10")
                    LabeledContent("Ships", value: "5 (sizes 2–5)")
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
