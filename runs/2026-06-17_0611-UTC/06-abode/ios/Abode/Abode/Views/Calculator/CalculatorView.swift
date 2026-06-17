import SwiftUI
import SwiftData

/// The centerpiece: live mortgage inputs → monthly payment hero + PITI breakdown,
/// donut, total interest, payoff date, and loan-to-value. Free for everyone.
struct CalculatorView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MortgageScenario.createdAt) private var scenarios: [MortgageScenario]

    @State private var model: CalculatorModel?
    @State private var showSaveSheet = false
    @State private var showPaywall = false
    @State private var saveName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AbodeTheme.appBackground(scheme).ignoresSafeArea()
                if let model {
                    content(model)
                } else {
                    LoadingStateView(message: "Preparing calculator…")
                }
            }
            .navigationTitle("Calculator")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap(settings.hapticsEnabled)
                        saveName = defaultScenarioName()
                        showSaveSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .disabled(model?.hasValidLoan != true)
                    .accessibilityLabel("Save scenario")
                }
            }
            .sheet(isPresented: $showSaveSheet) { saveSheet }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
        .onAppear {
            if model == nil { model = CalculatorModel(settings: settings) }
        }
    }

    @ViewBuilder
    private func content(_ model: CalculatorModel) -> some View {
        @Bindable var model = model
        ScrollView {
            VStack(spacing: 16) {
                heroCard(model)
                inputsCard($model)
                if model.hasValidLoan {
                    donutCard(model)
                    summaryCard(model)
                } else {
                    AbodeCard {
                        EmptyStateView(
                            icon: "house",
                            title: "Enter a home price",
                            message: "Add a home price and a down payment below 100% to see your monthly payment."
                        )
                    }
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Hero

    private func heroCard(_ model: CalculatorModel) -> some View {
        let total = model.breakdown.total
        return AbodeCard(padding: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Estimated monthly payment")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                Text(Format.money(total, forceCents: true))
                    .font(AbodeTheme.figure(.largeTitle, weight: .bold))
                    .foregroundStyle(AbodeTheme.accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("\(Format.money(model.breakdown.principalAndInterest, forceCents: true)) principal & interest")
                    .font(.footnote)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Estimated monthly payment")
            .accessibilityValue("\(Format.money(total, forceCents: true)), including \(Format.money(model.breakdown.principalAndInterest, forceCents: true)) principal and interest")
        }
    }

    // MARK: Inputs

    private func inputsCard(_ model: Bindable<CalculatorModel>) -> some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 14) {
                AbodeSectionHeader(title: "Loan details", systemImage: "slider.horizontal.3")

                AbodeNumberField(title: "Home price", symbol: Format.currencySymbol,
                                 prompt: "350,000", text: model.homePriceText)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Down payment")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AbodeTheme.primaryText(scheme))
                        Spacer()
                        Picker("Down payment unit", selection: model.downIsPercent) {
                            Text("%").tag(true)
                            Text(Format.currencySymbol).tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 96)
                        .accessibilityLabel("Down payment unit")
                    }
                    AbodeNumberField(
                        title: "",
                        symbol: model.downIsPercent.wrappedValue ? "%" : Format.currencySymbol,
                        prompt: model.downIsPercent.wrappedValue ? "20" : "70,000",
                        text: model.downPaymentText,
                        help: downHelp(model.wrappedValue)
                    )
                }

                AbodeNumberField(title: "Interest rate", symbol: "%", prompt: "6.5", text: model.rateText)

                AbodeSegmentPicker(
                    title: "Loan term",
                    options: CalculatorModel.termOptions,
                    selection: model.termYears
                )

                Divider().overlay(AbodeTheme.hairline(scheme))

                AbodeSectionHeader(title: "Taxes & costs", systemImage: "building.columns")
                AbodeNumberField(title: "Property tax (annual %)", symbol: "%", prompt: "1.1", text: model.propertyTaxText)
                AbodeNumberField(title: "Homeowners insurance (annual)", symbol: Format.currencySymbol, prompt: "1,500", text: model.annualInsuranceText)
                AbodeNumberField(title: "HOA dues (monthly)", symbol: Format.currencySymbol, prompt: "0", text: model.monthlyHOAText)
                AbodeNumberField(title: "Extra principal (monthly)", symbol: Format.currencySymbol, prompt: "0", text: model.extraMonthlyText,
                                 help: "Modeled in detail on the Schedule tab.")
            }
        }
    }

    private func downHelp(_ model: CalculatorModel) -> String {
        let input = model.loanInput
        let pct = Format.percentValue(model.downPercent, fractionDigits: 1)
        if MortgageEngine.pmiAppliesAtStart(input) {
            return "\(Format.money(input.downPayment, forceWhole: true)) (\(pct)) — under 20%, so PMI applies."
        }
        return "\(Format.money(input.downPayment, forceWhole: true)) (\(pct)) — 20% or more, no PMI."
    }

    // MARK: Donut

    private func donutCard(_ model: CalculatorModel) -> some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 14) {
                AbodeSectionHeader(title: "Monthly breakdown", systemImage: "chart.pie")
                PaymentDonut(breakdown: model.breakdown)
            }
        }
    }

    // MARK: Summary

    private func summaryCard(_ model: CalculatorModel) -> some View {
        let input = model.loanInput
        let schedule = MortgageEngine.amortize(input)
        return AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "Loan summary", systemImage: "doc.text.magnifyingglass")
                StatRow(label: "Loan amount", value: Format.money(input.principal, forceWhole: true), emphasis: true)
                StatRow(label: "Loan-to-value", value: Format.percentFraction(input.ltv, fractionDigits: 1))
                StatRow(label: "Total interest", value: Format.money(schedule.totalInterest, forceWhole: true), accent: AbodeTheme.pmi)
                StatRow(label: "Total of payments", value: Format.money(schedule.totalPaid, forceWhole: true))
                StatRow(label: "Payoff", value: Format.monthYear(schedule.payoffDate))
                if let drop = schedule.pmiDropMonth {
                    StatRow(label: "PMI drops", value: "after \(Format.termFromMonths(drop))", accent: AbodeTheme.positive)
                }
            }
        }
    }

    // MARK: Save sheet

    private var saveSheet: some View {
        NavigationStack {
            ZStack {
                AbodeTheme.appBackground(scheme).ignoresSafeArea()
                VStack(spacing: 18) {
                    if !pro.isPro && scenarios.count >= ProStore.freeScenarioLimit {
                        ProLockView(
                            feature: "Unlimited scenarios",
                            detail: "The free tier saves up to \(ProStore.freeScenarioLimit) scenarios. Upgrade to save and compare as many as you like.",
                            showPaywall: $showPaywall
                        )
                    } else {
                        AbodeCard {
                            VStack(alignment: .leading, spacing: 10) {
                                AbodeSectionHeader(title: "Scenario name")
                                TextField("My home", text: $saveName)
                                    .textFieldStyle(.roundedBorder)
                                    .accessibilityLabel("Scenario name")
                            }
                        }
                        Button("Save scenario") { saveScenario() }
                            .buttonStyle(AbodePrimaryButtonStyle())
                            .disabled(saveName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showSaveSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func defaultScenarioName() -> String {
        let price = (model?.loanInput.homePrice).map { Format.money($0, forceWhole: true) } ?? "Home"
        return "\(price) home"
    }

    private func saveScenario() {
        guard let model else { return }
        let name = saveName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        modelContext.insert(model.makeScenario(name: name))
        try? modelContext.save()
        Haptics.success(settings.hapticsEnabled)
        showSaveSheet = false
    }
}
