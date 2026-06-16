import SwiftUI

struct UnitRow: View {
    let unit: Unit
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(unit.label)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(unit.bedBathSummary) · \(unit.sqft) sqft")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                if let lease = unit.activeLease {
                    Label(lease.tenantName, systemImage: "person.fill")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Text("No active tenant")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 6) {
                StatusChip(text: unit.status.rawValue, color: unit.status.color)
                let rent = unit.activeLease?.monthlyRent ?? unit.marketRent
                Text(Money.format(rent, currencyCode: settings.currencyCode) + "/mo")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .cardSurface()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(unit.label), \(unit.status.rawValue)")
        .accessibilityValue(unit.activeLease.map { "Tenant \($0.tenantName), rent \(Money.format($0.monthlyRent, currencyCode: settings.currencyCode))" } ?? "Vacant, market rent \(Money.format(unit.marketRent, currencyCode: settings.currencyCode))")
        .accessibilityHint("Opens unit editor")
    }
}
