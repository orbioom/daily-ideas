import SwiftUI
import SwiftData

/// Create or edit a vaccination record.
struct VaccinationFormView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings
    let vaccination: Vaccination?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dateAdministered = Date.now
    @State private var hasNextDue = true
    @State private var nextDue = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
    @State private var clinic = ""
    @State private var lotNumber = ""
    @State private var notes = ""
    @State private var showValidation = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vaccine") {
                    TextField("Name (e.g. Rabies)", text: $name)
                    if name.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(CommonVaccine.allCases) { v in
                                    Button(v.label) { name = v.label }
                                        .font(.caption)
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                Section("Dates") {
                    DatePicker("Administered", selection: $dateAdministered, in: ...Date.now, displayedComponents: .date)
                    Toggle("Has booster due", isOn: $hasNextDue.animation())
                    if hasNextDue {
                        DatePicker("Booster due", selection: $nextDue, displayedComponents: .date)
                    }
                }
                Section("Details") {
                    TextField("Clinic", text: $clinic)
                    TextField("Lot number", text: $lotNumber)
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4)
                }
                if showValidation && !isValid {
                    Label("Please enter a vaccine name.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.danger).font(.subheadline)
                }
            }
            .navigationTitle(vaccination == nil ? "New Vaccination" : "Edit Vaccination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let vax = vaccination else { return }
        name = vax.name
        dateAdministered = vax.dateAdministered
        if let due = vax.nextDue { hasNextDue = true; nextDue = due } else { hasNextDue = false }
        clinic = vax.clinic
        lotNumber = vax.lotNumber
        notes = vax.notes
    }

    private func save() {
        guard isValid else {
            withAnimation { showValidation = true }
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        if let vax = vaccination {
            vax.name = trimmedName
            vax.dateAdministered = dateAdministered
            vax.nextDue = hasNextDue ? nextDue : nil
            vax.clinic = clinic.trimmingCharacters(in: .whitespacesAndNewlines)
            vax.lotNumber = lotNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            vax.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let vax = Vaccination(name: trimmedName, dateAdministered: dateAdministered,
                                  nextDue: hasNextDue ? nextDue : nil,
                                  clinic: clinic.trimmingCharacters(in: .whitespacesAndNewlines),
                                  lotNumber: lotNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                                  notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
            vax.pet = pet
            context.insert(vax)
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
