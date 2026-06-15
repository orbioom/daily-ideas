import SwiftUI
import SwiftData

struct AddEditTransactionView: View {
    let transaction: BankrollTransaction?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var date = Date()
    @State private var kind: TransactionKind = .deposit
    @State private var amountText = ""
    @State private var note = ""
    @State private var validationMessage: String?

    private var isEditing: Bool { transaction != nil }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.bad)
                    }
                }
                Section("Type") {
                    Picker("Type", selection: $kind) {
                        ForEach(TransactionKind.allCases) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.mono(16))
                    }
                    TextField("Note (optional)", text: $note)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit transaction" : "New transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private func loadIfEditing() {
        if let transaction {
            date = transaction.date
            kind = transaction.kind
            amountText = transaction.amount == 0 ? "" : Money.plain(transaction.amount, fractionDigits: 2)
            note = transaction.note
        }
    }

    private func save() {
        guard let amount = Money.parse(amountText) else {
            validationMessage = "Enter a valid amount."
            return
        }
        guard amount > 0 else {
            validationMessage = "Amount must be greater than zero."
            return
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let transaction {
            transaction.date = date
            transaction.kind = kind
            transaction.amount = amount
            transaction.note = trimmedNote
        } else {
            let new = BankrollTransaction(date: date, amount: amount, kind: kind, note: trimmedNote)
            modelContext.insert(new)
        }
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
