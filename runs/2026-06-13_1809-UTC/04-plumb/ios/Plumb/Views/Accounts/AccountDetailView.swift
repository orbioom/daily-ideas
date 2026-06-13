import SwiftUI
import SwiftData
import Charts

struct AccountDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allEntries: [BalanceEntry]
    @AppStorage("currencyCode") private var currencyCode = "USD"

    let account: Account

    @State private var showUpdate = false
    @State private var showEdit = false
    @State private var confirmDelete = false

    private var entries: [BalanceEntry] {
        allEntries.filter { $0.accountID == account.id }.sorted { $0.date < $1.date }
    }
    private var change: Double? {
        guard let first = entries.first, entries.count >= 2 else { return nil }
        return account.balance - first.balance
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if entries.count >= 2 { chartCard }
                    historyCard
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete account", systemImage: "trash")
                            .font(Theme.rounded(15, .semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Theme.bad.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Theme.bad)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showEdit = true } }
        }
        .sheet(isPresented: $showUpdate) { UpdateBalanceSheet(account: account) }
        .sheet(isPresented: $showEdit) { AccountEditView(account: account, nextIndex: account.sortIndex) }
        .alert("Delete this account?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the account and its balance history from your net worth.")
        }
    }

    private var headerCard: some View {
        Card(padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: account.type.icon).font(.system(size: 20))
                        .foregroundStyle(account.isAsset ? Theme.accent : Theme.bad)
                    Text(account.type.label).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    if !account.includeInNetWorth { Pill(text: "Excluded", color: Theme.inkFaint) }
                }
                Text((account.isAsset ? "" : "−") + Money.format(account.balance, code: currencyCode))
                    .font(Theme.rounded(34, .bold))
                    .foregroundStyle(account.isAsset ? Theme.ink : Theme.bad)
                    .minimumScaleFactor(0.5).lineLimit(1)
                HStack {
                    Text("Updated \(Fmt.relativeDay(account.updatedAt))")
                        .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    if let change { DeltaBadge(amount: account.isAsset ? change : -change, currency: currencyCode) }
                }
                Button { showUpdate = true } label: {
                    Label("Update balance", systemImage: "arrow.triangle.2.circlepath")
                        .font(Theme.rounded(15, .bold)).frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Balance history").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(entries) { e in
                    LineMark(x: .value("Date", e.date), y: .value("Balance", e.balance))
                        .foregroundStyle(account.isAsset ? Theme.accent : Theme.bad)
                        .interpolationMethod(.monotone)
                    PointMark(x: .value("Date", e.date), y: .value("Balance", e.balance))
                        .foregroundStyle(account.isAsset ? Theme.accent : Theme.bad)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel { if let v = value.as(Double.self) { Text(Money.compact(v, code: currencyCode)) } }
                    }
                }
                .frame(height: 160)
            }
        }
    }

    private var historyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Updates").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let reversed = entries.reversed().map { $0 }
                ForEach(reversed) { e in
                    HStack {
                        Text(e.date.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(Theme.rounded(14, .medium)).foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Text(Money.format(e.balance, code: currencyCode))
                            .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                    }
                    .padding(.vertical, 5)
                    if e.id != reversed.last?.id { Divider().background(Theme.hairline) }
                }
            }
        }
    }

    private func delete() {
        for e in entries { context.delete(e) }
        context.delete(account)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}

struct UpdateBalanceSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = "USD"
    let account: Account

    @State private var text: String = ""
    @State private var date = Date()

    private var value: Double { Double(text) ?? -1 }
    private var isValid: Bool { value >= 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section(account.isAsset ? "New value" : "New amount owed") {
                        HStack {
                            TextField("0", text: $text).keyboardType(.decimalPad)
                            Text(currencyCode).foregroundStyle(Theme.inkSoft)
                        }
                        DatePicker("As of", selection: $date, in: ...Date(), displayedComponents: .date)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Update balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        account.balance = value
                        account.updatedAt = date
                        context.insert(BalanceEntry(accountID: account.id, balance: value, date: date))
                        try? context.save(); Haptics.success(); dismiss()
                    }.disabled(!isValid).bold()
                }
            }
            .onAppear { text = numString(account.balance) }
        }
    }
}

private func numString(_ value: Double) -> String {
    if value == value.rounded() { return String(Int(value)) }
    return String(format: "%.2f", value)
}
