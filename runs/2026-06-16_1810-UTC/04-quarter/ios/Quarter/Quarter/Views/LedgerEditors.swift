import SwiftUI
import SwiftData

/// Add / edit an income entry.
struct IncomeEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let existing: IncomeEntry?

    @State private var label: String
    @State private var amountText: String
    @State private var date: Date
    @State private var source: IncomeSource
    @State private var isBusiness: Bool

    init(entry: IncomeEntry? = nil) {
        self.existing = entry
        _label = State(initialValue: entry?.label ?? "")
        _amountText = State(initialValue: entry.map { Self.plain($0.amount) } ?? "")
        _date = State(initialValue: entry?.date ?? .now)
        _source = State(initialValue: IncomeSource(rawValue: entry?.source ?? "1099") ?? .form1099)
        _isBusiness = State(initialValue: entry?.isBusiness ?? true)
    }

    private var amount: Double { Double(EstimateViewModel.parse(amountText).doubleValue) }
    private var isValid: Bool { amount > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Label (e.g. Client invoice)", text: $label)
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    Picker("Source", selection: $source) {
                        ForEach(IncomeSource.allCases) { s in
                            Label(s.rawValue, systemImage: s.systemImage).tag(s)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Business income", isOn: $isBusiness)
                }

                if !isValid && !amountText.isEmpty {
                    Section {
                        Label("Enter an amount greater than zero.", systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(Theme.warning)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Income" : "Edit Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        if let existing {
            existing.label = label
            existing.amount = amount
            existing.date = date
            existing.source = source.rawValue
            existing.isBusiness = isBusiness
        } else {
            let entry = IncomeEntry(label: label, amount: amount, date: date,
                                    source: source.rawValue, isBusiness: isBusiness)
            context.insert(entry)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private static func plain(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.2f", value)
    }
}

/// Add / edit an expense entry.
struct ExpenseEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let existing: ExpenseEntry?

    @State private var label: String
    @State private var amountText: String
    @State private var date: Date
    @State private var category: ExpenseCategory
    @State private var note: String

    init(entry: ExpenseEntry? = nil) {
        self.existing = entry
        _label = State(initialValue: entry?.label ?? "")
        _amountText = State(initialValue: entry.map { Self.plain($0.amount) } ?? "")
        _date = State(initialValue: entry?.date ?? .now)
        _category = State(initialValue: ExpenseCategory.from(entry?.category ?? ExpenseCategory.other.rawValue))
        _note = State(initialValue: entry?.note ?? "")
    }

    private var amount: Double { EstimateViewModel.parse(amountText).doubleValue }
    private var isValid: Bool { amount > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Label (e.g. New laptop)", text: $label)
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { c in
                            Label(c.rawValue, systemImage: c.systemImage).tag(c)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }

                if !isValid && !amountText.isEmpty {
                    Section {
                        Label("Enter an amount greater than zero.", systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(Theme.warning)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        if let existing {
            existing.label = label
            existing.amount = amount
            existing.date = date
            existing.category = category.rawValue
            existing.note = note
        } else {
            let entry = ExpenseEntry(label: label, amount: amount, date: date,
                                     category: category.rawValue, note: note)
            context.insert(entry)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private static func plain(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.2f", value)
    }
}
