import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    @Query private var sets: [SetEntry]

    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("oneRMFormula") private var formulaRaw = OneRepMaxFormula.epley.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Weight unit", selection: $unitRaw) {
                        ForEach(WeightUnit.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Picker("1RM formula", selection: $formulaRaw) {
                        ForEach(OneRepMaxFormula.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Library") {
                    LabeledContent("Sessions", value: "\(workouts.count)")
                    LabeledContent("Lifts", value: "\(exercises.count)")
                    LabeledContent("Sets logged", value: "\(sets.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample data", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Forge stays entirely on your device. e1RM uses the Epley or Brzycki formula — estimates, not maxes to attempt blindly.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every session, lift, and set. This can't be undone.") }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo program.") }
        }
    }

    private func deleteAll() {
        for w in workouts { context.delete(w) }
        for e in exercises { context.delete(e) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() {
        deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success()
    }
}
