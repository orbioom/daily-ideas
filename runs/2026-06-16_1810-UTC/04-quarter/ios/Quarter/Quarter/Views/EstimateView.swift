import SwiftUI
import SwiftData

/// The dashboard: hero "estimated tax you'll owe", set-aside %, breakdown, and
/// editable inputs with live recompute.
struct EstimateView: View {
    @Environment(\.modelContext) private var context
    @Environment(StoreManager.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("defaultFilingStatus") private var defaultFilingStatus = FilingStatus.single.rawValue
    @AppStorage("defaultStateRate") private var defaultStateRate = 0.0
    @AppStorage("defaultTaxYear") private var defaultTaxYear = 2025

    @Query private var incomes: [IncomeEntry]
    @Query private var expenses: [ExpenseEntry]
    @Query private var scenarios: [TaxScenario]

    @State private var vm = EstimateViewModel()
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showSavedToast = false
    @State private var didSeedDefaults = false

    private var ledgerIncomeTotal: Double {
        incomes.filter { $0.isBusiness }.reduce(0) { $0 + $1.amount }
    }
    private var ledgerExpenseTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    heroSection
                    if vm.isComputable {
                        breakdownSection
                        ratesSection
                    }
                    inputsSection
                    saveScenarioSection
                    disclaimerNote
                }
                .padding(Theme.Spacing.m)
            }
            .background(Theme.background)
            .navigationTitle("Estimate")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .overlay(alignment: .bottom) {
                if showSavedToast {
                    ToastView(text: "Scenario saved")
                        .padding(.bottom, Theme.Spacing.l)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            guard !didSeedDefaults else { return }
            vm.applyDefaults(filingStatusRaw: defaultFilingStatus,
                             stateRate: defaultStateRate,
                             year: defaultTaxYear)
            didSeedDefaults = true
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        let est = vm.estimate
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if vm.isComputable {
                heroComputed(est)
            } else {
                heroIdle
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .background(
            LinearGradient(
                colors: [Theme.ink, Theme.ink.opacity(0.92)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous))
    }

    private func heroComputed(_ est: TaxEstimate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Label("Computed for \(est.year)", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Text(est.filingStatus.shortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityElement(children: .combine)

            Text("ESTIMATED TAX YOU'LL OWE")
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.7))

            Text(Format.money(est.totalTax))
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .snappy, value: est.totalTax)
                .accessibilityLabel("Estimated tax you'll owe for \(est.year)")
                .accessibilityValue(Format.money(est.totalTax))

            setAsideBadge(est)

            if est.federalWithholding > 0 {
                balanceLine(est)
            }
        }
    }

    private func setAsideBadge(_ est: TaxEstimate) -> some View {
        let pct = Format.percentFromFraction(est.setAsidePercent)
        return HStack(spacing: Theme.Spacing.s) {
            Image(systemName: "banknote")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Set aside about ")
                .foregroundStyle(.white.opacity(0.85))
            + Text(pct).foregroundStyle(.white).fontWeight(.bold)
            + Text(" of what you earn").foregroundStyle(.white.opacity(0.85))
        }
        .font(.subheadline)
        .padding(.vertical, 10)
        .padding(.horizontal, Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recommended set-aside")
        .accessibilityValue("About \(pct) of what you earn")
    }

    private func balanceLine(_ est: TaxEstimate) -> some View {
        let owes = est.owes
        let amount = abs(est.balanceDueOrRefund)
        return HStack {
            Text(owes ? "Balance due after withholding" : "Estimated refund")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(Format.money(amount))
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(owes ? Theme.warning : Theme.accent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(owes ? "Balance due after withholding" : "Estimated refund")
        .accessibilityValue(Format.money(amount))
    }

    private var heroIdle: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Image(systemName: "function")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Enter your income to estimate")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Add your self-employment income below — or pull totals straight from your Ledger — and Quarter will compute your estimated tax live.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Breakdown

    private var breakdownSection: some View {
        let est = vm.estimate
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: "Breakdown", systemImage: "list.bullet")
            VStack(spacing: 0) {
                BreakdownRow(label: "Self-employment tax", amount: est.seTax,
                             systemImage: "person.fill")
                Divider()
                BreakdownRow(label: "Federal income tax", amount: est.federalIncomeTax,
                             systemImage: "building.columns")
                if est.stateTax > 0 {
                    Divider()
                    BreakdownRow(label: "State tax", amount: est.stateTax,
                                 systemImage: "map", isApprox: true)
                }
                Divider()
                BreakdownRow(label: "Total estimated tax", amount: est.totalTax,
                             systemImage: "sum", valueColor: Theme.accent)
            }
            .card()
        }
    }

    private var ratesSection: some View {
        let est = vm.estimate
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: "Your rates", systemImage: "percent")
            HStack(spacing: Theme.Spacing.m) {
                StatChip(title: "Effective rate",
                         value: Format.percentFromFraction(est.effectiveRate))
                StatChip(title: "Marginal bracket",
                         value: Format.percentFromFraction(est.marginalRate),
                         tint: Theme.accentDeep)
            }
            Text("Effective = total tax ÷ gross income. Marginal = the top federal bracket your taxable income reaches.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Inputs

    @ViewBuilder
    private var inputsSection: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: "Your numbers", systemImage: "slider.horizontal.3")
            VStack(spacing: 0) {
                // Year picker — multi-year is Pro; free is current year only.
                yearPicker
                Divider()
                Picker("Filing status", selection: $vm.filingStatus) {
                    ForEach(FilingStatus.allCases) { status in
                        Text(status.label).tag(status)
                    }
                }
                .padding(.vertical, 4)
                Divider()
                CurrencyField(label: "Self-employment income", text: $vm.incomeText,
                              systemImage: "briefcase")
                Divider()
                CurrencyField(label: "Business expenses", text: $vm.expensesText,
                              systemImage: "minus.circle")
                Divider()
                CurrencyField(label: "Other W-2 income", text: $vm.otherW2Text,
                              systemImage: "building.2")
                Divider()
                CurrencyField(label: "Federal withholding", text: $vm.withholdingText,
                              systemImage: "tray.and.arrow.down")
                Divider()
                CurrencyField(label: "State rate %", text: $vm.stateRateText,
                              systemImage: "map", prompt: "0", isPercent: true)
            }
            .card()

            if ledgerIncomeTotal > 0 || ledgerExpenseTotal > 0 {
                Button {
                    vm.applyLedger(incomeTotal: ledgerIncomeTotal,
                                   expenseTotal: ledgerExpenseTotal)
                } label: {
                    Label("Pull totals from Ledger (\(Format.money(ledgerIncomeTotal)) income, \(Format.money(ledgerExpenseTotal)) expenses)",
                          systemImage: "arrow.down.doc")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
            }
        }
        .onChange(of: vm.filingStatus) { _, _ in Haptics.selection() }
    }

    @ViewBuilder
    private var yearPicker: some View {
        @Bindable var vm = vm
        if store.isPro {
            Picker("Tax year", selection: $vm.year) {
                ForEach(TaxTables.supportedYears, id: \.self) { y in
                    Text(String(y)).tag(y)
                }
            }
            .padding(.vertical, 4)
        } else {
            HStack {
                Text("Tax year")
                Spacer()
                Text(String(vm.year))
                    .foregroundStyle(Theme.secondaryText)
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Multi-year")
                        ProBadge()
                    }
                    .font(.caption)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Save scenario

    @ViewBuilder
    private var saveScenarioSection: some View {
        if vm.isComputable {
            let canSaveFree = scenarios.isEmpty
            Button {
                if store.isPro || canSaveFree {
                    saveScenario()
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("Save as scenario", systemImage: "square.and.arrow.down")
                    if !store.isPro && !canSaveFree {
                        Spacer()
                        ProBadge()
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(Theme.accent)
        }
    }

    private func saveScenario() {
        let count = scenarios.count + 1
        let scenario = TaxScenario(
            name: "Scenario \(count)",
            year: vm.year,
            filingStatusRaw: vm.filingStatus.rawValue,
            selfEmploymentIncome: vm.incomeValue.doubleValue,
            businessExpenses: vm.expensesValue.doubleValue,
            otherW2Income: vm.otherW2Value.doubleValue,
            federalWithholding: vm.withholdingValue.doubleValue,
            stateRatePct: vm.stateRateValue.doubleValue
        )
        context.insert(scenario)
        try? context.save()
        Haptics.success()
        withAnimation { showSavedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { withAnimation { showSavedToast = false } }
        }
    }

    private var disclaimerNote: some View {
        Text("Estimate only — uses published \(vm.year) federal figures and your flat state rate. Not tax advice.")
            .font(.caption2)
            .foregroundStyle(Theme.tertiaryText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, Theme.Spacing.s)
    }
}

// MARK: - Toast

struct ToastView: View {
    let text: String
    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
            .background(Theme.ink)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(radius: 8, y: 4)
            .accessibilityAddTraits(.isStaticText)
    }
}
