import SwiftUI

/// Side-by-side comparison of exactly two saved scenarios.
struct CompareView: View {
    let scenarios: [LoanScenario]
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    private var symbol: String { settings.currency.symbol }

    var body: some View {
        NavigationStack {
            Group {
                if scenarios.count == 2 {
                    content(a: scenarios[0], b: scenarios[1])
                } else {
                    EmptyStateView(symbol: "rectangle.on.rectangle",
                                   title: "Pick two scenarios",
                                   message: "Comparison needs exactly two saved scenarios.")
                }
            }
            .background(Theme.bg)
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func content(a: LoanScenario, b: LoanScenario) -> some View {
        let sa = a.summary
        let sb = b.summary
        return ScrollView {
            VStack(spacing: 16) {
                headerRow(a: a, b: b)
                Card {
                    VStack(spacing: 0) {
                        compareRow("Monthly payment",
                                   Fmt.money(sa.monthlyPayment, symbol: symbol),
                                   Fmt.money(sb.monthlyPayment, symbol: symbol),
                                   lowerIsBetter: true,
                                   aVal: sa.monthlyPayment, bVal: sb.monthlyPayment)
                        divider
                        compareRow("Total interest",
                                   Fmt.moneyWhole(sa.totalInterest, symbol: symbol),
                                   Fmt.moneyWhole(sb.totalInterest, symbol: symbol),
                                   lowerIsBetter: true,
                                   aVal: sa.totalInterest, bVal: sb.totalInterest)
                        divider
                        compareRow("Total paid",
                                   Fmt.moneyWhole(sa.totalPaid, symbol: symbol),
                                   Fmt.moneyWhole(sb.totalPaid, symbol: symbol),
                                   lowerIsBetter: true,
                                   aVal: sa.totalPaid, bVal: sb.totalPaid)
                        divider
                        compareRow("Payoff date",
                                   Fmt.monthYear(sa.payoffDate),
                                   Fmt.monthYear(sb.payoffDate),
                                   lowerIsBetter: true,
                                   aVal: sa.payoffDate.timeIntervalSince1970,
                                   bVal: sb.payoffDate.timeIntervalSince1970)
                        divider
                        compareRow("Payments",
                                   "\(sa.payoffMonths)",
                                   "\(sb.payoffMonths)",
                                   lowerIsBetter: true,
                                   aVal: Double(sa.payoffMonths), bVal: Double(sb.payoffMonths))
                    }
                }
                verdict(a: a, b: b, sa: sa, sb: sb)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var divider: some View {
        Divider().overlay(Theme.hairline).padding(.vertical, 8)
    }

    private func headerRow(a: LoanScenario, b: LoanScenario) -> some View {
        HStack(spacing: 12) {
            scenarioChip(a, tint: Theme.accent)
            Text("vs")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkFaint)
            scenarioChip(b, tint: Theme.interestTint)
        }
    }

    private func scenarioChip(_ s: LoanScenario, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: s.loanType.symbol)
                .font(.system(size: 18))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(s.name)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private func compareRow(_ label: String, _ aText: String, _ bText: String,
                            lowerIsBetter: Bool, aVal: Double, bVal: Double) -> some View {
        let aBetter = lowerIsBetter ? aVal < bVal : aVal > bVal
        let tie = aVal == bVal
        return VStack(spacing: 6) {
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkFaint)
                .frame(maxWidth: .infinity)
            HStack(spacing: 12) {
                valueCell(aText, highlighted: !tie && aBetter)
                valueCell(bText, highlighted: !tie && !aBetter)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue("First \(aText), second \(bText)\(tie ? ", tied" : (aBetter ? ", first is better" : ", second is better")).")
    }

    private func valueCell(_ text: String, highlighted: Bool) -> some View {
        Text(text)
            .font(Theme.rounded(16, .semibold))
            .foregroundStyle(highlighted ? Theme.good : Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(highlighted ? Theme.accentSoft : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func verdict(a: LoanScenario, b: LoanScenario,
                         sa: LoanSummary, sb: LoanSummary) -> some View {
        let diff = abs(sa.totalInterest - sb.totalInterest)
        let cheaper = sa.totalInterest <= sb.totalInterest ? a : b
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text("Bottom line")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                }
                if diff < 0.5 {
                    Text("Both cost about the same in interest.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Text("\(cheaper.name) costs \(Fmt.moneyWhole(diff, symbol: symbol)) less in total interest.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
