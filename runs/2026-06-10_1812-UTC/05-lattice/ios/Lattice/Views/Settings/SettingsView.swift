import SwiftUI

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("highlightConflicts") private var highlightConflicts = true
    @AppStorage("highlightSame") private var highlightSame = true
    @AppStorage("autoRemoveNotes") private var autoRemoveNotes = true
    @AppStorage("limitMistakes") private var limitMistakes = true
    @AppStorage("showRemaining") private var showRemaining = true

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Toggle("Highlight conflicts", isOn: $highlightConflicts)
                        Toggle("Highlight matching numbers", isOn: $highlightSame)
                        Toggle("Auto-remove notes", isOn: $autoRemoveNotes)
                        Toggle("Show remaining counts", isOn: $showRemaining)
                    } header: { Text("Assists") } footer: {
                        Text("Tune how much help the board gives you while solving.")
                    }
                    Section {
                        Toggle("Limit to 3 mistakes", isOn: $limitMistakes)
                    } header: { Text("Challenge") } footer: {
                        Text("When on, a fourth wrong entry ends the game — just like the classics.")
                    }
                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                    }
                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }
                    Section {
                        EmptyView()
                    } footer: {
                        Text("Lattice is fully on-device and ad-free. Every puzzle is generated with a single guaranteed solution.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
