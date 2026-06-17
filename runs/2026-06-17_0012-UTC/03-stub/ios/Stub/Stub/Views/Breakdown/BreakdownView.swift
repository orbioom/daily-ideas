import SwiftUI

/// Full waterfall + donut for the current calculator inputs, with a
/// per-paycheck vs annual toggle and marginal/effective rates.
struct BreakdownView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @Bindable var calc: CalculatorModel

    @State private var showAnnual = false
    @State private var didInit = false

    private var result: PaycheckResult { calc.result }

    /// Divides annual figures down to per-paycheck when in per-check mode.
    private func scaled(_ annual: Decimal) -> Decimal {
        showAnnual ? annual : PaycheckResult.divide(annual, by: Decimal(result.frequency.periodsPerYear))
    }

    private var refTotal: Decimal { scaled(result.annualGross) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if result.annualGross <= 0 {
                    emptyState
                } else {
                    VStack(spacing: 18) {
                        modeToggle
                        donutCard
                        ratesCard
                        waterfallCard
                        ficaDetailCard
                        disclaimerNote
                    }
                    .padding(16)
                }
            }
            .background(StubTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Breakdown")
        }
        .onAppear {
            guard !didInit else { return }
            didInit = true
            showAnnual = prefs.showAnnualByDefault
        }
    }

    // MARK: - Pieces

    private var modeToggle: some View {
        Picker("View", selection: $showAnnual) {
            Text("Per paycheck").tag(false)
            Text("Per year").tag(true)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Show figures per paycheck or per year")
    }

    private var donutCard: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Where each dollar goes")
                    .font(.headline)
                    .foregroundStyle(StubTheme.primaryText(scheme))
                TakeHomeDonut(result: result)
            }
        }
    }

    private var ratesCard: some View {
        HStack(spacing: 12) {
            StatTile(title: "Net / \(showAnnual ? "year" : "paycheck")",
                     value: Format.currency(showAnnual ? result.netAnnual : result.netPerPaycheck, whole: prefs.roundWhole),
                     accent: StubTheme.green)
            StatTile(title: "Effective rate",
                     value: Format.percent(result.effectiveTaxRate))
            StatTile(title: "Marginal fed.",
                     value: Format.percent(result.marginalFederalRate, fractionDigits: 0))
        }
    }

    private var waterfallCard: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Gross → Net waterfall")
                    .font(.headline)
                    .foregroundStyle(StubTheme.primaryText(scheme))

                WaterfallRow(label: "Gross pay", amount: scaled(result.annualGross),
                             total: refTotal, color: StubTheme.green, emphasized: true,
                             roundWhole: prefs.roundWhole)

                if result.totalPretax > 0 {
                    Group {
                        if result.contrib401k > 0 {
                            WaterfallRow(label: "401(k)", amount: scaled(result.contrib401k),
                                         total: refTotal, color: StubTheme.fica, isDeduction: true,
                                         roundWhole: prefs.roundWhole)
                        }
                        if result.hsa > 0 {
                            WaterfallRow(label: "HSA", amount: scaled(result.hsa),
                                         total: refTotal, color: StubTheme.fica, isDeduction: true,
                                         roundWhole: prefs.roundWhole)
                        }
                        if result.healthPremiums > 0 {
                            WaterfallRow(label: "Health premiums", amount: scaled(result.healthPremiums),
                                         total: refTotal, color: StubTheme.fica, isDeduction: true,
                                         roundWhole: prefs.roundWhole)
                        }
                        if result.otherPretax > 0 {
                            WaterfallRow(label: "Other pre-tax", amount: scaled(result.otherPretax),
                                         total: refTotal, color: StubTheme.fica, isDeduction: true,
                                         roundWhole: prefs.roundWhole)
                        }
                    }
                }

                Divider().background(StubTheme.hairline(scheme))

                WaterfallRow(label: "Federal income tax", amount: scaled(result.federalTax),
                             total: refTotal, color: StubTheme.federal, isDeduction: true,
                             roundWhole: prefs.roundWhole)
                if result.extraWithholdingAnnual > 0 {
                    WaterfallRow(label: "Extra withholding", amount: scaled(result.extraWithholdingAnnual),
                                 total: refTotal, color: StubTheme.federal, isDeduction: true,
                                 roundWhole: prefs.roundWhole)
                }
                WaterfallRow(label: "State income tax (\(calc.stateCode))", amount: scaled(result.stateTax),
                             total: refTotal, color: StubTheme.state, isDeduction: true,
                             roundWhole: prefs.roundWhole)
                WaterfallRow(label: "Social Security", amount: scaled(result.socialSecurity),
                             total: refTotal, color: StubTheme.fica, isDeduction: true,
                             roundWhole: prefs.roundWhole)
                WaterfallRow(label: "Medicare", amount: scaled(result.medicare),
                             total: refTotal, color: StubTheme.fica, isDeduction: true,
                             roundWhole: prefs.roundWhole)
                if result.postTaxAnnual > 0 {
                    WaterfallRow(label: "Post-tax deductions", amount: scaled(result.postTaxAnnual),
                                 total: refTotal, color: StubTheme.secondaryText(scheme), isDeduction: true,
                                 roundWhole: prefs.roundWhole)
                }

                Divider().background(StubTheme.hairline(scheme))

                WaterfallRow(label: "Take-home pay", amount: scaled(result.netAnnual),
                             total: refTotal, color: StubTheme.green, emphasized: true,
                             roundWhole: prefs.roundWhole)
            }
        }
    }

    private var ficaDetailCard: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Taxable income detail")
                    .font(.headline)
                    .foregroundStyle(StubTheme.primaryText(scheme))
                detailRow("Federal taxable income", scaled(result.federalTaxableIncome))
                detailRow("FICA-taxable wages", scaled(result.ficaWages))
                detailRow("Standard deduction (annual)", TaxTables2025.standardDeduction(calc.filing))
            }
        }
    }

    private func detailRow(_ label: String, _ value: Decimal) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(StubTheme.secondaryText(scheme))
            Spacer()
            Text(Format.currency(value, whole: prefs.roundWhole))
                .font(StubTheme.figureFont(.subheadline, weight: .medium))
                .foregroundStyle(StubTheme.primaryText(scheme))
        }
        .accessibilityElement(children: .combine)
    }

    private var disclaimerNote: some View {
        Text("Estimate only — not tax advice. State rates are approximate flat effective rates; figures use 2025 federal & FICA parameters.")
            .font(.caption2)
            .foregroundStyle(StubTheme.secondaryText(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.pie")
                .font(.system(size: 52))
                .foregroundStyle(StubTheme.green.opacity(0.7))
                .accessibilityHidden(true)
            Text("Nothing to break down yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(StubTheme.primaryText(scheme))
            Text("Enter a salary or hourly rate on the Calculator tab to see your full take-home breakdown here.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(StubTheme.secondaryText(scheme))
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
