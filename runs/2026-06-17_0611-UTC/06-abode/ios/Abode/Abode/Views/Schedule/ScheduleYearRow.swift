import SwiftUI

/// A year's worth of amortization rows, summarized and expandable.
struct ScheduleYearGroup: Identifiable {
    let id: Int
    let year: Int
    let rows: [AmortizationRow]

    var principalPaid: Decimal { rows.reduce(0) { $0 + $1.principal } }
    var interestPaid: Decimal { rows.reduce(0) { $0 + $1.interest } }
    var endingBalance: Decimal { rows.last?.balance ?? 0 }
}

/// A collapsible year summary; expanding reveals the month-by-month detail.
struct ScheduleYearRow: View {
    @Environment(\.colorScheme) private var scheme
    let group: ScheduleYearGroup
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                expanded.toggle()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Year \(group.year)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AbodeTheme.primaryText(scheme))
                        Text("Balance \(Format.money(group.endingBalance, forceWhole: true))")
                            .font(.caption)
                            .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Format.money(group.principalPaid, forceWhole: true))
                            .font(AbodeTheme.figure(.caption, weight: .medium))
                            .foregroundStyle(AbodeTheme.principalInterest)
                        Text(Format.money(group.interestPaid, forceWhole: true))
                            .font(AbodeTheme.figure(.caption, weight: .medium))
                            .foregroundStyle(AbodeTheme.pmi)
                    }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AbodeTheme.secondaryText(scheme))
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AbodeTheme.subtleSurface(scheme))
                )
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Year \(group.year)")
            .accessibilityValue("Principal \(Format.money(group.principalPaid, forceWhole: true)), interest \(Format.money(group.interestPaid, forceWhole: true)), ending balance \(Format.money(group.endingBalance, forceWhole: true))")
            .accessibilityHint(expanded ? "Collapse months" : "Expand months")

            if expanded {
                VStack(spacing: 4) {
                    HStack {
                        Text("Month").frame(width: 56, alignment: .leading)
                        Text("Principal").frame(maxWidth: .infinity, alignment: .trailing)
                        Text("Interest").frame(maxWidth: .infinity, alignment: .trailing)
                        Text("Balance").frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    .padding(.top, 8)

                    ForEach(group.rows) { row in
                        HStack {
                            Text("#\(row.id)").frame(width: 56, alignment: .leading)
                            Text(Format.money(row.principal, forceWhole: true)).frame(maxWidth: .infinity, alignment: .trailing)
                            Text(Format.money(row.interest, forceWhole: true)).frame(maxWidth: .infinity, alignment: .trailing)
                            Text(Format.money(row.balance, forceWhole: true)).frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .font(AbodeTheme.figure(.caption2, weight: .regular))
                        .foregroundStyle(AbodeTheme.primaryText(scheme))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Payment \(row.id)")
                        .accessibilityValue("Principal \(Format.money(row.principal, forceWhole: true)), interest \(Format.money(row.interest, forceWhole: true)), balance \(Format.money(row.balance, forceWhole: true))")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }
}
