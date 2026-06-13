import SwiftUI
import SwiftData

/// Home: bills grouped by urgency (Overdue / Due soon / Upcoming) with a
/// one-tap Mark paid, plus a header tile for this month's totals.
struct UpcomingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Bill.dueDate) private var bills: [Bill]
    @Query private var payments: [Payment]

    @AppStorage("currencyCode") private var currencyCode = "USD"

    private var stats: BillStats { BillStats.from(bills, payments: payments) }

    private func group(_ s: BillStatus) -> [Bill] {
        bills.filter { BillEngine.status($0) == s }
            .sorted { BillEngine.daysUntilDue($0) < BillEngine.daysUntilDue($1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if bills.isEmpty {
                    EmptyStateView(icon: "tray.full.fill",
                                   title: "No bills yet",
                                   message: "Add your recurring bills in the Bills tab and they'll show up here, grouped by what needs paying first.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            headerTile
                            section("Overdue", group(.overdue), tint: Theme.bad)
                            section("Due soon", group(.dueSoon), tint: Theme.warn)
                            section("Upcoming", group(.upcoming), tint: Theme.inkSoft)
                            paidSection
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Upcoming")
        }
    }

    private var headerTile: some View {
        Card {
            VStack(spacing: 14) {
                HStack {
                    totalColumn("Due this month", stats.dueThisMonth, Theme.ink)
                    Divider().frame(height: 40).background(Theme.hairline)
                    totalColumn("Remaining", stats.remainingThisMonth, Theme.accent)
                }
                if stats.countOverdue > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.bad)
                            .accessibilityHidden(true)
                        Text("\(stats.countOverdue) overdue — pay these first")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.bad)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.bad.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func totalColumn(_ label: String, _ amount: Decimal, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(Fmt.money(amount, code: currencyCode))
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Fmt.money(amount, code: currencyCode))")
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [Bill], tint: Color) -> some View {
        if !items.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(title).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                        Spacer()
                        Pill(text: "\(items.count)", color: tint)
                    }
                    ForEach(Array(items.enumerated()), id: \.element.persistentModelID) { idx, bill in
                        BillRow(bill: bill, currencyCode: currencyCode, showMarkPaid: true) {
                            markPaid(bill)
                        }
                        if idx < items.count - 1 { Divider().background(Theme.hairline) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var paidSection: some View {
        let paid = group(.paidThisPeriod)
        if !paid.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Paid this period").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                        Spacer()
                        Pill(text: "\(paid.count)", color: Theme.good)
                    }
                    ForEach(Array(paid.enumerated()), id: \.element.persistentModelID) { idx, bill in
                        BillRow(bill: bill, currencyCode: currencyCode, showMarkPaid: true)
                        if idx < paid.count - 1 { Divider().background(Theme.hairline) }
                    }
                }
            }
        }
    }

    private func markPaid(_ bill: Bill) {
        BillEngine.markPaid(bill, context: context)
        Haptics.success()
    }
}
