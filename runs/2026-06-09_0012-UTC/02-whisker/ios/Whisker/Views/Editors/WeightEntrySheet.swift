import SwiftUI
import SwiftData

struct WeightEntrySheet: View {
    let pet: Pet
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("whisker.weightUnit") private var unitRaw = WeightUnit.kg.rawValue

    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var value: Double? {
        let v = Double(amount.replacingOccurrences(of: ",", with: "."))
        guard let v, v > 0, v < 2000 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    HStack {
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(Brand.mono(20))
                        Text(unit.label).foregroundStyle(Brand.text3)
                    }
                    if let last = pet.latestWeightKg {
                        Text("Last recorded: \(Format.weight(last, unit: unit))")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Section("When") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical).lineLimit(1...3)
                }
            }
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(value == nil)
                }
            }
        }
    }

    private func save() {
        guard let value else { return }
        let entry = WeightEntry(date: date, kilograms: unit.toKg(value), note: note)
        entry.pet = pet
        context.insert(entry)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
