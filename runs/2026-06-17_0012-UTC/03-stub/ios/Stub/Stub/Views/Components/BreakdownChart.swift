import SwiftUI
import Charts

/// One slice of the take-home donut.
struct BreakdownSlice: Identifiable {
    let id = UUID()
    let label: String
    let amount: Decimal
    let color: Color
}

extension PaycheckResult {
    /// The four-way split for the donut: federal, state, FICA, take-home.
    var donutSlices: [BreakdownSlice] {
        let fica = socialSecurity + medicare
        return [
            BreakdownSlice(label: "Take-home", amount: netAnnual, color: StubTheme.takeHome),
            BreakdownSlice(label: "Federal", amount: federalTax + extraWithholdingAnnual, color: StubTheme.federal),
            BreakdownSlice(label: "State", amount: stateTax, color: StubTheme.state),
            BreakdownSlice(label: "FICA", amount: fica, color: StubTheme.fica)
        ]
    }
}

/// A SectorMark donut of where each gross dollar goes.
struct TakeHomeDonut: View {
    @Environment(\.colorScheme) private var scheme
    let result: PaycheckResult

    private var slices: [BreakdownSlice] { result.donutSlices.filter { $0.amount > 0 } }

    var body: some View {
        let total = slices.reduce(Decimal(0)) { $0 + $1.amount }
        return VStack(spacing: 16) {
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
                    Text("Take-home")
                        .font(.caption2)
                        .foregroundStyle(StubTheme.secondaryText(scheme))
                    Text(Format.percent(result.takeHomePercent, fractionDigits: 0))
                        .font(StubTheme.figureFont(.title2, weight: .bold))
                        .foregroundStyle(StubTheme.primaryText(scheme))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(donutAccessibilityLabel(total: total))

            // Legend
            VStack(spacing: 8) {
                ForEach(slices) { slice in
                    HStack(spacing: 10) {
                        Circle().fill(slice.color).frame(width: 11, height: 11)
                        Text(slice.label)
                            .font(.subheadline)
                            .foregroundStyle(StubTheme.primaryText(scheme))
                        Spacer()
                        Text(Format.currency(slice.amount, whole: true))
                            .font(StubTheme.figureFont(.subheadline, weight: .medium))
                            .foregroundStyle(StubTheme.secondaryText(scheme))
                        Text(percentString(slice.amount, of: total))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(StubTheme.secondaryText(scheme))
                            .frame(width: 46, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(slice.label): \(Format.currencySpoken(slice.amount, whole: true)), \(percentString(slice.amount, of: total))")
                }
            }
        }
    }

    private func percentString(_ amount: Decimal, of total: Decimal) -> String {
        guard total > 0 else { return "0%" }
        return Format.percent(amount / total, fractionDigits: 0)
    }

    private func donutAccessibilityLabel(total: Decimal) -> String {
        let parts = slices.map { "\($0.label) \(percentString($0.amount, of: total))" }
        return "Where each gross dollar goes: " + parts.joined(separator: ", ") + "."
    }
}
