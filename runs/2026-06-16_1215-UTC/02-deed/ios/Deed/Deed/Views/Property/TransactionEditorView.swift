import SwiftUI
import SwiftData

struct TransactionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let property: Property
    var onSave: () -> Void

    @State private var kind: TxnKind = .expense
    @State private var category: TxnCategory = .repairs
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var unitID: UUID?
    @State private var validationMessage: String?

    private var categories: [TxnCategory] {
        kind == .income ? TxnCategory.incomeCategories : TxnCategory.expenseCategories
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(TxnKind.allCases) { k in Text(k.rawValue).tag(k) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: kind) { _, newValue in
                        let options = newValue == .income ? TxnCategory.incomeCategories : TxnCategory.expenseCategories
                        if !options.contains(category), let first = options.first {
                            category = first
                        }
                    }
                }

                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(categories) { c in
                            Label(c.rawValue, systemImage: c.systemImage).tag(c)
                        }
                    }
                    HStack {
                        Text("Amount").foregroundStyle(Theme.ink)
                        Spacer()
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 140)
                            .accessibilityLabel("Amount")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                if !property.units.isEmpty {
                    Section("Unit (optional)") {
                        Picker("Unit", selection: $unitID) {
                            Text("Whole property").tag(UUID?.none)
                            ForEach(property.units.sorted { $0.label < $1.label }) { unit in
                                Text(unit.label).tag(UUID?.some(unit.id))
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
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
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func parse(_ text: String) -> Decimal {
        Decimal(string: text.filter { $0.isNumber || $0 == "." }) ?? 0
    }

    private func save() {
        let value = parse(amount)
        guard value > 0 else {
            validationMessage = "Amount must be greater than zero."
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        let txn = Txn(
            date: date,
            kind: kind,
            category: category,
            amount: value,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            unitID: unitID
        )
        txn.property = property
        property.transactions.append(txn)
        context.insert(txn)
        do {
            try context.save()
            Haptics.notify(.success, enabled: settings.hapticsEnabled)
            onSave()
            dismiss()
        } catch {
            validationMessage = "Could not save. Please try again."
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
        }
    }
}
