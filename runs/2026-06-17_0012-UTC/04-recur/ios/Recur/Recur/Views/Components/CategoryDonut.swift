import SwiftUI
import Charts

/// A donut (SectorMark) of monthly spend by category, with a legend.
/// iOS 17 Charts. Total is shown in the center hole.
struct CategoryDonut: View {
    @Environment(\.colorScheme) private var scheme
    let slices: [BreakdownSlice]
    let currencyCode: String
    let hideAmounts: Bool
    let total: Decimal

    private func doubleValue(_ d: Decimal) -> Double {
        NSDecimalNumber(decimal: d).doubleValue
    }

    private func percent(_ slice: BreakdownSlice) -> Int {
        let totalD = doubleValue(total)
        guard totalD > 0 else { return 0 }
        return Int((doubleValue(slice.monthlyTotal) / totalD * 100).rounded())
    }

    var body: some View {
        VStack(spacing: 16) {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Spend", doubleValue(slice.monthlyTotal)),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(Color(hex: slice.colorHex))
            }
            .frame(height: 180)
            .chartLegend(.hidden)
            .overlay {
                VStack(spacing: 2) {
                    Text("per month")
                        .font(.caption2)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                    Text(hideAmounts ? MoneyFormatter.masked(code: currencyCode)
                                     : MoneyFormatter.compact(total, code: currencyCode))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RecurTheme.primaryText(scheme))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .accessibilityLabel("Spending by category donut chart")
            .accessibilityValue(legendAccessibility)

            // Legend
            VStack(spacing: 8) {
                ForEach(slices) { slice in
                    HStack(spacing: 8) {
                        CategoryDot(colorHex: slice.colorHex, size: 10)
                        Text(slice.label)
                            .font(.subheadline)
                            .foregroundStyle(RecurTheme.primaryText(scheme))
                        Spacer()
                        Text("\(percent(slice))%")
                            .font(.subheadline)
                            .foregroundStyle(RecurTheme.secondaryText(scheme))
                        Text(hideAmounts ? MoneyFormatter.masked(code: currencyCode)
                                         : MoneyFormatter.string(slice.monthlyTotal, code: currencyCode))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RecurTheme.primaryText(scheme))
                            .frame(minWidth: 64, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(slice.label), \(percent(slice)) percent, \(hideAmounts ? "amount hidden" : MoneyFormatter.string(slice.monthlyTotal, code: currencyCode)) per month")
                }
            }
        }
    }

    private var legendAccessibility: String {
        slices.map { "\($0.label) \(percent($0)) percent" }.joined(separator: ", ")
    }
}
