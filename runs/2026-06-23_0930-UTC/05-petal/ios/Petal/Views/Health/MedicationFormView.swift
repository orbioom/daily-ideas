import SwiftUI
import SwiftData

/// Create or edit a medication for a pet.
struct MedicationFormView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings
    let medication: Medication?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency: DoseFrequency = .daily
    @State private var nextDue = Date.now
    @State private var hasCourseEnd = false
    @State private var courseEnd = Calendar.current.date(byAdding: .day, value: 10, to: .now) ?? .now
    @State private var isActive = true
    @State private var notes = ""
    @State private var showValidation = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name (e.g. Apoquel)", text: $name)
                    TextField("Dosage (e.g. 16 mg)", text: $dosage)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(DoseFrequency.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section("Schedule") {
                    DatePicker("Next dose", selection: $nextDue, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Has end date", isOn: $hasCourseEnd.animation())
                    if hasCourseEnd {
                        DatePicker("Course ends", selection: $courseEnd, in: nextDue..., displayedComponents: .date)
                    }
                    Toggle("Active", isOn: $isActive)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                if showValidation && !isValid {
                    Label("Please enter a medication name.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.danger).font(.subheadline)
                }
            }
            .navigationTitle(medication == nil ? "New Medication" : "Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let med = medication else { return }
        name = med.name
        dosage = med.dosage
        frequency = med.frequency
        nextDue = med.nextDue
        if let end = med.courseEnd { hasCourseEnd = true; courseEnd = end }
        isActive = med.isActive
        notes = med.notes
    }

    private func save() {
        guard isValid else {
            withAnimation { showValidation = true }
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        if let med = medication {
            med.name = trimmedName
            med.dosage = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
            med.frequency = frequency
            med.nextDue = nextDue
            med.courseEnd = hasCourseEnd ? courseEnd : nil
            med.isActive = isActive
            med.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let med = Medication(name: trimmedName,
                                 dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
                                 frequency: frequency, nextDue: nextDue,
                                 courseEnd: hasCourseEnd ? courseEnd : nil,
                                 notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                                 isActive: isActive)
            med.pet = pet
            context.insert(med)
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
