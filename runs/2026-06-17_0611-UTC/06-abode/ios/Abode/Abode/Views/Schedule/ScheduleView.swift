import SwiftUI
import Charts

/// Amortization schedule: year-grouped rows in a LazyVStack, a balance-over-time area
/// chart, cumulative principal vs interest, and an extra-payment toggle showing savings.
/// The schedule is built off the main thread with a loading state. Free for everyone.
struct ScheduleView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings

    @State private var model: CalculatorModel?
    @State private var schedule: AmortizationResult?
    @State private var impact: MortgageEngine.ExtraPaymentImpact?
    @State private var isBuilding = false
    @State private var applyExtra = false
    @State private var extraText = "200"
    @State private var buildToken = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AbodeTheme.appBackground(scheme).ignoresSafeArea()
                if let model {
                    content(model)
                } else {
                    LoadingStateView(message: "Preparing schedule…")
                }
            }
            .navigationTitle("Schedule")
        }
        .onAppear {
            if model == nil { model = CalculatorModel(settings: settings) }
            scheduleRebuild()
        }
    }

    @ViewBuilder
    private func content(_ model: CalculatorModel) -> some View {
        @Bindable var model = model
        ScrollView {
            VStack(spacing: 16) {
                inputsCard($model)

                if !model.hasValidLoan {
                    AbodeCard {
                        EmptyStateView(icon: "list.bullet.rectangle",
                                       title: "No schedule yet",
                                       message: "Enter a home price and down payment to build your amortization schedule.")
                    }
                } else if isBuilding || schedule == nil {
                    AbodeCard { LoadingStateView(message: "Building amortization schedule…") }
                } else if let schedule {
                    extraCard()
                    if applyExtra, let impact { savingsCard(impact) }
                    balanceChartCard(schedule)
                    splitChartCard(schedule)
                    rowsCard(schedule)
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Inputs

    private func inputsCard(_ model: Bindable<CalculatorModel>) -> some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 14) {
                AbodeSectionHeader(title: "Loan", systemImage: "house")
                AbodeNumberField(title: "Home price", symbol: Format.currencySymbol, prompt: "350,000", text: model.homePriceText)
                AbodeNumberField(title: model.downIsPercent.wrappedValue ? "Down payment (%)" : "Down payment",
                                 symbol: model.downIsPercent.wrappedValue ? "%" : Format.currencySymbol,
                                 prompt: model.downIsPercent.wrappedValue ? "20" : "70,000",
                                 text: model.downPaymentText)
                AbodeNumberField(title: "Interest rate", symbol: "%", prompt: "6.5", text: model.rateText)
                AbodeSegmentPicker(title: "Loan term",
                                   options: CalculatorModel.termOptions,
                                   selection: model.termYears)
            }
        }
        .onChange(of: model.wrappedValue.homePriceText) { _, _ in scheduleRebuild() }
        .onChange(of: model.wrappedValue.downPaymentText) { _, _ in scheduleRebuild() }
        .onChange(of: model.wrappedValue.rateText) { _, _ in scheduleRebuild() }
        .onChange(of: model.wrappedValue.termYears) { _, _ in scheduleRebuild() }
    }

    // MARK: Extra-payment toggle

    private func extraCard() -> some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(get: { applyExtra }, set: { applyExtra = $0; scheduleRebuild() })) {
                    Text("Apply extra monthly principal")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AbodeTheme.primaryText(scheme))
                }
                .tint(AbodeTheme.accent)

                if applyExtra {
                    AbodeNumberField(title: "Extra each month", symbol: Format.currencySymbol, prompt: "200", text: $extraText,
                                     help: "Recomputes payoff and interest saved.")
                        .onChange(of: extraText) { _, _ in scheduleRebuild() }
                }
            }
        }
    }

    private func savingsCard(_ impact: MortgageEngine.ExtraPaymentImpact) -> some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "With extra payments", systemImage: "bolt.fill")
                StatRow(label: "Months saved", value: Format.termFromMonths(impact.monthsSaved), emphasis: true, accent: AbodeTheme.positive)
                StatRow(label: "Interest saved", value: Format.money(impact.interestSaved, forceWhole: true), accent: AbodeTheme.positive)
                StatRow(label: "Interest (baseline)", value: Format.money(impact.baselineInterest, forceWhole: true))
                StatRow(label: "Interest (accelerated)", value: Format.money(impact.acceleratedInterest, forceWhole: true))
            }
        }
    }

    // MARK: Charts

    private func balanceChartCard(_ schedule: AmortizationResult) -> some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "Balance over time", systemImage: "chart.line.downtrend.xyaxis")
                Chart(downsample(schedule.rows)) { row in
                    AreaMark(
                        x: .value("Month", row.id),
                        y: .value("Balance", row.balance.doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [AbodeTheme.accent.opacity(0.5), AbodeTheme.accent.opacity(0.05)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    LineMark(
                        x: .value("Month", row.id),
                        y: .value("Balance", row.balance.doubleValue)
                    )
                    .foregroundStyle(AbodeTheme.accent)
                }
                .chartYAxis { AxisMarks(format: .currency(code: settings.currencyCode).precision(.fractionLength(0))) }
                .frame(height: 200)
                .accessibilityLabel("Remaining balance over time")
                .accessibilityValue("Starts at \(Format.money(loanPrincipal, forceWhole: true)), reaches zero in \(Format.termFromMonths(schedule.monthsToPayoff)).")
            }
        }
    }

    private func splitChartCard(_ schedule: AmortizationResult) -> some View {
        let cumulative = cumulativeSplit(schedule.rows)
        return AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "Principal vs interest paid", systemImage: "chart.bar.xaxis")
                Chart {
                    ForEach(cumulative) { p in
                        AreaMark(x: .value("Month", p.month), y: .value("Amount", p.principal.doubleValue),
                                 series: .value("Series", "Principal"))
                            .foregroundStyle(AbodeTheme.principalInterest)
                    }
                    ForEach(cumulative) { p in
                        AreaMark(x: .value("Month", p.month), y: .value("Amount", p.interest.doubleValue),
                                 series: .value("Series", "Interest"))
                            .foregroundStyle(AbodeTheme.pmi.opacity(0.85))
                    }
                }
                .chartForegroundStyleScale([
                    "Principal": AbodeTheme.principalInterest,
                    "Interest": AbodeTheme.pmi.opacity(0.85)
                ])
                .chartYAxis { AxisMarks(format: .currency(code: settings.currencyCode).precision(.fractionLength(0))) }
                .frame(height: 200)
                .accessibilityLabel("Cumulative principal versus interest paid over the life of the loan")
            }
        }
    }

    // MARK: Rows (year-grouped, lazy)

    private func rowsCard(_ schedule: AmortizationResult) -> some View {
        AbodeCard {
            VStack(alignment: .leading, spacing: 12) {
                AbodeSectionHeader(title: "Payment schedule", systemImage: "list.number")
                Text("\(schedule.rows.count) payments • paid off \(Format.monthYear(schedule.payoffDate))")
                    .font(.caption)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                LazyVStack(spacing: 8) {
                    ForEach(yearGroups(schedule.rows)) { group in
                        ScheduleYearRow(group: group)
                    }
                }
            }
        }
    }

    // MARK: Building (async, off main thread)

    private var loanPrincipal: Decimal { model?.loanInput.principal ?? 0 }

    private func scheduleRebuild() {
        guard let model, model.hasValidLoan else {
            schedule = nil; impact = nil; return
        }
        let input = model.loanInput
        let extra = applyExtra ? Parse.decimalOrZero(extraText) : 0
        let useExtra = applyExtra
        buildToken += 1
        let token = buildToken
        isBuilding = true

        Task {
            // Heavy work off the main actor.
            let built = await Task.detached(priority: .userInitiated) { () -> (AmortizationResult, MortgageEngine.ExtraPaymentImpact?) in
                let sched = MortgageEngine.amortize(input, extraMonthly: useExtra ? extra : 0)
                let imp = useExtra ? MortgageEngine.extraPaymentImpact(input, extraMonthly: extra) : nil
                return (sched, imp)
            }.value

            await MainActor.run {
                guard token == buildToken else { return }  // a newer build superseded us
                schedule = built.0
                impact = built.1
                isBuilding = false
            }
        }
    }

    // MARK: Chart helpers

    /// Caps points so a 360+ row schedule charts smoothly.
    private func downsample(_ rows: [AmortizationRow]) -> [AmortizationRow] {
        guard rows.count > 120 else { return rows }
        let stride = max(1, rows.count / 120)
        var out: [AmortizationRow] = []
        out.reserveCapacity(rows.count / stride + 1)
        for (i, r) in rows.enumerated() where i % stride == 0 { out.append(r) }
        if let last = rows.last, out.last?.id != last.id { out.append(last) }
        return out
    }

    private struct CumulativePoint: Identifiable {
        let id: Int
        let month: Int
        let principal: Decimal
        let interest: Decimal
    }

    private func cumulativeSplit(_ rows: [AmortizationRow]) -> [CumulativePoint] {
        var principalSum: Decimal = 0
        var interestSum: Decimal = 0
        var points: [CumulativePoint] = []
        let stride = max(1, rows.count / 120)
        for (i, r) in rows.enumerated() {
            principalSum += r.principal
            interestSum += r.interest
            if i % stride == 0 || i == rows.count - 1 {
                points.append(CumulativePoint(id: r.id, month: r.id, principal: principalSum, interest: interestSum))
            }
        }
        return points
    }

    private func yearGroups(_ rows: [AmortizationRow]) -> [ScheduleYearGroup] {
        var groups: [ScheduleYearGroup] = []
        var current: [AmortizationRow] = []
        var yearIndex = 1
        for row in rows {
            current.append(row)
            if current.count == 12 || row.id == rows.last?.id {
                groups.append(ScheduleYearGroup(id: yearIndex, year: yearIndex, rows: current))
                current = []
                yearIndex += 1
            }
        }
        return groups
    }
}
