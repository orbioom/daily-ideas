import SwiftUI
import SwiftData

struct GearEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var gear: GearItem?

    @State private var name = ""
    @State private var brand = ""
    @State private var category: GearCategory = .other
    @State private var weightValue = 0.0
    @State private var entryUnit = "g"        // g or oz, just for entry
    @State private var isWorn = false
    @State private var isConsumable = false
    @State private var notes = ""

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var grams: Double { entryUnit == "oz" ? weightValue * 28.3495 : weightValue }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Item")
                        TextField("Name", text: $name).textFieldStyle(.roundedBorder)
                        TextField("Brand (optional)", text: $brand).textFieldStyle(.roundedBorder)
                        HStack {
                            Text("Category").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("Category", selection: $category) {
                                ForEach(GearCategory.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Weight")
                        HStack(spacing: 10) {
                            TextField("0", value: $weightValue, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity)
                                .textFieldStyle(.roundedBorder)
                            Picker("Unit", selection: $entryUnit) {
                                Text("g").tag("g"); Text("oz").tag("oz")
                            }.pickerStyle(.segmented).frame(width: 100)
                        }
                        Text("Stored as \(String(format: "%.0f", grams)) g.")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "How it's carried")
                        Toggle("Worn / carried on body", isOn: $isWorn)
                            .onChange(of: isWorn) { _, v in if v { isConsumable = false } }
                        Divider().overlay(Brand.hairline)
                        Toggle("Consumable (food, water, fuel)", isOn: $isConsumable)
                            .onChange(of: isConsumable) { _, v in if v { isWorn = false } }
                        Text("Worn gear and consumables are kept out of your base weight.")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }.tint(Brand.live).glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Notes")
                        TextField("Optional", text: $notes, axis: .vertical)
                            .lineLimit(1...4).textFieldStyle(.roundedBorder)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle(gear == nil ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Brand.text2) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.tint(Brand.text).disabled(trimmed.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let gear else { return }
        name = gear.name
        brand = gear.brand
        category = gear.category
        weightValue = gear.weightGrams
        entryUnit = "g"
        isWorn = gear.isWorn
        isConsumable = gear.isConsumable
        notes = gear.notes
    }

    private func save() {
        let target = gear ?? GearItem(name: trimmed)
        target.name = trimmed
        target.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        target.category = category
        target.weightGrams = max(0, grams)
        target.isWorn = isWorn
        target.isConsumable = isConsumable
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if gear == nil { context.insert(target) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
