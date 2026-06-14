import SwiftUI
import SwiftData

/// Add or edit a transaction. Handles the inflow/outflow sign, category, account,
/// date and cleared flag, with validation (numeric, non-zero amount, an account).
struct TransactionEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \Account.dateAdded) private var accounts: [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    private let existing: Transaction?
    private let preselectedAccount: Account?

    @State private var payee = ""
    @State private var amountText = ""
    @State private var isInflow = false
    @State private var note = ""
    @State private var cleared = true
    @State private var date = Date()
    @State private var selectedAccountID: UUID?
    @State private var selectedCategoryID: UUID?

    init(existing: Transaction? = nil, preselectedAccount: Account? = nil) {
        self.existing = existing
        self.preselectedAccount = preselectedAccount
    }

    private var trimmedPayee: String { payee.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var parsedMagnitude: Double? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value.isFinite, value > 0 else { return nil }
        return BudgetEngine.cents(value)
    }

    private var canSave: Bool {
        parsedMagnitude != nil && selectedAccountID != nil && !trimmedPayee.isEmpty
    }

    private var sortedCategories: [Category] {
        categories.sorted {
            if $0.group.sortRank != $1.group.sortRank { return $0.group.sortRank < $1.group.sortRank }
            return $0.sortOrder < $1.sortOrder
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                amountSection
                detailsSection
                if !isInflow { categorySection }
                Section {
                    Toggle("Cleared", isOn: $cleared)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(existing == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitial)
        }
    }

    private var amountSection: some View {
        Section {
            Picker("Type", selection: $isInflow) {
                Text("Outflow").tag(false)
                Text("Inflow").tag(true)
            }
            .pickerStyle(.segmented)

            HStack {
                Text(isInflow ? "+" : "−")
                    .font(Theme.money(20, .bold))
                    .foregroundStyle(isInflow ? Theme.good : Theme.bad)
                Text(settings.currencySymbol)
                    .font(Theme.money(18, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(Theme.money(22, .semibold))
                    .monospacedDigit()
            }
        } footer: {
            if !amountText.isEmpty && parsedMagnitude == nil {
                Text("Enter a positive amount.").foregroundStyle(Theme.bad)
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Payee", text: $payee)
            DatePicker("Date", selection: $date, displayedComponents: .date)
            Picker("Account", selection: $selectedAccountID) {
                Text("Select account").tag(UUID?.none)
                ForEach(accounts) { acct in
                    Text(acct.name).tag(UUID?.some(acct.id))
                }
            }
            TextField("Note (optional)", text: $note, axis: .vertical)
                .lineLimit(1...3)
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $selectedCategoryID) {
                Text("Uncategorized").tag(UUID?.none)
                ForEach(sortedCategories) { cat in
                    Text("\(cat.emoji) \(cat.name)").tag(UUID?.some(cat.id))
                }
            }
        }
    }

    private func loadInitial() {
        if let existing {
            payee = existing.payee
            amountText = String(format: "%.2f", abs(existing.amount))
            isInflow = existing.isInflow
            note = existing.note
            cleared = existing.cleared
            date = existing.date
            selectedAccountID = existing.accountRef?.id
            selectedCategoryID = existing.categoryRef?.id
        } else {
            selectedAccountID = preselectedAccount?.id ?? accounts.first?.id
        }
    }

    private func save() {
        guard let magnitude = parsedMagnitude,
              let accountID = selectedAccountID,
              let account = accounts.first(where: { $0.id == accountID }) else { return }

        let signed = isInflow ? magnitude : -magnitude
        // Income/inflow rows stay uncategorized; outflows may carry a category.
        let category = isInflow ? nil : categories.first(where: { $0.id == selectedCategoryID })

        if let existing {
            existing.payee = trimmedPayee
            existing.amount = signed
            existing.note = note
            existing.cleared = cleared
            existing.date = date
            existing.accountRef = account
            existing.categoryRef = category
        } else {
            let txn = Transaction(date: date,
                                  payee: trimmedPayee,
                                  amount: signed,
                                  note: note,
                                  cleared: cleared,
                                  categoryRef: category,
                                  accountRef: account)
            context.insert(txn)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
