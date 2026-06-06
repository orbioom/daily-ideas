import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var dives: [Dive]
    @Query private var sites: [DiveSite]

    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue
    @AppStorage("defaultO2") private var defaultO2 = 32
    @AppStorage("ppO2Limit") private var ppO2Limit = 1.4
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Units", selection: $unitRaw) {
                        ForEach(UnitSystem.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Stepper(value: $defaultO2, in: 21...40) {
                        HStack { Text("Default gas"); Spacer()
                            Text(BreathingGas(oxygenPercent: defaultO2).label).foregroundStyle(Brand.text2).font(Brand.mono(15)) }
                    }
                    Picker("Default ppO₂ limit", selection: $ppO2Limit) {
                        Text("1.4").tag(1.4); Text("1.6").tag(1.6)
                    }
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Library") {
                    LabeledContent("Dives", value: "\(dives.count)")
                    LabeledContent("Sites", value: "\(sites.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample data", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Fathom is a logbook and planning aid that runs entirely offline. It is not a dive computer; never dive on its numbers alone.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every dive and site. This can't be undone.") }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo logbook.") }
        }
    }

    private func deleteAll() {
        for d in dives { context.delete(d) }
        for s in sites { context.delete(s) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}
