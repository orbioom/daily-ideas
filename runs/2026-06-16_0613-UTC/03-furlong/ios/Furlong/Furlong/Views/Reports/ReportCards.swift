import SwiftUI

struct DeductionSummaryCard: View {
    @EnvironmentObject private var settings: AppSettings
    let result: DeductionResult

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total deduction")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Text(settings.money(result.totalDeduction))
                        .font(Theme.mono(34, .bold))
                        .foregroundStyle(Theme.accent)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                Divider().background(Theme.hairline)
                row("Mileage deduction", settings.money(result.totalMileageDeduction), "road.lanes")
                ForEach(TripPurpose.allCases.filter { $0.isDeductible }) { purpose in
                    let miles = result.milesByPurpose[purpose] ?? 0
                    let amount = result.mileageDeductionByPurpose[purpose] ?? 0
                    if miles > 0 {
                        subRow("\(purpose.rawValue) · \(settings.distance(miles))",
                               settings.money(amount), purpose.tint)
                    }
                }
                Divider().background(Theme.hairline)
                row("Deductible expenses", settings.money(result.totalDeductibleExpenses), "creditcard.fill")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total deduction \(settings.money(result.totalDeduction)), mileage \(settings.money(result.totalMileageDeduction)), expenses \(settings.money(result.totalDeductibleExpenses))")
    }

    private func row(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(value)
                .font(Theme.mono(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
    }

    private func subRow(_ title: String, _ value: String, _ tint: Color) -> some View {
        HStack {
            Circle().fill(tint).frame(width: 7, height: 7)
            Text(title)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.mono(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.leading, 4)
    }
}

struct MethodComparisonCard: View {
    @EnvironmentObject private var settings: AppSettings
    let comparison: MethodComparison

    private var standardWins: Bool {
        comparison.standardMileageAmount >= comparison.actualExpenseAmount
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Standard vs. actual")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    TagPill(text: comparison.recommended,
                            symbol: "checkmark.seal.fill",
                            tint: Theme.accent)
                }
                methodBar("Standard mileage",
                          amount: comparison.standardMileageAmount,
                          highlighted: standardWins)
                methodBar("Actual expense",
                          amount: comparison.actualExpenseAmount,
                          highlighted: !standardWins)
                Text("Actual method estimates operating costs × \(NumberFormatting.percent(comparison.businessUsePercent)) business use. Furlong recommends the larger lawful deduction; confirm eligibility with a tax pro.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Method comparison. Standard mileage \(settings.money(comparison.standardMileageAmount)), actual expense \(settings.money(comparison.actualExpenseAmount)). Recommended \(comparison.recommended).")
    }

    private var maxAmount: Decimal {
        max(comparison.standardMileageAmount, comparison.actualExpenseAmount, 1)
    }

    private func methodBar(_ title: String, amount: Decimal, highlighted: Bool) -> some View {
        let fraction = NSDecimalNumber(decimal: amount).doubleValue
            / max(1, NSDecimalNumber(decimal: maxAmount).doubleValue)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(settings.money(amount))
                    .font(Theme.mono(14, .semibold))
                    .foregroundStyle(highlighted ? Theme.accent : Theme.inkSoft)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule()
                        .fill(highlighted ? Theme.accent : Theme.inkSoft.opacity(0.5))
                        .frame(width: max(6, geo.size.width * CGFloat(min(1, max(0, fraction)))))
                }
            }
            .frame(height: 10)
        }
        .accessibilityHidden(true)
    }
}
