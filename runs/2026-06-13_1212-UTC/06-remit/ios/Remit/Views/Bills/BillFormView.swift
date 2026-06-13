import SwiftUI
import SwiftData

/// Add or edit a bill. Amount entry is Decimal-safe (parsed via a localized
/// formatter, never Double currency math).
struct BillFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = add mode; non-nil = edit mode.
    let bill: Bill?
    let currencyCode: String

    @State private var name: String
    @State private var amountText: String
    @State private var category: Category
    @State private var dueDate: Date
    @State private var recurrence: Recurrence
    @State private var autopay: Bool
    @State private var notes: String
    @State private var dueSoonDays: Int

    init(bill: Bill?, defaultRecurrence: Recurrence, defaultDueSoonDays: Int, currencyCode: String) {
        self.bill = bill
        self.currencyCode = currencyCode
        if let bill {
            _name = State(initialValue: bill.name)
            _amountText = State(initialValue: BillFormView.decimalString(bill.amount))
            _category = State(initialValue: bill.category)
            _dueDate = State(initialValue: bill.dueDate)
            _recurrence = State(initialValue: bill.recurrence)
            _autopay = State(initialValue: bill.autopay)
            _notes = State(initialValue: bill.notes)
            _dueSoonDays = State(initialValue: bill.dueSoonDays)
        } else {
            _name = State(initialValue: "")
            _amountText = State(initialValue: "")
            _category = State(initialValue: .housing)
            _dueDate = State(initialValue: Calendar.current.startOfDay(for: .now))
            _recurrence = State(initialValue: defaultRecurrence)
            _autopay = State(initialValue: false)
            _notes = State(initialValue: "")
            _dueSoonDays = State(initialValue: max(0, defaultDueSoonDays))
        }
    }

    private var parsedAmount: Decimal? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }
        // Decimal(string:) is locale-insensitive on "." and rejects garbage.
        guard let value = Decimal(string: cleaned), value >= 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && parsedAmount != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section("Bill") {
                        TextField("Name (e.g. Rent)", text: $name)
                        HStack {
                            Text(currencySymbol).foregroundStyle(Theme.inkSoft)
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("Amount")
                        }
                        Picker("Category", selection: $category) {
                            ForEach(Category.allCases) { c in
                                Label(c.label, systemImage: c.icon).tag(c)
                            }
                        }
                    }

                    Section("Schedule") {
                        DatePicker("Next due", selection: $dueDate, displayedComponents: .date)
                        Picker("Repeats", selection: $recurrence) {
                            ForEach(Recurrence.allCases) { Text($0.label).tag($0) }
                        }
                        Stepper(value: $dueSoonDays, in: 0...30) {
                            HStack {
                                Text("Remind window")
                                Spacer()
                                Text("\(dueSoonDays) day\(dueSoonDays == 1 ? "" : "s")")
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        Toggle("Autopay", isOn: $autopay)
                    }

                    Section("Notes") {
                        TextField("Optional notes", text: $notes, axis: .vertical)
                            .lineLimit(2...5)
                    }

                    if let parsedAmount, recurrence != .oneTime {
                        Section {
                            HStack {
                                Text("Monthly equivalent")
                                Spacer()
                                Text(Fmt.money(monthlyEquivalentPreview(parsedAmount), code: currencyCode))
                                    .foregroundStyle(Theme.accent)
                                    .font(Theme.rounded(15, .bold))
                            }
                        } footer: {
                            Text("How much this bill adds to your true monthly obligations.")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(bill == nil ? "New bill" : "Edit bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
        }
    }

    private var currencySymbol: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = currencyCode
        return fmt.currencySymbol ?? currencyCode
    }

    private func monthlyEquivalentPreview(_ amount: Decimal) -> Decimal {
        let perYear = recurrence.occurrencesPerYear
        guard perYear > 0 else { return 0 }
        return (amount * Decimal(perYear)) / 12
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let bill {
            bill.name = trimmedName
            bill.amount = amount
            bill.categoryRaw = category.rawValue
            bill.dueDate = dueDate
            bill.recurrenceRaw = recurrence.rawValue
            bill.autopay = autopay
            bill.notes = notes
            bill.dueSoonDays = max(0, dueSoonDays)
        } else {
            let newBill = Bill(name: trimmedName,
                               amount: amount,
                               category: category,
                               dueDate: dueDate,
                               recurrence: recurrence,
                               autopay: autopay,
                               notes: notes,
                               dueSoonDays: max(0, dueSoonDays))
            context.insert(newBill)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    /// Renders a Decimal as a plain editable string (no thousands separators).
    private static func decimalString(_ value: Decimal) -> String {
        var v = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &v, 2, .plain)
        return NSDecimalNumber(decimal: rounded).stringValue
    }
}
