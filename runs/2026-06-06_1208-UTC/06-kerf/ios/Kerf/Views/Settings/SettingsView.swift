import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var projects: [Project]

    @AppStorage("lengthUnit") private var unitRaw = LengthUnit.mm.rawValue
    @AppStorage("defaultKerfMm") private var defaultKerfMm = 3.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Units", selection: $unitRaw) {
                        ForEach(LengthUnit.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Picker("Default kerf", selection: $defaultKerfMm) {
                        Text("2 mm").tag(2.0); Text("3 mm (⅛\")").tag(3.0); Text("3.2 mm").tag(3.2); Text("1.5 mm").tag(1.5)
                    }
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Library") {
                    LabeledContent("Projects", value: "\(projects.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample data", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Kerf runs entirely on your device. The optimizer uses best-fit-decreasing packing — a fast, near-optimal layout, not always the theoretical minimum.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every project, part, and stock board. This can't be undone.") }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo projects.") }
        }
    }

    private func deleteAll() {
        for p in projects { context.delete(p) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}
