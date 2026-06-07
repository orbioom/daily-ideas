import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("useMetric") private var useMetric = true
    @AppStorage("defaultStartState") private var defaultStartRaw = StartState.fridge.rawValue
    @AppStorage("defaultLogReductions") private var defaultLogReductions = 6.5
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Query private var cooks: [Cook]
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Toggle("Celsius", isOn: $useMetric)
                        Picker("Default starting state", selection: $defaultStartRaw) {
                            ForEach(StartState.allCases) { s in Text(s.label).tag(s.rawValue) }
                        }
                        Picker("Pasteurization target", selection: $defaultLogReductions) {
                            Text("6.5-log").tag(6.5)
                            Text("7-log").tag(7.0)
                            Text("8-log").tag(8.0)
                        }
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    } header: { Text("Preferences") } footer: {
                        Text("More log reductions means a longer, safer hold. 6.5-log is a common home target for poultry.")
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        LabeledContent("Cooks logged", value: "\(cooks.count)")
                        LabeledContent("In progress",
                                       value: "\(cooks.filter { $0.state == .cooking }.count)")
                    } header: { Text("Your data") }
                        .listRowBackground(Color.clear)

                    Section {
                        Button("Replay intro") { hasOnboarded = false }.foregroundStyle(Brand.text)
                        Button(role: .destructive) { confirmClear = true } label: { Text("Clear all data") }
                    } header: { Text("Manage") }
                        .listRowBackground(Color.clear)

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Plateau").font(.headline).foregroundStyle(Brand.text)
                            Text("Sous-vide timing from first principles: heat-equation come-up times and a thermal-death-time pasteurization model. A cooking aid — when in doubt, hold longer.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Clear all data?", isPresented: $confirmClear) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every cook in progress and in your log. This cannot be undone.")
            }
        }
    }

    private func clearAll() {
        for c in cooks { context.delete(c) }
        try? context.save(); Haptics.warning()
    }
}
