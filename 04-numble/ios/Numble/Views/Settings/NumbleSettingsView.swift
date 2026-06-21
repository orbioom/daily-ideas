import SwiftUI
import SwiftData

struct NumbleSettingsView: View {
    @Query private var prefs: [NumblePrefs]
    @Environment(\.modelContext) private var ctx

    private var pref: NumblePrefs {
        if let p = prefs.first { return p }
        let p = NumblePrefs()
        ctx.insert(p)
        return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    Picker("Max Attempts", selection: Binding(
                        get: { pref.maxAttempts },
                        set: { pref.maxAttempts = $0 }
                    )) {
                        Text("4").tag(4)
                        Text("5").tag(5)
                        Text("6 (Default)").tag(6)
                    }
                    Toggle("Haptics", isOn: Binding(
                        get: { pref.hapticsEnabled },
                        set: { pref.hapticsEnabled = $0 }
                    ))
                }
                Section("About") {
                    LabeledContent("Equations in Pool", value: "\(numbleEquations.count)")
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
