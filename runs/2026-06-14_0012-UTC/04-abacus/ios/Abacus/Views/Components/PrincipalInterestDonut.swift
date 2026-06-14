import SwiftUI
import Charts

/// A donut showing principal vs total interest split (Swift Charts SectorMark).
struct PrincipalInterestDonut: View {
    let principal: Double
    let interest: Double
    let symbol: String

    private struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
        let color: Color
    }

    private var slices: [Slice] {
        [
            Slice(name: "Principal", value: max(0, principal), color: Theme.principalTint),
            Slice(name: "Interest", value: max(0, interest), color: Theme.interestTint)
        ]
    }

    private var total: Double { max(0.0001, principal + interest) }
    private var interestShare: Double { max(0, interest) / total }

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Amount", slice.value),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(slice.color)
        }
        .chartLegend(.hidden)
        .frame(height: 170)
        .overlay {
            VStack(spacing: 2) {
                Text("\(Int((interestShare * 100).rounded()))%")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text("interest")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Principal versus interest")
        .accessibilityValue("Principal \(Fmt.moneyWhole(principal, symbol: symbol)), interest \(Fmt.moneyWhole(interest, symbol: symbol)), which is \(Int((interestShare * 100).rounded())) percent of the total.")
    }
}

/// A small color-key legend row for the donut.
struct DonutLegend: View {
    let principal: Double
    let interest: Double
    let symbol: String

    var body: some View {
        HStack(spacing: 16) {
            legendItem(color: Theme.principalTint, name: "Principal", value: principal)
            legendItem(color: Theme.interestTint, name: "Interest", value: interest)
        }
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, name: String, value: Double) -> some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 10, height: 10)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkFaint)
                Text(Fmt.moneyWhole(value, symbol: symbol))
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
