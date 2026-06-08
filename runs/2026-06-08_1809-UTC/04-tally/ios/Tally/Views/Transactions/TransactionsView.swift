import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var month = Date()
    @State private var search = ""
    @State private var editing: Transaction?
    @State private var showAdd = false
    private let cal = Calendar.current

    private var monthTxns: [Transaction] {
        let base = MoneyEngine.transactions(all, inMonth: month)
        guard !search.isEmpty else { return base }
        return base.filter {
            $0.note.localizedCaseInsensitiveContains(search)
                || $0.category.title.localizedCaseInsensitiveContains(search)
        }
    }

    private var grouped: [(day: Date, txns: [Transaction])] {
        let dict = Dictionary(grouping: monthTxns) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0]!.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    MonthBar(month: $month)
                    if monthTxns.isEmpty {
                        Spacer()
                        EmptyStateView(icon: "list.bullet.rectangle.portrait",
                                       title: search.isEmpty ? "No transactions" : "No matches",
                                       message: search.isEmpty ? "Add your first entry for this month."
                                                                : "Try a different search.")
                        Spacer()
                    } else {
                        List {
                            ForEach(grouped, id: \.day) { group in
                                Section {
                                    ForEach(group.txns) { t in
                                        Button { editing = t } label: {
                                            TransactionRow(txn: t, currency: currency)
                                        }
                                        .buttonStyle(.plain)
                                        .listRowBackground(Color.white.opacity(0.001))
                                    }
                                    .onDelete { offsets in delete(group.txns, at: offsets) }
                                } header: {
                                    HStack {
                                        Text(headerTitle(group.day)).foregroundStyle(Brand.text2)
                                        Spacer()
                                        Text(Money.format(dayTotal(group.txns), code: currency, showSign: true))
                                            .font(Brand.mono(11)).foregroundStyle(Brand.text3)
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .searchable(text: $search, prompt: "Search notes or categories")
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add transaction")
                }
            }
            .sheet(item: $editing) { t in TransactionEditorView(mode: .edit(t)) }
            .sheet(isPresented: $showAdd) { TransactionEditorView(mode: .create) }
        }
    }

    private func headerTitle(_ day: Date) -> String {
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return Format.dayFull.string(from: day)
    }

    private func dayTotal(_ txns: [Transaction]) -> Double {
        txns.reduce(0) { $0 + $1.signedAmount }
    }

    private func delete(_ txns: [Transaction], at offsets: IndexSet) {
        for i in offsets { context.delete(txns[i]) }
        try? context.save()
        Haptics.warning()
    }
}
