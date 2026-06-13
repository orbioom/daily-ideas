import SwiftUI
import SwiftData

struct MoneyView: View {
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @Environment(\.modelContext) private var context
    @Query(sort: \RecurringItem.amount, order: .reverse) private var recurring: [RecurringItem]
    @Query(sort: \OneOffItem.date) private var oneOffs: [OneOffItem]

    @State private var tab = 0
    @State private var editingRecurring: RecurringItem?
    @State private var editingOneOff: OneOffItem?
    @State private var addingRecurring = false
    @State private var addingOneOff = false

    private var income: [RecurringItem] { recurring.filter { $0.kind == .income } }
    private var bills: [RecurringItem] { recurring.filter { $0.kind == .bill } }
    private var monthlyIncome: Double { income.reduce(0) { $0 + $1.monthlyEquivalent } }
    private var monthlyBills: Double { bills.reduce(0) { $0 + $1.monthlyEquivalent } }
    private var upcomingOneOffs: [OneOffItem] { oneOffs.filter { $0.date >= Calendar.current.startOfDay(for: .now) } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("", selection: $tab) {
                        Text("Recurring").tag(0)
                        Text("One-time").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16).padding(.vertical, 8)

                    if tab == 0 { recurringList } else { oneOffList }
                }
            }
            .navigationTitle("Money")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { tab == 0 ? (addingRecurring = true) : (addingOneOff = true); Haptics.tap() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(tab == 0 ? "Add recurring item" : "Add one-time item")
                }
            }
            .sheet(item: $editingRecurring) { RecurringEditor(item: $0) }
            .sheet(item: $editingOneOff) { OneOffEditor(item: $0) }
            .sheet(isPresented: $addingRecurring) { RecurringEditor(item: nil) }
            .sheet(isPresented: $addingOneOff) { OneOffEditor(item: nil) }
        }
    }

    private var recurringList: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    summaryTile("Monthly in", monthlyIncome, Theme.accent)
                    summaryTile("Monthly out", monthlyBills, Theme.ink)
                    summaryTile("Left over", monthlyIncome - monthlyBills,
                                monthlyIncome - monthlyBills >= 0 ? Theme.accent : Theme.danger)
                }
                if recurring.isEmpty {
                    EmptyState(icon: "repeat",
                               title: "No recurring money yet",
                               message: "Add your paycheck and regular bills so Runway can forecast ahead.",
                               actionTitle: "Add item") { addingRecurring = true }
                        .frame(minHeight: 280)
                } else {
                    group("Income", income, kind: .income)
                    group("Bills", bills, kind: .bill)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 24)
        }
    }

    private func summaryTile(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(Money.whole(value, code: currencyCode)).font(Theme.num(19)).foregroundStyle(color)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(0.4)
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
    }

    @ViewBuilder
    private func group(_ title: String, _ items: [RecurringItem], kind: FlowKind) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: title)
                ForEach(items) { item in
                    Button { editingRecurring = item } label: { recurringRow(item) }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) { context.delete(item) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func recurringRow(_ item: RecurringItem) -> some View {
        HStack(spacing: 12) {
            CategoryBadge(category: item.category, kind: item.kind)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                Text(item.cadence.label).font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.string(item.signedAmount, code: currencyCode, showSign: true))
                    .font(Theme.num(16)).foregroundStyle(item.kind == .income ? Theme.accent : Theme.ink)
                Text("≈\(Money.whole(item.monthlyEquivalent, code: currencyCode))/mo")
                    .font(.system(size: 11)).foregroundStyle(Theme.inkFaint)
            }
            if !item.isActive {
                Image(systemName: "pause.circle").foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .opacity(item.isActive ? 1 : 0.5)
    }

    private var oneOffList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if upcomingOneOffs.isEmpty {
                    EmptyState(icon: "calendar.badge.plus",
                               title: "No one-time items",
                               message: "Add a planned expense or a windfall — like a dentist bill or a tax refund — to see its impact.",
                               actionTitle: "Add item") { addingOneOff = true }
                        .frame(minHeight: 320)
                } else {
                    ForEach(upcomingOneOffs) { item in
                        Button { editingOneOff = item } label: { oneOffRow(item) }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) { context.delete(item) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 24)
        }
    }

    private func oneOffRow(_ item: OneOffItem) -> some View {
        HStack(spacing: 12) {
            CategoryBadge(category: item.category, kind: item.kind)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                Text(item.date, format: .dateTime.weekday().month().day())
                    .font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            Text(Money.string(item.signedAmount, code: currencyCode, showSign: true))
                .font(Theme.num(16)).foregroundStyle(item.kind == .income ? Theme.accent : Theme.ink)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
    }
}
