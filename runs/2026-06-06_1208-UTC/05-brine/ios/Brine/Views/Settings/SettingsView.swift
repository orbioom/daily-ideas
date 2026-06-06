import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var tanks: [Tank]
    @Query private var readings: [Reading]

    @AppStorage("tempFahrenheit") private var tempF = false
    @AppStorage("salinitySG") private var salSG = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false
    @AppStorage("selectedTankID") private var selectedTankID = ""

    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Display units") {
                    Toggle("Temperature in °F", isOn: $tempF)
                    Toggle("Salinity as specific gravity", isOn: $salSG)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Library") {
                    LabeledContent("Tanks", value: "\(tanks.count)")
                    LabeledContent("Readings", value: "\(readings.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample data", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Brine runs entirely on your device. Target ranges follow common reef-keeping guidance — adjust to your own livestock's needs.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every tank, reading, dose, and task. This can't be undone.") }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo reef tank.") }
        }
    }

    private func deleteAll() {
        for t in tanks { context.delete(t) }
        try? context.save(); selectedTankID = ""; Haptics.warning()
    }
    private func reseed() {
        deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success()
    }
}
