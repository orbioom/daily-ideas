import SwiftUI
import SwiftData

/// Create or edit a vet visit.
struct VetVisitFormView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings
    let visit: VetVisit?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date.now
    @State private var reason: VisitReason = .checkup
    @State private var clinic = ""
    @State private var vetName = ""
    @State private var diagnosis = ""
    @State private var notes = ""
    @State private var costText = ""
    @State private var hasFollowUp = false
    @State private var followUpDate = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section("Visit") {
                    DatePicker("Date", selection: $date, in: ...Date.now.addingTimeInterval(60), displayedComponents: .date)
                    Picker("Reason", selection: $reason) {
                        ForEach(VisitReason.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                }
                Section("Clinic") {
                    TextField("Clinic name", text: $clinic)
                    TextField("Veterinarian", text: $vetName)
                }
                Section("Outcome") {
                    TextField("Diagnosis", text: $diagnosis, axis: .vertical).lineLimit(1...3)
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
                    TextField("Cost (optional)", text: $costText)
                        .keyboardType(.decimalPad)
                }
                Section("Follow-up") {
                    Toggle("Schedule follow-up", isOn: $hasFollowUp.animation())
                    if hasFollowUp {
                        DatePicker("Follow-up date", selection: $followUpDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(visit == nil ? "New Visit" : "Edit Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let v = visit else { return }
        date = v.date
        reason = v.reason
        clinic = v.clinic
        vetName = v.vetName
        diagnosis = v.diagnosis
        notes = v.notes
        costText = v.cost > 0 ? String(format: "%.2f", v.cost) : ""
        if let f = v.followUpDate { hasFollowUp = true; followUpDate = f }
    }

    /// Parses cost defensively; invalid input becomes 0 rather than crashing.
    private var parsedCost: Double {
        let cleaned = costText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return max(0, Double(cleaned) ?? 0)
    }

    private func save() {
        if let v = visit {
            v.date = date
            v.reason = reason
            v.clinic = clinic.trimmingCharacters(in: .whitespacesAndNewlines)
            v.vetName = vetName.trimmingCharacters(in: .whitespacesAndNewlines)
            v.diagnosis = diagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
            v.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            v.cost = parsedCost
            v.followUpDate = hasFollowUp ? followUpDate : nil
        } else {
            let v = VetVisit(date: date, reason: reason,
                             clinic: clinic.trimmingCharacters(in: .whitespacesAndNewlines),
                             vetName: vetName.trimmingCharacters(in: .whitespacesAndNewlines),
                             diagnosis: diagnosis.trimmingCharacters(in: .whitespacesAndNewlines),
                             notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                             cost: parsedCost,
                             followUpDate: hasFollowUp ? followUpDate : nil)
            v.pet = pet
            context.insert(v)
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
