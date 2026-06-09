import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [VitalEntry]

    @AppStorage("cuff.onboarded") private var onboarded = false
    @AppStorage("cuff.haptics") private var haptics = true
    @AppStorage("cuff.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("cuff.glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mgdl.rawValue
    @AppStorage("cuff.targetSystolic") private var targetSystolic = 120
    @AppStorage("cuff.targetDiastolic") private var targetDiastolic = 80

    @State private var showDeleteConfirm = false
    @State private var showResetConfirm = false

    var body: some View {
        Form {
            Section("Targets") {
                Stepper(value: $targetSystolic, in: 90...180, step: 1) {
                    LabeledContent("Target systolic") {
                        Text("\(targetSystolic) mmHg").font(Brand.mono(14, weight: .semibold))
                    }
                }
                .accessibilityValue("\(targetSystolic) millimeters of mercury")
                Stepper(value: $targetDiastolic, in: 50...120, step: 1) {
                    LabeledContent("Target diastolic") {
                        Text("\(targetDiastolic) mmHg").font(Brand.mono(14, weight: .semibold))
                    }
                }
                .accessibilityValue("\(targetDiastolic) millimeters of mercury")
            } footer: {
                Text("Used for the in-target percentage and the target line on charts.")
            }

            Section("Units") {
                Picker("Weight", selection: $weightUnitRaw) {
                    ForEach(WeightUnit.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("Glucose", selection: $glucoseUnitRaw) {
                    ForEach(GlucoseUnit.allCases) { Text($0.label).tag($0.rawValue) }
                }
            } footer: {
                Text("Readings are stored in kilograms and mg/dL and converted for display.")
            }

            Section("General") {
                Toggle("Interface haptics", isOn: $haptics)
            }

            Section("Your data") {
                LabeledContent("Total readings", value: "\(entries.count)")
                LabeledContent("Blood pressure",
                               value: "\(entries.filter { $0.kind == .bloodPressure }.count)")
            }

            Section {
                Button {
                    showResetConfirm = true
                } label: {
                    Label("Replay welcome", systemImage: "sparkles")
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete all data", systemImage: "trash")
                }
            } footer: {
                Text("Deleting removes every reading from this device. This cannot be undone.")
            }

            Section {
                LabeledContent("Cuff", value: "1.0")
            } footer: {
                Text("Cuff is a personal log, not a medical device; consult your clinician about any concerns. All data stays on this device. Conjured, not just coded.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Delete all data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every logged reading. This cannot be undone.")
        }
        .confirmationDialog("Replay the welcome screens?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Show welcome") { onboarded = false }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your readings are kept; you'll just see the intro again.")
        }
    }

    private func deleteAll() {
        for e in entries { context.delete(e) }
        try? context.save()
        Haptics.warning()
    }
}
