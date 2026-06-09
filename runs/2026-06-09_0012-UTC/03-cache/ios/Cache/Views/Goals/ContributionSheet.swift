import SwiftUI
import SwiftData

struct ContributionSheet: View {
    let goal: Goal
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cache.symbol") private var symbol = "$"

    @State private var amountText = ""
    @State private var isWithdrawal = false
    @State private var date = Date()
    @State private var note = ""

    private var amount: Double? {
        let v = Double(amountText.replacingOccurrences(of: ",", with: "."))
        guard let v, v > 0 else { return nil }
        return isWithdrawal ? -v : v
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $isWithdrawal) {
                        Text("Deposit").tag(false)
                        Text("Withdrawal").tag(true)
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text(symbol).foregroundStyle(Brand.text3).font(Brand.mono(20))
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad).font(Brand.mono(20))
                    }
                }
                Section {
                    HStack {
                        ForEach([25, 50, 100, 250], id: \.self) { q in
                            Button("\(symbol)\(q)") {
                                Haptics.selection()
                                amountText = String(q)
                            }
                            .buttonStyle(.bordered)
                            .tint(goal.color.color)
                            .frame(maxWidth: .infinity)
                        }
                    }
                } header: { Text("Quick amounts") }

                Section("Details") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    TextField("Note (optional)", text: $note, axis: .vertical).lineLimit(1...3)
                }
            }
            .navigationTitle("Contribution")
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
        let c = Contribution(date: date, amount: amount, note: note)
        c.goal = goal
        context.insert(c)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
