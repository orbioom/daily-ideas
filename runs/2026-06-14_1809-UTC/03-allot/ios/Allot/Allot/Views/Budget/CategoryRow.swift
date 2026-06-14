import SwiftUI

/// A single category row inside the budget: name, Assigned & Activity, and an
/// Available pill. Tapping opens the assign sheet.
struct CategoryRow: View {
    let category: Category
    let monthKey: String
    let transactions: [Transaction]
    let settings: AppSettings
    let onTap: () -> Void

    private var assigned: Double { BudgetEngine.allocated(category, monthKey: monthKey) }
    private var activity: Double { BudgetEngine.spent(category, monthKey: monthKey, txns: transactions) }
    private var available: Double { BudgetEngine.available(category, upToMonth: monthKey, txns: transactions) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(category.emoji)
                    .font(.system(size: 22))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text("Assigned \(settings.money(assigned))")
                        Text("·").foregroundStyle(Theme.inkFaint)
                        Text("Spent \(settings.money(activity))")
                    }
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                Spacer()
                AvailablePill(amount: available, text: settings.moneyMasked(available))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.name)")
        .accessibilityValue("Assigned \(settings.money(assigned)), spent \(settings.money(activity)), available \(settings.money(available))")
        .accessibilityHint("Double tap to assign money")
    }
}
