import SwiftUI
import SwiftData

struct ScenarioDetailView: View {
    let scenario: LoanScenario
    @Binding var selection: RootView.Tab

    @Environment(CalculatorModel.self) private var calc
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    private var symbol: String { settings.currency.symbol }

    var body: some View {
        let s = scenario.summary
        ScrollView {
            VStack(spacing: 16) {
                header
                Card {
                    VStack(spacing: 12) {
                        HStack { SectionLabel(text: "Results"); Spacer() }
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            StatTile(caption: "Monthly payment",
                                     value: Fmt.money(s.monthlyPayment, symbol: symbol),
                                     tint: Theme.accent, symbol: "calendar")
                            StatTile(caption: "Total interest",
                                     value: Fmt.moneyWhole(s.totalInterest, symbol: symbol),
                                     tint: Theme.interestTint, symbol: "percent")
                            StatTile(caption: "Total paid",
                                     value: Fmt.moneyWhole(s.totalPaid, symbol: symbol),
                                     symbol: "sum")
                            StatTile(caption: "Payoff date",
                                     value: Fmt.monthYear(s.payoffDate),
                                     symbol: "flag.checkered")
                        }
                        if s.interestSaved > 0 || s.monthsSaved > 0 {
                            Divider().overlay(Theme.hairline)
                            InfoRow(label: "Interest saved by extra",
                                    value: Fmt.moneyWhole(s.interestSaved, symbol: symbol),
                                    valueTint: Theme.good)
                            InfoRow(label: "Time saved",
                                    value: Fmt.termDescription(months: s.monthsSaved),
                                    valueTint: Theme.good)
                        }
                    }
                }
                Card {
                    VStack(spacing: 10) {
                        HStack { SectionLabel(text: "Loan terms"); Spacer() }
                        InfoRow(label: "Loan type", value: scenario.loanType.label)
                        InfoRow(label: "Amount", value: Fmt.moneyWhole(scenario.principal, symbol: symbol))
                        InfoRow(label: "Rate", value: Fmt.percent(scenario.annualRatePct))
                        InfoRow(label: "Term", value: Fmt.termDescription(months: scenario.termMonths))
                        InfoRow(label: "First payment", value: Fmt.monthYear(scenario.startDate))
                        if scenario.extraMonthly > 0 {
                            InfoRow(label: "Extra monthly", value: Fmt.moneyWhole(scenario.extraMonthly, symbol: symbol))
                        }
                        if scenario.extraOneTime > 0 && scenario.extraOneTimeMonth > 0 {
                            InfoRow(label: "One-time extra",
                                    value: "\(Fmt.moneyWhole(scenario.extraOneTime, symbol: symbol)) at #\(scenario.extraOneTimeMonth)")
                        }
                    }
                }
                loadButton
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Theme.bg)
        .navigationTitle(scenario.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 54, height: 54)
                    Image(systemName: scenario.loanType.symbol)
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(scenario.name)
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Saved \(Fmt.monthYear(scenario.createdAt))")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer()
            }
        }
    }

    private var loadButton: some View {
        VStack(spacing: 8) {
            Button {
                calc.load(from: scenario)
                Haptics.tap(enabled: settings.hapticsEnabled)
                selection = .calculator
                dismiss()
            } label: {
                Label("Open in Calculator", systemImage: "function")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Color.white)
            }
            Text("Loads these inputs so you can tweak and re-save.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }
}
