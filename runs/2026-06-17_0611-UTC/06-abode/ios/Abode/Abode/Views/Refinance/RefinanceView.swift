import SwiftUI
import Charts

/// Refinance compare: current loan vs new loan → monthly savings, break-even months,
/// and lifetime interest delta. Pro-gated.
struct RefinanceView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro

    @State private var balanceText = "280000"
    @State private var currentRateText = "7.2"
    @State private var remainingYearsText = "27"
    @State private var newRateText = "6.0"
    @State private var newTermYears = 30
    @State private var closingCostsText = "4500"
    @State private var showPaywall = false

    private var result: RefinanceResult {
        MortgageEngine.refinance(
            currentBalance: Parse.decimalOrZero(balanceText),
            currentRatePct: Parse.decimalOrZero(currentRateText),
            currentRemainingMonths: (Parse.intPositive(remainingYearsText) ?? 1) * 12,
            newRatePct: Parse.decimalOrZero(newRateText),
            newTermYears: newTermYears,
            closingCosts: Parse.decimalOrZero(closingCostsText)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AbodeTheme.appBackground(scheme).ignoresSafeArea()
                if pro.isPro {
                    content
                } else {
                    ScrollView {
                        AbodeCard {
                            ProLockView(
                                feature: "Refinance compare",
                                detail: "Compare your current loan with a new one to see monthly savings, break-even time, and the lifetime interest difference.",
                                showPaywall: $showPaywall
                            )
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Refinance")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                verdictCard
                comparisonChartCard
                detailCard
                inputsCard
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var verdictCard: some View {
        let r = result
        let saves = r.monthlySavings > 0
        return AbodeCard(padding: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(saves ? "Monthly savings" : "Monthly difference")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                Text(Format.money(abs(r.monthlySavings), forceCents: true))
                    .font(AbodeTheme.figure(.largeTitle, weight: .bold))
                    .foregroundStyle(saves ? AbodeTheme.positive : AbodeTheme.danger)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if let be = r.breakEvenMonths {
                    Text("Break-even in \(Format.termFromMonths(be)) — after closing costs of \(Format.money(r.closingCosts, forceWhole: true)).")
                        .font(.footnote)
                        .foregroundStyle(AbodeTheme.secondaryText(scheme))
                } else {
                    Text("The new loan costs more per month, so there is no break-even point.")
                        .font(.footnote)
                        .foregroundStyle(AbodeTheme.secondaryText(scheme))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    private struct PayBar: Identifiable {
        let id: String
        let label: String
        let amount: Decimal
        let color: Color
    }

    private var comparisonChartCard: some View {
        let r = result
        let bars = [
            PayBar(id: "cur", label: "Current", amount: r.currentPayment, color: AbodeTheme.secondaryText(scheme)),
            PayBar(id: "new", label: "New", amount: r.newPayment, color: AbodeTheme.accent)
        ]
        return AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "Monthly payment (P&I)", systemImage: "chart.bar")
                Chart(bars) { bar in
                    BarMark(
                        x: .value("Loan", bar.label),
                        y: .value("Payment", bar.amount.doubleValue)
                    )
                    .foregroundStyle(bar.color)
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text(Format.money(bar.amount, forceWhole: true))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    }
                }
                .chartYAxis { AxisMarks(format: .currency(code: settings.currencyCode).precision(.fractionLength(0))) }
                .frame(height: 200)
                .accessibilityLabel("Current payment \(Format.money(r.currentPayment, forceCents: true)) versus new payment \(Format.money(r.newPayment, forceCents: true))")
            }
        }
    }

    private var detailCard: some View {
        let r = result
        let cheaper = r.lifetimeInterestDelta < 0
        return AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "Details", systemImage: "doc.text.magnifyingglass")
                StatRow(label: "Current payment", value: Format.money(r.currentPayment, forceCents: true))
                StatRow(label: "New payment", value: Format.money(r.newPayment, forceCents: true))
                StatRow(label: "Closing costs", value: Format.money(r.closingCosts, forceWhole: true))
                StatRow(label: "Current lifetime interest", value: Format.money(r.currentLifetimeInterest, forceWhole: true))
                StatRow(label: "New lifetime interest", value: Format.money(r.newLifetimeInterest, forceWhole: true))
                StatRow(label: "Lifetime cost change",
                        value: "\(cheaper ? "−" : "+")\(Format.money(abs(r.lifetimeInterestDelta), forceWhole: true))",
                        emphasis: true,
                        accent: cheaper ? AbodeTheme.positive : AbodeTheme.danger)
                Text("Lifetime change includes closing costs and reflects the new term. A longer term can lower the payment yet raise total interest.")
                    .font(.caption2)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
            }
        }
    }

    private var inputsCard: some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 14) {
                AbodeSectionHeader(title: "Current loan", systemImage: "house")
                AbodeNumberField(title: "Remaining balance", symbol: Format.currencySymbol, prompt: "280,000", text: $balanceText)
                AbodeNumberField(title: "Current rate", symbol: "%", prompt: "7.2", text: $currentRateText)
                AbodeNumberField(title: "Years remaining", symbol: "yr", prompt: "27", text: $remainingYearsText)

                Divider().overlay(AbodeTheme.hairline(scheme))
                AbodeSectionHeader(title: "New loan", systemImage: "arrow.left.arrow.right")
                AbodeNumberField(title: "New rate", symbol: "%", prompt: "6.0", text: $newRateText)
                AbodeSegmentPicker(title: "New term", options: CalculatorModel.termOptions, selection: $newTermYears)
                AbodeNumberField(title: "Closing costs", symbol: Format.currencySymbol, prompt: "4,500", text: $closingCostsText)
            }
        }
    }
}
