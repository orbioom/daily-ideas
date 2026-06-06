import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var runs: [Run]

    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @AppStorage("riegelExponent") private var exponent = 1.06
    @AppStorage("weeklyGoalKm") private var weeklyGoalKm = 40.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var goalText = ""
    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Units", selection: $unitRaw) {
                        ForEach(DistanceUnit.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    Picker("Riegel exponent", selection: $exponent) {
                        Text("1.04 (optimistic)").tag(1.04)
                        Text("1.06 (standard)").tag(1.06)
                        Text("1.08 (conservative)").tag(1.08)
                        Text("1.10 (cautious)").tag(1.10)
                    }
                    HStack {
                        Text("Weekly goal")
                        Spacer()
                        TextField("40", text: $goalText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 70)
                            .onChange(of: goalText) { _, v in if let g = Double(v), g >= 0 { weeklyGoalKm = g } }
                        Text("km").foregroundStyle(Brand.text3)
                    }
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Log") {
                    LabeledContent("Runs logged", value: "\(runs.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample runs", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all runs", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Stride runs entirely on your device. Predictions use Riegel's formula; training paces and VDOT follow Jack Daniels' running model. Estimates, not guarantees — trust your training.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onAppear { goalText = String(format: "%.0f", weeklyGoalKm) }
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all runs?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every logged run. This can't be undone.") }
            .alert("Reload sample runs?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current runs and restores the demo log.") }
        }
    }

    private func deleteAll() {
        for r in runs { context.delete(r) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}
