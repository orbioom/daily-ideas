import SwiftUI
import SwiftData

struct AccountEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var account: Account?

    @State private var name = ""
    @State private var institution = ""
    @State private var type: AccountType = .asset
    @State private var assetClass: AssetClass = .cash
    @State private var balance = 0.0
    @State private var includeInNetWorth = true

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var classes: [AssetClass] {
        type == .liability ? [.debt] : AssetClass.investable
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Account")
                        TextField("Name (e.g. Roth IRA)", text: $name).textFieldStyle(.roundedBorder)
                        TextField("Institution (optional)", text: $institution).textFieldStyle(.roundedBorder)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Type")
                        Picker("Type", selection: $type) {
                            ForEach(AccountType.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented)
                        .onChange(of: type) { _, t in
                            assetClass = (t == .liability) ? .debt : .cash
                        }
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Asset class").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("Class", selection: $assetClass) {
                                ForEach(classes) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: type == .liability ? "Amount owed" : "Balance")
                        HStack {
                            Text("Value").foregroundStyle(Brand.text2).font(.subheadline)
                            Spacer()
                            TextField("0", value: $balance, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 130)
                                .textFieldStyle(.roundedBorder)
                        }
                        Toggle("Count toward net worth", isOn: $includeInNetWorth)
                            .tint(Brand.live).foregroundStyle(Brand.text)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle(account == nil ? "New account" : "Edit account")
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
        guard let account else { return }
        name = account.name
        institution = account.institution
        type = account.type
        assetClass = account.assetClass
        balance = account.balance
        includeInNetWorth = account.includeInNetWorth
    }

    private func save() {
        let target = account ?? Account(name: trimmed)
        target.name = trimmed
        target.institution = institution.trimmingCharacters(in: .whitespacesAndNewlines)
        target.type = type
        target.assetClass = assetClass
        target.balance = max(0, balance)
        target.includeInNetWorth = includeInNetWorth
        if account == nil { context.insert(target) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
