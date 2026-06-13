import SwiftUI

/// A category icon chip used in rows.
struct CategoryIcon: View {
    let category: Category
    var size: CGFloat = 38
    var body: some View {
        Image(systemName: category.icon)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(category.color)
            .frame(width: size, height: size)
            .background(category.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// A single bill row for the Upcoming and Bills lists. Shows name, amount,
/// category, due copy, an autopay badge, and an optional one-tap Mark paid.
struct BillRow: View {
    let bill: Bill
    let currencyCode: String
    var showMarkPaid: Bool = false
    var onMarkPaid: (() -> Void)? = nil

    private var status: BillStatus { BillEngine.status(bill) }
    private var days: Int { BillEngine.daysUntilDue(bill) }

    private var dueColor: Color {
        switch status {
        case .overdue:        return Theme.bad
        case .dueSoon:        return Theme.warn
        case .paidThisPeriod: return Theme.good
        case .upcoming:       return Theme.inkSoft
        }
    }

    private var dueText: String {
        if status == .paidThisPeriod { return "Paid this period" }
        return Fmt.relativeDue(days)
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: bill.category)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(bill.name)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    if bill.autopay {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.accent)
                            .accessibilityLabel("Autopay")
                    }
                }
                Text(dueText)
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(dueColor)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(Fmt.money(bill.amount, code: currencyCode))
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(bill.recurrence == .oneTime ? "once" : bill.recurrence.shortSuffix.replacingOccurrences(of: "/", with: ""))
                    .font(Theme.rounded(11, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }

            if showMarkPaid, status != .paidThisPeriod, let onMarkPaid {
                Button {
                    onMarkPaid()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark \(bill.name) paid")
            } else if showMarkPaid, status == .paidThisPeriod {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.good)
                    .accessibilityLabel("Already paid")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bill.name), \(Fmt.money(bill.amount, code: currencyCode)), \(dueText)")
    }
}
