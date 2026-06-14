import SwiftUI
import SwiftData

struct CalculatorView: View {
    @Binding var selection: RootView.Tab
    @Environment(CalculatorModel.self) private var calc
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var scenarios: [LoanScenario]

    @State private var showSaveSheet = false
    @State private var showPaywall = false
    @State private var savedToast = false

    private var symbol: String { settings.currency.symbol }
    private var isPro: Bool { UserDefaults.standard.bool(forKey: "isPro") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroResult
                    inputs
                    if calc.isValid {
                        breakdown
                        if calc.hasExtra { savingsCard }
                        donutCard
                        saveButton
                    } else {
                        validationCard
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Theme.bg)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap(enabled: settings.hapticsEnabled)
                        resetToNew()
                    } label: {
                        Image(systemName: "plus.circle")
                            .accessibilityLabel("New calculation")
                    }
                }
            }
            .overlay(alignment: .bottom) { savedToastView }
            .sheet(isPresented: $showSaveSheet) {
                SaveScenarioSheet(onSave: saveScenario)
                    .presentationDetents([.height(260)])
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Hero

    private var heroResult: some View {
        Card {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: calc.loanType.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text("Monthly payment")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkFaint)
                }
                if let s = calc.summary {
                    Text(Fmt.money(s.monthlyPayment, symbol: symbol))
                        .font(Theme.rounded(46, .bold))
                        .foregroundStyle(Theme.ink)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: s.monthlyPayment)
                        .accessibilityLabel("Monthly payment \(Fmt.money(s.monthlyPayment, symbol: symbol))")
                    if calc.hasExtra {
                        Text("plus \(Fmt.moneyWhole(calc.extraMonthly, symbol: symbol)) extra")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.accent)
                    }
                } else {
                    Text("—")
                        .font(Theme.rounded(46, .bold))
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityLabel("Enter valid inputs to see your payment")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Inputs

    private var inputs: some View {
        @Bindable var calc = calc
        return Card {
            VStack(spacing: 12) {
                HStack {
                    SectionLabel(text: "Loan details")
                    Spacer()
                }
                loanTypePicker
                CurrencyField(title: "Loan amount", symbol: symbol, value: $calc.principal,
                              accessibilityHint: "The amount you are borrowing.")
                PercentField(title: "Interest rate", value: $calc.annualRatePct,
                             accessibilityHint: "Annual interest rate.")
                TermField(termMonths: $calc.termMonths)
                DatePicker("First payment", selection: $calc.startDate, displayedComponents: .date)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(Theme.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .tint(Theme.accent)

                Divider().overlay(Theme.hairline).padding(.vertical, 2)

                HStack {
                    SectionLabel(text: "Extra payments (optional)")
                    Spacer()
                }
                CurrencyField(title: "Extra monthly", symbol: symbol, value: $calc.extraMonthly,
                              accessibilityHint: "Additional amount paid toward principal every month.")
                CurrencyField(title: "One-time extra", symbol: symbol, value: $calc.extraOneTime,
                              accessibilityHint: "A single additional payment.")
                if calc.extraOneTime > 0 {
                    OneTimeMonthField(month: $calc.extraOneTimeMonth, maxMonth: calc.termMonths)
                }
            }
        }
    }

    private var loanTypePicker: some View {
        @Bindable var calc = calc
        return Picker("Loan type", selection: $calc.loanType) {
            ForEach(LoanType.allCases) { t in
                Text(t.label).tag(t)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Loan type")
    }

    // MARK: - Breakdown

    private var breakdown: some View {
        Group {
            if let s = calc.summary {
                Card {
                    VStack(spacing: 12) {
                        HStack { SectionLabel(text: "Summary"); Spacer() }
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            StatTile(caption: "Total interest",
                                     value: Fmt.moneyWhole(s.totalInterest, symbol: symbol),
                                     tint: Theme.interestTint, symbol: "percent")
                            StatTile(caption: "Total paid",
                                     value: Fmt.moneyWhole(s.totalPaid, symbol: symbol),
                                     symbol: "sum")
                            StatTile(caption: "Payoff date",
                                     value: Fmt.monthYear(s.payoffDate),
                                     tint: Theme.accent, symbol: "calendar")
                            StatTile(caption: "Payments",
                                     value: "\(s.payoffMonths)",
                                     symbol: "number")
                        }
                    }
                }
            }
        }
    }

    private var savingsCard: some View {
        Group {
            if let s = calc.summary, (s.monthsSaved > 0 || s.interestSaved > 0) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.heart.fill")
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text("Your extra payments")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                        }
                        Text("By paying extra, you finish sooner and pay less interest.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                        HStack(spacing: 10) {
                            StatTile(caption: "Interest saved",
                                     value: Fmt.moneyWhole(s.interestSaved, symbol: symbol),
                                     tint: Theme.good, symbol: "arrow.down.right")
                            StatTile(caption: "Time saved",
                                     value: Fmt.termDescription(months: s.monthsSaved),
                                     tint: Theme.good, symbol: "clock.arrow.circlepath")
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }

    private var donutCard: some View {
        Group {
            if let s = calc.summary {
                Card {
                    VStack(spacing: 12) {
                        HStack { SectionLabel(text: "Principal vs interest"); Spacer() }
                        PrincipalInterestDonut(principal: s.totalPrincipal,
                                               interest: s.totalInterest,
                                               symbol: symbol)
                        DonutLegend(principal: s.totalPrincipal,
                                    interest: s.totalInterest,
                                    symbol: symbol)
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        VStack(spacing: 8) {
            Button {
                attemptSave()
            } label: {
                Label(calc.loadedScenarioID == nil ? "Save scenario" : "Update scenario",
                      systemImage: "square.and.arrow.down")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Color.white)
            }
            Button {
                selection = .amortization
            } label: {
                Label("View amortization schedule", systemImage: "list.bullet.rectangle")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.top, 2)
        }
    }

    private var validationCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.bad)
                        .accessibilityHidden(true)
                    Text("Check your inputs")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                }
                ForEach(calc.issues) { issue in
                    Text("• \(issue.rawValue)")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var savedToastView: some View {
        Group {
            if savedToast {
                Text("Scenario saved")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.accent, in: Capsule())
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Actions

    private func attemptSave() {
        // Free tier: 1 saved scenario. Updating the loaded one is always allowed.
        let isUpdatingExisting = calc.loadedScenarioID != nil &&
            scenarios.contains { $0.id == calc.loadedScenarioID }
        if !isPro && !isUpdatingExisting && scenarios.count >= 1 {
            showPaywall = true
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        showSaveSheet = true
    }

    private func saveScenario(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { calc.name = trimmed }

        if let id = calc.loadedScenarioID,
           let existing = scenarios.first(where: { $0.id == id }) {
            calc.apply(to: existing)
        } else {
            let newScenario = calc.makeScenario()
            context.insert(newScenario)
            calc.loadedScenarioID = newScenario.id
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { savedToast = false }
        }
    }

    private func resetToNew() {
        calc.name = "New mortgage"
        calc.loanType = .mortgage
        calc.principal = 350_000
        calc.annualRatePct = 6.25
        calc.termMonths = settings.defaultTermMonths
        calc.startDate = .now
        calc.extraMonthly = settings.defaultExtraMonthly
        calc.extraOneTime = 0
        calc.extraOneTimeMonth = 0
        calc.loadedScenarioID = nil
    }
}
