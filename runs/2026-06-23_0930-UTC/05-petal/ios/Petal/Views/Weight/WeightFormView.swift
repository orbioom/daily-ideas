import SwiftUI
import SwiftData

/// Logs a new weight entry for a pet, in the user's preferred unit.
struct WeightFormView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var valueText = ""
    @State private var date = Date.now
    @State private var notes = ""
    @State private var showValidation = false

    private var unit: WeightUnit { settings.preferredWeightUnit }

    /// Parsed, sanitised positive value; nil if invalid.
    private var parsedValue: Double? {
        let cleaned = valueText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let v = Double(cleaned), v > 0, v < 5000 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight (\(unit.longLabel))") {
                    HStack {
                        TextField("0.0", text: $valueText)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Weight value")
                        Text(unit.label).foregroundStyle(Theme.secondaryText)
                    }
                    DatePicker("Date", selection: $date, in: ...Date.now.addingTimeInterval(60), displayedComponents: .date)
                }
                Section("Notes") {
                    TextField("Optional (e.g. after grooming)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                if showValidation && parsedValue == nil {
                    Label("Enter a valid weight greater than zero.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.danger).font(.subheadline)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
    }

    private func save() {
        guard let value = parsedValue else {
            withAnimation { showValidation = true }
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        let kg = unit.toKilograms(value)
        let entry = WeightEntry(date: date, kilograms: kg,
                                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
        entry.pet = pet
        context.insert(entry)
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
