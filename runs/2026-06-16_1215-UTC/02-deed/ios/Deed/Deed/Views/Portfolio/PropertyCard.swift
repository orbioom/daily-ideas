import SwiftUI

struct PropertyCard: View {
    let property: Property
    @EnvironmentObject private var settings: AppSettings

    private var metrics: PropertyMetrics {
        FinanceEngine.metrics(for: property, settings: settings.closingCostPct)
    }

    var body: some View {
        let cashFlow = metrics.monthlyCashFlow
        let cashFlowColor = cashFlow >= 0 ? Theme.good : Theme.bad

        return HStack(spacing: 14) {
            identityBadge
            VStack(alignment: .leading, spacing: 6) {
                Text(property.name)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(property.address)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    StatusChip(
                        text: Money.formatSigned(cashFlow, currencyCode: settings.currencyCode) + "/mo",
                        color: cashFlowColor,
                        systemImage: cashFlow >= 0 ? "arrow.up.right" : "arrow.down.right"
                    )
                    StatusChip(
                        text: "\(metrics.occupiedUnits)/\(metrics.totalUnits) occ",
                        color: Theme.accent,
                        systemImage: "person.fill"
                    )
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(property.name), \(property.type.rawValue)")
        .accessibilityValue("Cash flow \(Money.formatSigned(cashFlow, currencyCode: settings.currencyCode)) per month, \(metrics.occupiedUnits) of \(metrics.totalUnits) units occupied")
        .accessibilityHint("Opens property details")
    }

    private var identityBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                .fill(property.identityGradient)
                .frame(width: 52, height: 52)
            Image(systemName: property.type.systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}
