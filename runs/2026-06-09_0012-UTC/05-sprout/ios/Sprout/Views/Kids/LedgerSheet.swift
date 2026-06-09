import SwiftUI
import SwiftData

struct LedgerSheet: View {
    let kid: Kid
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sprout.symbol") private var symbol = "$"

    enum Action: String, CaseIterable, Identifiable {
        case bonus = "Add bonus", payout = "Cash out", spend = "Record spend", add = "Add money", remove = "Remove money"
        var id: String { rawValue }
        var kind: LedgerKind {
            switch self {
            case .bonus: return .bonus
            case .payout: return .payout
            case .spend: return .spend
            case .add, .remove: return .adjustment
            }
        }
        var negative: Bool { self == .payout || self == .spend || self == .remove }
    }

    @State private var action: Action = .bonus
    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()

    private var amount: Double? {
        let v = Double(amountText.replacingOccurrences(of: ",", with: "."))
        guard let v, v > 0 else { return nil }
        return action.negative ? -v : v
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Action", selection: $action) {
                        ForEach(Action.allCases) { Text($0.rawValue).tag($0) }
                    }
                    HStack {
                        Text(symbol).foregroundStyle(Brand.text3).font(Brand.mono(20))
                        TextField("0", text: $amountText).keyboardType(.decimalPad).font(Brand.mono(20))
                    }
                } footer: {
                    Text("Current balance: \(Money.string(kid.balance, symbol: symbol))")
                }
                Section("Details") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    TextField("Note (optional)", text: $note, axis: .vertical).lineLimit(1...3)
                }
            }
            .navigationTitle("Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(amount == nil)
                }
            }
        }
    }

    private func save() {
        guard let amount else { return }
        let entry = LedgerEntry(date: date, amount: amount, kind: action.kind, note: note)
        entry.kid = kid
        context.insert(entry)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
