import SwiftUI
import SwiftData

struct RungSettingsView: View {
    @Query private var prefs: [RungPrefs]
    @Environment(\.modelContext) private var ctx

    private var pref: RungPrefs {
        if let p = prefs.first { return p }
        let p = RungPrefs()
        ctx.insert(p)
        return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    Picker("Max Hints Per Puzzle", selection: Binding(
                        get: { pref.showHintCount },
                        set: { pref.showHintCount = $0 }
                    )) {
                        Text("1").tag(1)
                        Text("3").tag(3)
                        Text("5").tag(5)
                        Text("Unlimited").tag(99)
                    }
                    Toggle("Haptics", isOn: Binding(
                        get: { pref.hapticsEnabled },
                        set: { pref.hapticsEnabled = $0 }
                    ))
                }
                Section("About") {
                    LabeledContent("Word List", value: "\(rungWordList.count) words")
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
