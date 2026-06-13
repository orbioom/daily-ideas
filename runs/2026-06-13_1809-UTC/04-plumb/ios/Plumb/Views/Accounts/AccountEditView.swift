import SwiftUI
import SwiftData

struct AccountEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = "USD"

    let account: Account?
    let nextIndex: Int

    @State private var name: String
    @State private var isAsset: Bool
    @State private var type: AccountType
    @State private var institution: String
    @State private var balanceText: String
    @State private var includeInNet: Bool

    init(account: Account?, nextIndex: Int) {
        self.account = account
        self.nextIndex = nextIndex
        _name = State(initialValue: account?.name ?? "")
        _isAsset = State(initialValue: account?.isAsset ?? true)
        _type = State(initialValue: account?.type ?? .checking)
        _institution = State(initialValue: account?.institution ?? "")
        _balanceText = State(initialValue: account.map { numString($0.balance) } ?? "")
        _includeInNet = State(initialValue: account?.includeInNetWorth ?? true)
    }

    private var balanceValue: Double { Double(balanceText) ?? -1 }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && balanceValue >= 0 && balanceValue <= 1_000_000_000 }
    private var typeOptions: [AccountType] { isAsset ? AccountType.assetTypes : AccountType.liabilityTypes }

    private var currencySymbol: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section {
                        Picker("Kind", selection: $isAsset) {
                            Text("Asset").tag(true); Text("Liability").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: isAsset) { _, asset in
                            if !typeOptions.contains(type) { type = asset ? .checking : .creditCard }
                        }
                    }
                    Section("Account") {
                        TextField("Name (e.g. Chase Checking)", text: $name)
                        Picker("Type", selection: $type) {
                            ForEach(typeOptions) { t in Label(t.label, systemImage: t.icon).tag(t) }
                        }
                        TextField("Institution — optional", text: $institution)
                    }
                    Section("Balance") {
                        HStack {
                            Text(isAsset ? "Current value" : "Amount owed")
                            Spacer()
                            Text(currencySymbol).foregroundStyle(Theme.inkSoft)
                            TextField("0", text: $balanceText).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).frame(maxWidth: 130)
                        }
                    }
                    Section {
                        Toggle("Include in net worth", isOn: $includeInNet)
                    } footer: {
                        Text("Turn off to keep an account visible without counting it (e.g. a shared account).")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(account == nil ? "Add account" : "Edit account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid).bold() }
            }
            .onAppear { if !typeOptions.contains(type) { type = isAsset ? .checking : .creditCard } }
        }
    }

    private func save() {
        guard isValid else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let account {
            account.name = trimmed
            account.type = type
            account.institution = institution
            account.includeInNetWorth = includeInNet
            if abs(account.balance - balanceValue) > 0.005 {
                account.balance = balanceValue
                account.updatedAt = Date()
                context.insert(BalanceEntry(accountID: account.id, balance: balanceValue))
            }
        } else {
            let acc = Account(name: trimmed, type: type, institution: institution,
                              balance: balanceValue, sortIndex: nextIndex)
            acc.includeInNetWorth = includeInNet
            context.insert(acc)
            context.insert(BalanceEntry(accountID: acc.id, balance: balanceValue, date: acc.createdAt))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

private func numString(_ value: Double) -> String {
    if value == value.rounded() { return String(Int(value)) }
    return String(format: "%.2f", value)
}
