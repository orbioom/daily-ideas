import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var prefs: [GomokuPrefs]
    @Environment(\.modelContext) private var ctx

    private var pref: GomokuPrefs {
        if let p = prefs.first { return p }
        let p = GomokuPrefs()
        ctx.insert(p)
        return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    Picker("Difficulty", selection: Binding(
                        get: { pref.difficulty },
                        set: { pref.difficulty = $0 }
                    )) {
                        Text("Easy").tag("Easy")
                        Text("Normal").tag("Normal")
                        Text("Hard").tag("Hard")
                    }
                    Picker("Play As", selection: Binding(
                        get: { pref.humanColor },
                        set: { pref.humanColor = $0 }
                    )) {
                        Text("Black (First)").tag("Black")
                        Text("White (Second)").tag("White")
                    }
                }
                Section("Display") {
                    Picker("Board Theme", selection: Binding(
                        get: { pref.boardTheme },
                        set: { pref.boardTheme = $0 }
                    )) {
                        Text("Classic (Wood)").tag("Classic")
                        Text("Dark").tag("Dark")
                        Text("Bamboo").tag("Bamboo")
                    }
                    Toggle("Show Coordinates", isOn: Binding(
                        get: { pref.showCoordinates },
                        set: { pref.showCoordinates = $0 }
                    ))
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: Binding(
                        get: { pref.hapticsEnabled },
                        set: { pref.hapticsEnabled = $0 }
                    ))
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Rules", value: "First to 5 in a row wins")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
