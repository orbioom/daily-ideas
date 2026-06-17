import SwiftUI
import Charts

/// Side-by-side comparison of saved scenarios: payment, total interest, payoff, plus
/// a grouped bar chart. Built on demand (no stored schedule rows).
struct CompareView: View {
    @Environment(\.colorScheme) private var scheme
    let scenarios: [MortgageScenario]

    private struct Computed: Identifiable {
        let id: UUID
        let name: String
        let monthly: Decimal
        let principalInterest: Decimal
        let totalInterest: Decimal
        let payoffMonths: Int
        let color: Color
    }

    private var computed: [Computed] {
        let palette: [Color] = [AbodeTheme.accent, AbodeTheme.propertyTax, AbodeTheme.insurance,
                                AbodeTheme.hoa, AbodeTheme.pmi]
        return scenarios.enumerated().map { index, s in
            let input = s.asLoanInput
            let breakdown = MortgageEngine.breakdown(input)
            let schedule = MortgageEngine.amortize(input)
            return Computed(
                id: s.id,
                name: s.name,
                monthly: breakdown.total,
                principalInterest: breakdown.principalAndInterest,
                totalInterest: schedule.totalInterest,
                payoffMonths: schedule.monthsToPayoff,
                color: palette[safe: index % palette.count] ?? AbodeTheme.accent
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if computed.count < 2 {
                    AbodeCard {
                        EmptyStateView(icon: "rectangle.split.3x1",
                                       title: "Select at least two",
                                       message: "Pick two or more scenarios to compare them here.")
                    }
                } else {
                    chartCard
                    tableCard
                }
            }
            .padding(16)
        }
        .abodeScreenBackground(scheme)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chartCard: some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "Monthly payment", systemImage: "chart.bar")
                Chart(computed) { c in
                    BarMark(
                        x: .value("Payment", c.monthly.doubleValue),
                        y: .value("Scenario", c.name)
                    )
                    .foregroundStyle(c.color)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text(Format.money(c.monthly, forceWhole: true))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    }
                }
                .chartXAxis { AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0))) }
                .frame(height: max(120, CGFloat(computed.count) * 56))
                .accessibilityLabel("Monthly payment comparison across \(computed.count) scenarios")
            }
        }
    }

    private var tableCard: some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 14) {
                AbodeSectionHeader(title: "Details", systemImage: "tablecells")
                ForEach(computed) { c in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle().fill(c.color).frame(width: 10, height: 10).accessibilityHidden(true)
                            Text(c.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AbodeTheme.primaryText(scheme))
                        }
                        StatRow(label: "Monthly payment", value: Format.money(c.monthly, forceCents: true))
                        StatRow(label: "Principal & interest", value: Format.money(c.principalInterest, forceCents: true))
                        StatRow(label: "Total interest", value: Format.money(c.totalInterest, forceWhole: true), accent: AbodeTheme.pmi)
                        StatRow(label: "Payoff", value: Format.termFromMonths(c.payoffMonths))
                        if c.id != computed.last?.id {
                            Divider().overlay(AbodeTheme.hairline(scheme))
                        }
                    }
                    .accessibilityElement(children: .contain)
                }
            }
        }
    }
}
