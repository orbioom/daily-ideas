import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var apiaries: [Apiary]
    @Query private var hives: [Hive]
    @Query private var inspections: [Inspection]

    @AppStorage("massUnit") private var massRaw = MassUnit.kg.rawValue
    @AppStorage("inspectionIntervalDays") private var inspectionInterval = 10
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Harvest units", selection: $massRaw) {
                        ForEach(MassUnit.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    Stepper("Inspection reminder: \(inspectionInterval)d",
                            value: $inspectionInterval, in: 3...30)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Library") {
                    LabeledContent("Apiaries", value: "\(apiaries.count)")
                    LabeledContent("Hives", value: "\(hives.count)")
                    LabeledContent("Inspections", value: "\(inspections.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample data", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Apiary runs entirely on your device. Queen colors follow the international marking standard; the varroa action threshold is ~3% (9 mites per 300-bee wash). Tasks flag treatment windows and hives overdue for a look.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every apiary, hive, and record. This can't be undone.") }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo apiaries.") }
        }
    }

    private func deleteAll() {
        for a in apiaries { context.delete(a) }
        // Cascade removes hives/records; clean up any orphans just in case.
        for h in hives { context.delete(h) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}
