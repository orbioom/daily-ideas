import SwiftUI
import SwiftData

struct AddDrinkView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var drinkType: DrinkType = .beer
    @State private var name = ""
    @State private var abv: Double = 5.0
    @State private var volumeML: Double = 355
    @State private var context: DrinkContext = .friends
    @State private var notes = ""
    @State private var cost: Double = 0

    private var standardDrinks: Double {
        (volumeML * (abv / 100.0) * 0.789) / 14.0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Drink") {
                    Picker("Type", selection: $drinkType) {
                        ForEach(DrinkType.allCases, id: \.self) {
                            Label($0.rawValue, systemImage: "")
                                .tag($0)
                        }
                    }
                    .onChange(of: drinkType) { _, new in
                        abv = new.defaultABV
                        volumeML = new.defaultVolumeML
                        if name.isEmpty || DrinkType.allCases.map(\.rawValue).contains(name) {
                            name = new.rawValue
                        }
                    }
                    .accessibilityLabel("Drink type")

                    TextField("Name (e.g. IPA, Merlot)", text: $name)
                        .accessibilityLabel("Drink name")
                }

                Section("Details") {
                    HStack {
                        Text("ABV")
                        Spacer()
                        Text(String(format: "%.1f%%", abv))
                            .foregroundStyle(DripTheme.subtle)
                    }
                    Slider(value: $abv, in: 0.5...70, step: 0.5)
                        .tint(DripTheme.accent)
                        .accessibilityLabel("ABV: \(String(format: "%.1f", abv)) percent")

                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(Int(volumeML)) mL")
                            .foregroundStyle(DripTheme.subtle)
                    }
                    Slider(value: $volumeML, in: 20...1000, step: 10)
                        .tint(DripTheme.accent)
                        .accessibilityLabel("Volume: \(Int(volumeML)) milliliters")

                    HStack {
                        Label("Standard drinks", systemImage: "drop.fill")
                        Spacer()
                        Text(String(format: "%.1f", standardDrinks))
                            .font(.headline)
                            .foregroundStyle(DripTheme.accent)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Standard drinks: \(String(format: "%.1f", standardDrinks))")
                }

                Section("Context") {
                    Picker("Setting", selection: $context) {
                        ForEach(DrinkContext.allCases, id: \.self) {
                            Text("\($0.emoji) \($0.rawValue)").tag($0)
                        }
                    }
                    .accessibilityLabel("Social context")

                    TextField("Notes (optional)", text: $notes)
                        .accessibilityLabel("Optional notes")
                }

                Section("Cost") {
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("0.00", value: $cost, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .accessibilityLabel("Drink cost")
                    }
                }
            }
            .navigationTitle("Log Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityHint("Save this drink to your log")
                }
            }
        }
        .onAppear {
            name = drinkType.rawValue
            abv = drinkType.defaultABV
            volumeML = drinkType.defaultVolumeML
        }
    }

    private func save() {
        let entry = DrinkEntry(
            drinkType: drinkType,
            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? drinkType.rawValue : name,
            abv: abv, volumeML: volumeML,
            context: context, notes: notes, cost: cost
        )
        ctx.insert(entry)
        dismiss()
    }
}

struct EditDrinkView: View {
    @Bindable var entry: DrinkEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            Form {
                Section("Drink") {
                    TextField("Name", text: Binding(get: { entry.name }, set: { entry.name = $0 }))
                    Picker("Type", selection: Binding(get: { entry.drinkTypeRaw }, set: { entry.drinkTypeRaw = $0 })) {
                        ForEach(DrinkType.allCases, id: \.self) { Text($0.rawValue).tag($0.rawValue) }
                    }
                }
                Section("Details") {
                    HStack { Text("ABV"); Spacer(); Text(String(format: "%.1f%%", entry.abv)).foregroundStyle(DripTheme.subtle) }
                    Slider(value: Binding(get: { entry.abv }, set: { entry.abv = $0 }), in: 0.5...70, step: 0.5).tint(DripTheme.accent)
                    HStack { Text("Volume"); Spacer(); Text("\(Int(entry.volumeML)) mL").foregroundStyle(DripTheme.subtle) }
                    Slider(value: Binding(get: { entry.volumeML }, set: { entry.volumeML = $0 }), in: 20...1000, step: 10).tint(DripTheme.accent)
                }
            }
            .navigationTitle("Edit Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { ctx.delete(entry); dismiss() } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}
