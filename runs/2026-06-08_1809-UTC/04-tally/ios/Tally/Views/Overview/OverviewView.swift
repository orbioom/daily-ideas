import SwiftUI
import SwiftData
import Charts

struct OverviewView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @Query private var budgets: [BudgetItem]
    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var month = Date()
    @State private var showAdd = false
    @State private var showSettings = false

    private var monthTxns: [Transaction] { MoneyEngine.transactions(all, inMonth: month) }
    private var summary: MoneyEngine.MonthSummary { MoneyEngine.summary(monthTxns) }
    private var byCategory: [MoneyEngine.CategorySpend] { MoneyEngine.expenseByCategory(monthTxns) }
    private var projection: (avgPerDay: Double, projected: Double) {
        MoneyEngine.projection(monthTxns: monthTxns, month: month)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthBar(month: $month)
                    heroCard
                    if !byCategory.isEmpty { donutCard } else { emptyCategories }
                    recentCard
                }
                .padding(.bottom, 12)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Tally")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add transaction")
                }
            }
            .sheet(isPresented: $showAdd) { TransactionEditorView(mode: .create) }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Spent this month").font(.caption).foregroundStyle(Brand.text3)
                Text(Money.format(summary.expense, code: currency))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.text)
                    .minimumScaleFactor(0.6).lineLimit(1)
            }
            HStack(spacing: 0) {
                stat(Money.format(summary.income, code: currency), "income", Brand.live)
                Rectangle().fill(Brand.hairline).frame(width: 1, height: 32)
                stat(Money.format(summary.net, code: currency, showSign: true), "net",
                     summary.net >= 0 ? Brand.live : Brand.danger)
                Rectangle().fill(Brand.hairline).frame(width: 1, height: 32)
                stat(Money.format(projection.projected, code: currency), "projected", Brand.text)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
        .shadow(color: Brand.cardShadow, radius: 14, y: 8)
        .padding(.horizontal)
    }

    private func stat(_ value: String, _ label: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(tint)
                .minimumScaleFactor(0.5).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var donutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Where it went")
            Chart(byCategory) { slice in
                SectorMark(angle: .value("Amount", slice.amount),
                           innerRadius: .ratio(0.62), angularInset: 1.5)
                    .foregroundStyle(slice.category.color)
                    .cornerRadius(4)
            }
            .frame(height: 170)
            .accessibilityLabel("Donut chart of spending by category")

            ForEach(byCategory.prefix(5)) { slice in
                HStack(spacing: 10) {
                    Image(systemName: slice.category.icon).foregroundStyle(slice.category.color).frame(width: 22)
                    Text(slice.category.title).foregroundStyle(Brand.text)
                    Spacer()
                    Text(Money.format(slice.amount, code: currency))
                        .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(slice.category.title): \(Money.format(slice.amount, code: currency))")
            }
        }
        .glassCard()
        .padding(.horizontal)
    }

    private var emptyCategories: some View {
        EmptyStateView(icon: "tray",
                       title: "No spending yet",
                       message: "Tap + to log your first expense for this month.")
            .padding(.horizontal)
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "Recent")
                Spacer()
            }
            if monthTxns.isEmpty {
                Text("Nothing logged this month.").font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(monthTxns.prefix(6)) { t in
                    TransactionRow(txn: t, currency: currency)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding(.horizontal)
    }
}

struct TransactionRow: View {
    let txn: Transaction
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(txn.category.color.opacity(0.16)).frame(width: 38, height: 38)
                Image(systemName: txn.category.icon).foregroundStyle(txn.category.color).font(.subheadline)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(txn.note.isEmpty ? txn.category.title : txn.note)
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text).lineLimit(1)
                Text(Format.shortDate.string(from: txn.date))
                    .font(.caption2).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(Money.format(txn.signedAmount, code: currency, showSign: true))
                .font(Brand.mono(13, weight: .medium))
                .foregroundStyle(txn.isIncome ? Brand.live : Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(txn.note.isEmpty ? txn.category.title : txn.note), \(Money.format(txn.signedAmount, code: currency, showSign: true))")
    }
}
