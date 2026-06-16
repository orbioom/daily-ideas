import SwiftUI
import SwiftData

struct PropertyEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Property.createdAt) private var allProperties: [Property]

    /// nil = create new.
    let property: Property?
    var onSave: (String) -> Void

    @State private var name = ""
    @State private var address = ""
    @State private var type: PropertyType = .singleFamily
    @State private var purchasePrice = ""
    @State private var purchaseDate = Date()
    @State private var currentValue = ""
    @State private var downPayment = ""
    @State private var closingCosts = ""
    @State private var mortgageBalance = ""
    @State private var mortgagePayment = ""
    @State private var notes = ""
    @State private var validationMessage: String?

    private var isEditing: Bool { property != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Property name", text: $name)
                        .accessibilityLabel("Property name")
                    TextField("Address", text: $address, axis: .vertical)
                        .accessibilityLabel("Address")
                    Picker("Type", selection: $type) {
                        ForEach(PropertyType.allCases) { t in
                            Label(t.rawValue, systemImage: t.systemImage).tag(t)
                        }
                    }
                }

                Section("Purchase") {
                    moneyField("Purchase price", text: $purchasePrice)
                    DatePicker("Purchase date", selection: $purchaseDate, displayedComponents: .date)
                    moneyField("Down payment", text: $downPayment)
                    moneyField("Closing costs", text: $closingCosts)
                }

                Section("Current") {
                    moneyField("Current value", text: $currentValue)
                    moneyField("Mortgage balance", text: $mortgageBalance)
                    moneyField("Monthly P&I payment", text: $mortgagePayment)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                        .accessibilityLabel("Notes")
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(isEditing ? "Edit Property" : "New Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private func moneyField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.ink)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
                .accessibilityLabel(label)
        }
    }

    private func loadIfEditing() {
        guard let property, name.isEmpty else { return }
        name = property.name
        address = property.address
        type = property.type
        purchasePrice = decimalString(property.purchasePrice)
        purchaseDate = property.purchaseDate
        currentValue = decimalString(property.currentValue)
        downPayment = decimalString(property.downPayment)
        closingCosts = decimalString(property.closingCosts)
        mortgageBalance = decimalString(property.mortgageBalance)
        mortgagePayment = decimalString(property.mortgagePayment)
        notes = property.notes
    }

    private func decimalString(_ value: Decimal) -> String {
        let rounded = Money.round(value, scale: 2)
        var result = "\(rounded)"
        if result.hasSuffix(".0") { result = String(result.dropLast(2)) }
        return result
    }

    private func parse(_ text: String) -> Decimal {
        let cleaned = text.filter { $0.isNumber || $0 == "." }
        return Decimal(string: cleaned) ?? 0
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter a property name."
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        let value = parse(currentValue)
        guard value > 0 else {
            validationMessage = "Current value must be greater than zero."
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }

        if let property {
            property.name = trimmedName
            property.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            property.type = type
            property.purchasePrice = parse(purchasePrice)
            property.purchaseDate = purchaseDate
            property.currentValue = value
            property.downPayment = parse(downPayment)
            property.closingCosts = parse(closingCosts)
            property.mortgageBalance = parse(mortgageBalance)
            property.mortgagePayment = parse(mortgagePayment)
            property.notes = notes
        } else {
            let palette = Theme.identityPalette
            let index = allProperties.count % palette.count
            let new = Property(
                name: trimmedName,
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                purchasePrice: parse(purchasePrice),
                purchaseDate: purchaseDate,
                currentValue: value,
                downPayment: parse(downPayment),
                closingCosts: parse(closingCosts),
                mortgageBalance: parse(mortgageBalance),
                mortgagePayment: parse(mortgagePayment),
                colorHex: Int(palette[index]),
                notes: notes
            )
            context.insert(new)
        }

        do {
            try context.save()
            Haptics.notify(.success, enabled: settings.hapticsEnabled)
            onSave(trimmedName)
            dismiss()
        } catch {
            validationMessage = "Could not save. Please try again."
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
        }
    }
}
