import SwiftUI
import Charts

/// Affordability solver: income, debts, down payment, rate, term, DTI → max home price,
/// max loan, and resulting payment, with a DTI gauge. Pro-gated.
struct AffordabilityView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro

    @State private var incomeText = "8000"
    @State private var debtsText = "600"
    @State private var downText = "60000"
    @State private var rateText = "6.5"
    @State private var termYears = 30
    @State private var frontEndText = "28"
    @State private var backEndText = "36"
    @State private var propertyTaxText = "1.1"
    @State private var insuranceText = "1500"
    @State private var hoaText = "0"
    @State private var showPaywall = false

    private var result: AffordabilityResult {
        MortgageEngine.affordability(
            grossMonthlyIncome: Parse.decimalOrZero(incomeText),
            monthlyDebts: Parse.decimalOrZero(debtsText),
            downPayment: Parse.decimalOrZero(downText),
            annualRatePct: Parse.decimalOrZero(rateText),
            termYears: termYears,
            frontEndDTI: Parse.decimalOrZero(frontEndText) / 100,
            backEndDTI: Parse.decimalOrZero(backEndText) / 100,
            propertyTaxPct: Parse.decimalOrZero(propertyTaxText),
            annualInsurance: Parse.decimalOrZero(insuranceText),
            monthlyHOA: Parse.decimalOrZero(hoaText)
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
                                feature: "Affordability solver",
                                detail: "Find the maximum home price you can afford from your income, debts, and DTI targets, with front- and back-end ratio guidance.",
                                showPaywall: $showPaywall
                            )
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Affordability")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                resultCard
                gaugeCard
                inputsCard
                explanationCard
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var resultCard: some View {
        let r = result
        return AbodeCard(padding: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Maximum home price")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                Text(Format.money(r.maxHomePrice, forceWhole: true))
                    .font(AbodeTheme.figure(.largeTitle, weight: .bold))
                    .foregroundStyle(AbodeTheme.accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Divider().overlay(AbodeTheme.hairline(scheme)).padding(.vertical, 4)
                StatRow(label: "Max loan", value: Format.money(r.maxLoanAmount, forceWhole: true))
                StatRow(label: "Est. monthly payment", value: Format.money(r.estimatedPayment, forceCents: true), emphasis: true)
                StatRow(label: "Principal & interest", value: Format.money(r.principalAndInterest, forceCents: true))
                StatRow(label: "Limited by", value: r.bindingConstraint)
            }
            .accessibilityElement(children: .contain)
        }
    }

    private var gaugeCard: some View {
        let r = result
        return AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "Debt-to-income", systemImage: "gauge.with.dots.needle.50percent")
                DTIGauge(label: "Front-end (housing)", value: r.frontEndDTI, cap: Parse.decimalOrZero(frontEndText) / 100)
                DTIGauge(label: "Back-end (all debts)", value: r.backEndDTI, cap: Parse.decimalOrZero(backEndText) / 100)
            }
        }
    }

    private var inputsCard: some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 14) {
                AbodeSectionHeader(title: "Your finances", systemImage: "dollarsign.circle")
                AbodeNumberField(title: "Gross monthly income", symbol: Format.currencySymbol, prompt: "8,000", text: $incomeText)
                AbodeNumberField(title: "Existing monthly debts", symbol: Format.currencySymbol, prompt: "600", text: $debtsText,
                                 help: "Car loans, student loans, minimum credit-card payments.")
                AbodeNumberField(title: "Down payment", symbol: Format.currencySymbol, prompt: "60,000", text: $downText)
                AbodeNumberField(title: "Interest rate", symbol: "%", prompt: "6.5", text: $rateText)
                AbodeSegmentPicker(title: "Loan term", options: CalculatorModel.termOptions, selection: $termYears)

                Divider().overlay(AbodeTheme.hairline(scheme))
                AbodeSectionHeader(title: "Ratios & assumptions", systemImage: "percent")
                AbodeNumberField(title: "Front-end DTI target", symbol: "%", prompt: "28", text: $frontEndText)
                AbodeNumberField(title: "Back-end DTI target", symbol: "%", prompt: "36", text: $backEndText)
                AbodeNumberField(title: "Property tax (annual %)", symbol: "%", prompt: "1.1", text: $propertyTaxText)
                AbodeNumberField(title: "Homeowners insurance (annual)", symbol: Format.currencySymbol, prompt: "1,500", text: $insuranceText)
                AbodeNumberField(title: "HOA dues (monthly)", symbol: Format.currencySymbol, prompt: "0", text: $hoaText)
            }
        }
    }

    private var explanationCard: some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 8) {
                AbodeSectionHeader(title: "How this works", systemImage: "info.circle")
                Text("Lenders use two ratios. The front-end ratio caps your housing payment (PITI) at about 28% of gross income. The back-end ratio caps housing plus all other debts at about 36%. Abode solves for the largest loan that satisfies both, then adds your down payment to get the max price.")
                    .font(.footnote)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                Text("These are guidelines — actual approval depends on credit, reserves, and the lender. Estimates only, not financial advice.")
                    .font(.caption2)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
            }
        }
    }
}

/// A horizontal DTI gauge: a filled bar against a cap marker.
struct DTIGauge: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let value: Decimal   // 0...1
    let cap: Decimal     // 0...1

    private var fraction: Double {
        let f = (value / max(0.0001, cap)).doubleValue
        return min(max(f, 0), 1.0)
    }

    private var overCap: Bool { value > cap }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(AbodeTheme.primaryText(scheme))
                Spacer()
                Text(Format.percentFraction(value, fractionDigits: 1))
                    .font(AbodeTheme.figure(.subheadline, weight: .semibold))
                    .foregroundStyle(overCap ? AbodeTheme.danger : AbodeTheme.positive)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AbodeTheme.track(scheme))
                    Capsule()
                        .fill(overCap ? AbodeTheme.danger : AbodeTheme.positive)
                        .frame(width: max(4, geo.size.width * fraction))
                }
            }
            .frame(height: 10)
            Text("Cap \(Format.percentFraction(cap, fractionDigits: 0))")
                .font(.caption2)
                .foregroundStyle(AbodeTheme.secondaryText(scheme))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue("\(Format.percentFraction(value, fractionDigits: 1)) of a \(Format.percentFraction(cap, fractionDigits: 0)) cap")
    }
}
