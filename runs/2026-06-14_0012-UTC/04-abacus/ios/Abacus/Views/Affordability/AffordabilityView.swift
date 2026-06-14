import SwiftUI

struct AffordabilityView: View {
    @Environment(AppSettings.self) private var settings

    @State private var monthlyBudget: Double = 2_000
    @State private var annualRatePct: Double = 6.25
    @State private var termMonths: Int = 360

    private var symbol: String { settings.currency.symbol }

    private var isValid: Bool {
        monthlyBudget > 0 && annualRatePct >= 0 && annualRatePct <= 40 && termMonths >= 1 && termMonths <= 600
    }

    private var maxPrincipal: Double {
        LoanMath.maxPrincipal(monthlyBudget: monthlyBudget, annualRatePct: annualRatePct, termMonths: termMonths)
    }

    private var totalPaid: Double { monthlyBudget * Double(termMonths) }
    private var totalInterest: Double { max(0, totalPaid - maxPrincipal) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero
                    inputs
                    if isValid {
                        breakdown
                        donut
                    } else {
                        hint
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Theme.bg)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Affordability")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var hero: some View {
        Card {
            VStack(spacing: 6) {
                Text("You can borrow about")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkFaint)
                Text(isValid ? Fmt.moneyWhole(maxPrincipal, symbol: symbol) : "—")
                    .font(Theme.rounded(42, .bold))
                    .foregroundStyle(isValid ? Theme.ink : Theme.inkFaint)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: maxPrincipal)
                Text("for \(Fmt.moneyWhole(monthlyBudget, symbol: symbol))/mo over \(Fmt.termDescription(months: termMonths))")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Estimated borrowing power")
            .accessibilityValue(isValid ? Fmt.moneyWhole(maxPrincipal, symbol: symbol) : "enter a budget")
        }
    }

    private var inputs: some View {
        Card {
            VStack(spacing: 12) {
                HStack { SectionLabel(text: "Your budget"); Spacer() }
                CurrencyField(title: "Monthly budget", symbol: symbol, value: $monthlyBudget,
                              accessibilityHint: "The most you can pay per month.")
                PercentField(title: "Interest rate", value: $annualRatePct)
                AffordTermField(termMonths: $termMonths)
            }
        }
    }

    private var breakdown: some View {
        Card {
            VStack(spacing: 10) {
                HStack { SectionLabel(text: "Over the full term"); Spacer() }
                InfoRow(label: "Max loan amount", value: Fmt.moneyWhole(maxPrincipal, symbol: symbol), valueTint: Theme.accent)
                InfoRow(label: "Total you'd pay", value: Fmt.moneyWhole(totalPaid, symbol: symbol))
                InfoRow(label: "Of which interest", value: Fmt.moneyWhole(totalInterest, symbol: symbol), valueTint: Theme.interestTint)
            }
        }
    }

    private var donut: some View {
        Card {
            VStack(spacing: 12) {
                HStack { SectionLabel(text: "Principal vs interest"); Spacer() }
                PrincipalInterestDonut(principal: maxPrincipal, interest: totalInterest, symbol: symbol)
                DonutLegend(principal: maxPrincipal, interest: totalInterest, symbol: symbol)
            }
        }
    }

    private var hint: some View {
        Card {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Enter a monthly budget, a rate between 0–40%, and a term of 1–600 months.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Standalone term field for the affordability screen (respects unit setting).
struct AffordTermField: View {
    @Binding var termMonths: Int
    @Environment(AppSettings.self) private var settings

    @State private var text: String = ""
    @FocusState private var focused: Bool
    private var unit: TermUnit { settings.termUnit }

    var body: some View {
        HStack(spacing: 10) {
            Text("Term")
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
                        let n = Int(d) ?? 0
                        termMonths = unit == .years ? min(600, max(0, n * 12)) : min(600, max(0, n))
                    }
                    .onChange(of: settings.termUnitRaw) { _, _ in sync() }
                Text(unit == .years ? "yr" : "mo")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Term")
        .accessibilityValue(Fmt.termDescription(months: termMonths))
    }

    private func sync() {
        if unit == .years {
            let y = Int((Double(termMonths) / 12.0).rounded())
            text = y == 0 ? "" : String(y)
        } else {
            text = termMonths == 0 ? "" : String(termMonths)
        }
    }
}
