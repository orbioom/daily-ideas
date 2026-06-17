import SwiftUI

/// The hero "net per paycheck" card — the emotional centerpiece.
/// Shows the big net figure with gross + total tax as supporting context.
struct NetHeroCard: View {
    @Environment(\.colorScheme) private var scheme
    let result: PaycheckResult
    let roundWhole: Bool
    /// When true, show annual net; otherwise per-paycheck.
    var showAnnual: Bool = false

    private var primaryValue: Decimal {
        showAnnual ? result.netAnnual : result.netPerPaycheck
    }

    private var caption: String {
        showAnnual ? "Net pay per year" : "Net pay per \(periodWord)"
    }

    private var periodWord: String {
        switch result.frequency {
        case .weekly: return "week"
        case .biweekly: return "2 weeks"
        case .semimonthly: return "half-month"
        case .monthly: return "month"
        }
    }

    var body: some View {
        StubCard(padding: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Take-home", systemImage: "banknote.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(StubTheme.green)
                    Spacer()
                    Text(Format.percent(result.takeHomePercent, fractionDigits: 0) + " of gross")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(StubTheme.secondaryText(scheme))
                }

                Text(Format.currency(primaryValue, whole: roundWhole))
                    .font(StubTheme.figureFont(.largeTitle, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(StubTheme.primaryText(scheme))

                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(StubTheme.secondaryText(scheme))

                Divider().background(StubTheme.hairline(scheme))

                HStack(spacing: 0) {
                    miniStat(title: "Gross",
                             value: Format.currency(showAnnual ? result.annualGross : result.grossPerPaycheck, whole: roundWhole))
                    Divider().frame(height: 34).background(StubTheme.hairline(scheme))
                    miniStat(title: "Total tax",
                             value: Format.currency(showAnnual ? result.totalTax : result.totalTaxPerPaycheck, whole: roundWhole))
                    Divider().frame(height: 34).background(StubTheme.hairline(scheme))
                    miniStat(title: "Eff. rate",
                             value: Format.percent(result.effectiveTaxRate))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption): \(Format.currencySpoken(primaryValue, whole: roundWhole)). " +
                            "Take home \(Format.percent(result.takeHomePercent, fractionDigits: 0)) of gross. " +
                            "Effective tax rate \(Format.percent(result.effectiveTaxRate)).")
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(StubTheme.secondaryText(scheme))
            Text(value)
                .font(StubTheme.figureFont(.subheadline, weight: .semibold))
                .foregroundStyle(StubTheme.primaryText(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}
