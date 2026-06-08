import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var pregnancy: Pregnancy
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("bloom.haptics") private var haptics = true
    @AppStorage("bloom.kickTarget") private var kickTarget = 10

    @State private var weightText = ""
    @State private var heightText = ""
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Pregnancy") {
                    TextField("Baby's nickname", text: $pregnancy.babyName)
                    DatePicker("Due date", selection: $pregnancy.dueDate, displayedComponents: .date)
                    Toggle("Expecting multiples", isOn: $pregnancy.isMultiple)
                }

                Section("For weight-gain guidance") {
                    HStack {
                        Text("Pre-pregnancy weight")
                        Spacer()
                        TextField("kg", text: $weightText)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", text: $heightText)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    if let bmi = PregnancyEngine.bmi(weightKg: pregnancy.prePregnancyWeightKg, heightCm: pregnancy.heightCm) {
                        LabeledContent("Starting BMI",
                                       value: String(format: "%.1f (%@)", bmi,
                                                     PregnancyEngine.category(forBMI: bmi).rawValue))
                    }
                }

                Section("Tools") {
                    Stepper("Kick target: \(kickTarget)", value: $kickTarget, in: 5...20)
                }

                Section("Feel") {
                    Toggle("Haptics", isOn: $haptics)
                        .onChange(of: haptics) { _, new in Haptics.enabled = new }
                }

                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Reset everything", systemImage: "trash")
                    }
                } footer: {
                    Text("Bloom keeps all your data on this device only. Nothing leaves your phone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commit(); dismiss() }
                }
            }
            .onAppear {
                if pregnancy.prePregnancyWeightKg > 0 { weightText = String(format: "%.1f", pregnancy.prePregnancyWeightKg) }
                if pregnancy.heightCm > 0 { heightText = String(format: "%.0f", pregnancy.heightCm) }
            }
            .confirmationDialog("Reset Bloom?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete all data", role: .destructive, action: resetAll)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes your pregnancy and every log. This can't be undone.")
            }
        }
    }

    private func commit() {
        if let w = Double(weightText.replacingOccurrences(of: ",", with: ".")), w > 0 {
            pregnancy.prePregnancyWeightKg = w
        }
        if let h = Double(heightText.replacingOccurrences(of: ",", with: ".")), h > 0 {
            pregnancy.heightCm = h
        }
        try? context.save()
    }

    private func resetAll() {
        try? context.delete(model: SymptomEntry.self)
        try? context.delete(model: WeightEntry.self)
        try? context.delete(model: Appointment.self)
        try? context.delete(model: KickSession.self)
        try? context.delete(model: Contraction.self)
        try? context.delete(model: Pregnancy.self)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
