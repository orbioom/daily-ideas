import SwiftUI

/// Amortization rows grouped by calendar year, with aggregate totals.
struct YearGroup: Identifiable {
    let id: Int          // calendar year
    let year: Int
    let rows: [AmortRow]
    let totalPrincipal: Double
    let totalInterest: Double
    let endBalance: Double

    static func build(from rows: [AmortRow], calendar: Calendar = .current) -> [YearGroup] {
        guard !rows.isEmpty else { return [] }
        var buckets: [Int: [AmortRow]] = [:]
        for row in rows {
            let y = calendar.component(.year, from: row.date)
            buckets[y, default: []].append(row)
        }
        return buckets.keys.sorted().compactMap { year in
            guard let items = buckets[year], !items.isEmpty else { return nil }
            let prin = items.reduce(0) { $0 + $1.principal + $1.extra }
            let int = items.reduce(0) { $0 + $1.interest }
            let end = items.last?.balance ?? 0
            return YearGroup(id: year, year: year, rows: items,
                             totalPrincipal: prin, totalInterest: int, endBalance: end)
        }
    }
}

struct YearDisclosure: View {
    let group: YearGroup
    let symbol: String
    @State private var expanded = false

    var body: some View {
        Card(padding: 0) {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    header
                }
                .buttonStyle(.plain)

                if expanded {
                    Divider().overlay(Theme.hairline)
                    VStack(spacing: 0) {
                        ForEach(group.rows) { row in
                            MonthRowView(row: row, symbol: symbol)
                            if row.id != group.rows.last?.id {
                                Divider().overlay(Theme.hairline).padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(String(group.year))
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Balance \(Fmt.moneyWhole(group.endBalance, symbol: symbol))")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("Principal \(Fmt.moneyWhole(group.totalPrincipal, symbol: symbol))")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.principalTint)
                Text("Interest \(Fmt.moneyWhole(group.totalInterest, symbol: symbol))")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.interestTint)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .rotationEffect(.degrees(expanded ? 90 : 0))
                .accessibilityHidden(true)
        }
        .padding(16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Year \(group.year)")
        .accessibilityValue("Principal \(Fmt.moneyWhole(group.totalPrincipal, symbol: symbol)), interest \(Fmt.moneyWhole(group.totalInterest, symbol: symbol)), ending balance \(Fmt.moneyWhole(group.endBalance, symbol: symbol)).")
        .accessibilityHint(expanded ? "Collapse to hide months" : "Expand to see each month")
        .accessibilityAddTraits(.isButton)
    }
}

struct MonthRowView: View {
    let row: AmortRow
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Text(Fmt.monthYear(row.date))
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 70, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text("P \(Fmt.moneyWhole(row.principal + row.extra, symbol: symbol))")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.principalTint)
                Text("I \(Fmt.moneyWhole(row.interest, symbol: symbol))")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.interestTint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Fmt.moneyWhole(row.balance, symbol: symbol))
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("balance")
                    .font(Theme.rounded(10))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Fmt.monthYearLong(row.date))
        .accessibilityValue("Principal \(Fmt.moneyWhole(row.principal + row.extra, symbol: symbol)), interest \(Fmt.moneyWhole(row.interest, symbol: symbol)), balance \(Fmt.moneyWhole(row.balance, symbol: symbol)).")
    }
}
