import SwiftUI
import SwiftData

struct AddGearView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let trip: CampTrip

    @State private var name = ""
    @State private var category: GearCategory = .other
    @State private var owned = true
    @State private var weight = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Gear Name", text: $name)
                        .accessibilityLabel("Gear item name")
                    Picker("Category", selection: $category) {
                        ForEach(GearCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    .accessibilityLabel("Gear category")
                }

                Section("Details") {
                    Toggle("I own this", isOn: $owned)
                        .accessibilityLabel("I own this item")
                    HStack {
                        Text("Weight (oz)")
                        Spacer()
                        TextField("0.0", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    .accessibilityLabel("Item weight in ounces")
                    TextField("Notes", text: $notes)
                        .accessibilityLabel("Notes")
                }
            }
            .navigationTitle("Add Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = GearItem(name: trimmed, category: category, trip: trip)
        item.owned = owned
        item.weight = Double(weight) ?? 0
        item.notes = notes
        context.insert(item)
        try? context.save()
        dismiss()
    }
}
