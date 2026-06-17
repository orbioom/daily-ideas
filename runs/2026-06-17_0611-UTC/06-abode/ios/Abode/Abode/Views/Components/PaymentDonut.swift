import SwiftUI
import Charts

/// One slice of the monthly payment donut.
struct PaymentSlice: Identifiable {
    let id: String
    let label: String
    let amount: Decimal
    let color: Color
}

extension PaymentBreakdown {
    /// The slices for the donut, in a stable order, with consistent hues.
    var slices: [PaymentSlice] {
        [
            PaymentSlice(id: "pi", label: "Principal & interest", amount: principalAndInterest, color: AbodeTheme.principalInterest),
            PaymentSlice(id: "tax", label: "Property tax", amount: propertyTax, color: AbodeTheme.propertyTax),
            PaymentSlice(id: "ins", label: "Insurance", amount: insurance, color: AbodeTheme.insurance),
            PaymentSlice(id: "pmi", label: "PMI", amount: pmi, color: AbodeTheme.pmi),
            PaymentSlice(id: "hoa", label: "HOA", amount: hoa, color: AbodeTheme.hoa)
        ]
    }
}

/// A SectorMark donut of the monthly payment composition, with a legend.
struct PaymentDonut: View {
    @Environment(\.colorScheme) private var scheme
    let breakdown: PaymentBreakdown

    private var slices: [PaymentSlice] { breakdown.slices.filter { $0.amount > 0 } }

    var body: some View {
        let total = breakdown.total
        return VStack(spacing: 16) {
            if slices.isEmpty {
                Text("Enter loan details to see your payment breakdown.")
                    .font(.subheadline)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .frame(height: 180)
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Amount", slice.amount.doubleValue),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(slice.color)
                }
                .chartLegend(.hidden)
                .frame(height: 196)
                .overlay {
                    VStack(spacing: 2) {
                        Text("Monthly")
                            .font(.caption2)
                            .foregroundStyle(AbodeTheme.secondaryText(scheme))
                        Text(Format.money(total, forceWhole: true))
                            .font(AbodeTheme.figure(.title3, weight: .bold))
                            .foregroundStyle(AbodeTheme.primaryText(scheme))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(donutLabel(total: total))

                VStack(spacing: 8) {
                    ForEach(slices) { slice in
                        HStack(spacing: 10) {
                            Circle().fill(slice.color).frame(width: 11, height: 11)
                                .accessibilityHidden(true)
                            Text(slice.label)
                                .font(.subheadline)
                                .foregroundStyle(AbodeTheme.primaryText(scheme))
                            Spacer()
                            Text(Format.money(slice.amount, forceCents: true))
                                .font(AbodeTheme.figure(.subheadline, weight: .medium))
                                .foregroundStyle(AbodeTheme.secondaryText(scheme))
                            Text(percentString(slice.amount, of: total))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AbodeTheme.secondaryText(scheme))
                                .frame(width: 46, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(slice.label): \(Format.money(slice.amount, forceCents: true)), \(percentString(slice.amount, of: total))")
                    }
                }
            }
        }
    }

    private func percentString(_ amount: Decimal, of total: Decimal) -> String {
        guard total > 0 else { return "0%" }
        return Format.percentFraction(MortgageEngine.divide(amount, by: total), fractionDigits: 0)
    }

    private func donutLabel(total: Decimal) -> String {
        let parts = slices.map { "\($0.label) \(percentString($0.amount, of: total))" }
        return "Monthly payment of \(Format.money(total, forceCents: true)): " + parts.joined(separator: ", ") + "."
    }
}
