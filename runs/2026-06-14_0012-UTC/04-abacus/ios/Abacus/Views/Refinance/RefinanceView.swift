import SwiftUI
import Charts

struct RefinanceView: View {
    @Environment(AppSettings.self) private var settings

    @State private var currentBalance: Double = 280_000
    @State private var currentRate: Double = 7.0
    @State private var remainingMonths: Int = 300
    @State private var newRate: Double = 5.5
    @State private var newTermMonths: Int = 360
    @State private var closingCosts: Double = 4_000
    @State private var showPaywall = false

    private var symbol: String { settings.currency.symbol }
    private var isPro: Bool { UserDefaults.standard.bool(forKey: "isPro") }

    private var isValid: Bool {
        currentBalance > 0 && currentRate >= 0 && currentRate <= 40 &&
        remainingMonths >= 1 && remainingMonths <= 600 &&
        newRate >= 0 && newRate <= 40 && newTermMonths >= 1 && newTermMonths <= 600
    }

    private var refi: LoanMath.Refi {
        LoanMath.refinance(currentBalance: currentBalance,
                           currentRatePct: currentRate,
                           remainingMonths: remainingMonths,
                           newRatePct: newRate,
                           newTermMonths: newTermMonths,
                           closingCosts: closingCosts)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isPro {
                    proContent
                } else {
                    locked
                }
            }
            .background(Theme.bg)
            .navigationTitle("Refinance")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Locked (free) state

    private var locked: some View {
        VStack(spacing: 18) {
            EmptyStateView(symbol: "arrow.triangle.2.circlepath",
                           title: "Refinance is a Pro tool",
                           message: "See your new payment, lifetime interest change, and exactly when refinancing pays for itself.",
                           actionTitle: "Unlock Abacus Pro") {
                showPaywall = true
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Pro content

    private var proContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                verdictHero
                currentCard
                newCard
                if isValid { resultCard; chartCard } else { hint }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var verdictHero: some View {
        let r = refi
        let saves = r.monthlyDiff > 0
        return Card {
            VStack(spacing: 6) {
                Text(saves ? "You'd save monthly" : "New payment changes by")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkFaint)
                Text(isValid ? Fmt.money(abs(r.monthlyDiff), symbol: symbol) : "—")
                    .font(Theme.rounded(40, .bold))
                    .foregroundStyle(isValid ? (saves ? Theme.good : Theme.bad) : Theme.inkFaint)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: r.monthlyDiff)
                if isValid {
                    if let be = r.breakEvenMonths {
                        Text("Breaks even in \(Fmt.termDescription(months: be))")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.accent)
                    } else {
                        Text(saves ? "" : "No monthly saving at this rate")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Refinance result")
            .accessibilityValue(accessibilitySummary)
        }
    }

    private var accessibilitySummary: String {
        guard isValid else { return "Enter valid loan details." }
        let r = refi
        if r.monthlyDiff > 0, let be = r.breakEvenMonths {
            return "Refinancing saves \(Fmt.money(r.monthlyDiff, symbol: symbol)) per month and breaks even in \(Fmt.termDescription(months: be))."
        }
        return "Refinancing does not lower your monthly payment at these terms."
    }

    private var currentCard: some View {
        Card {
            VStack(spacing: 12) {
                HStack { SectionLabel(text: "Current loan"); Spacer() }
                CurrencyField(title: "Remaining balance", symbol: symbol, value: $currentBalance)
                PercentField(title: "Current rate", value: $currentRate)
                RefiTermField(title: "Months remaining", termMonths: $remainingMonths)
            }
        }
    }

    private var newCard: some View {
        Card {
            VStack(spacing: 12) {
                HStack { SectionLabel(text: "New loan"); Spacer() }
                PercentField(title: "New rate", value: $newRate)
                RefiTermField(title: "New term", termMonths: $newTermMonths)
                CurrencyField(title: "Closing costs", symbol: symbol, value: $closingCosts)
            }
        }
    }

    private var resultCard: some View {
        let r = refi
        return Card {
            VStack(spacing: 10) {
                HStack { SectionLabel(text: "Comparison"); Spacer() }
                InfoRow(label: "Current payment", value: Fmt.money(r.currentPayment, symbol: symbol))
                InfoRow(label: "New payment", value: Fmt.money(r.newPayment, symbol: symbol), valueTint: Theme.accent)
                Divider().overlay(Theme.hairline)
                InfoRow(label: "Current lifetime interest", value: Fmt.moneyWhole(r.currentLifetimeInterest, symbol: symbol))
                InfoRow(label: "New lifetime interest", value: Fmt.moneyWhole(r.newLifetimeInterest, symbol: symbol))
                InfoRow(label: "Closing costs", value: Fmt.moneyWhole(r.closingCosts, symbol: symbol))
                Divider().overlay(Theme.hairline)
                InfoRow(label: "Lifetime savings (after costs)",
                        value: (r.lifetimeInterestDiff >= 0 ? "+" : "−") + Fmt.moneyWhole(abs(r.lifetimeInterestDiff), symbol: symbol),
                        valueTint: r.lifetimeInterestDiff >= 0 ? Theme.good : Theme.bad)
            }
        }
    }

    private var chartCard: some View {
        let r = refi
        let data = [
            ("Current", r.currentLifetimeInterest, Theme.baselineTint),
            ("New", r.newLifetimeInterest + r.closingCosts, Theme.accent)
        ]
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Total interest + costs")
                Chart {
                    ForEach(data, id: \.0) { item in
                        BarMark(
                            x: .value("Amount", item.1),
                            y: .value("Plan", item.0)
                        )
                        .foregroundStyle(item.2)
                        .cornerRadius(6)
                        .annotation(position: .trailing) {
                            Text(Fmt.moneyWhole(item.1, symbol: symbol))
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 110)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Total interest plus costs comparison")
                .accessibilityValue("Current plan \(Fmt.moneyWhole(r.currentLifetimeInterest, symbol: symbol)), new plan \(Fmt.moneyWhole(r.newLifetimeInterest + r.closingCosts, symbol: symbol)).")
            }
        }
    }

    private var hint: some View {
        Card {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Enter a balance, rates of 0–40%, and terms of 1–600 months.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Month-based term field for the refinance screen (always months, with hint).
struct RefiTermField: View {
    let title: String
    @Binding var termMonths: Int

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 12)
            HStack(spacing: 4) {
                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
                    .onAppear { sync() }
                    .onChange(of: focused) { _, f in if !f { sync() } }
                    .onChange(of: text) { _, v in
                        let d = v.filter(\.isNumber)
                        if d != v { text = d }
                        termMonths = min(600, max(0, Int(d) ?? 0))
                    }
                    .onChange(of: termMonths) { _, _ in if !focused { sync() } }
                Text("mo")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(Fmt.termDescription(months: termMonths))
    }

    private func sync() {
        text = termMonths == 0 ? "" : String(termMonths)
    }
}
