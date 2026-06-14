import SwiftUI

/// A single transaction row: payee, category/account, date, amount (colored by sign).
struct TransactionRow: View {
    let txn: Transaction
    let settings: AppSettings
    var showAccount: Bool = true

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private var subtitle: String {
        var parts: [String] = []
        if let cat = txn.categoryRef { parts.append("\(cat.emoji) \(cat.name)") }
        else if txn.isInflow { parts.append("Income") }
        if showAccount, let acct = txn.accountRef { parts.append(acct.name) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(txn.payee.isEmpty ? "(No payee)" : txn.payee)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(settings.moneyMasked(txn.amount))
                    .font(Theme.money(16, .bold))
                    .monospacedDigit()
                    .foregroundStyle(txn.isInflow ? Theme.good : Theme.ink)
                HStack(spacing: 4) {
                    if !txn.cleared {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.warn)
                            .accessibilityHidden(true)
                    }
                    Text(Self.dateFormatter.string(from: txn.date))
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(txn.payee), \(subtitle.isEmpty ? "uncategorized" : subtitle)")
        .accessibilityValue("\(txn.isInflow ? "inflow" : "outflow") \(settings.money(txn.amount)), \(Self.dateFormatter.string(from: txn.date))\(txn.cleared ? "" : ", uncleared")")
    }
}
