import SwiftUI

/// Plain-language explanation of how Stub estimates pay, and its limits.
struct DisclaimerView: View {
    @Environment(\.colorScheme) private var scheme

    private struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let items: [Item] = [
        Item(icon: "building.columns",
             title: "Federal income tax",
             body: "Uses the 2025 progressive bracket schedule (10% to 37%) for your filing status, applied to wages after pre-tax deductions and the 2025 standard deduction."),
        Item(icon: "shield.lefthalf.filled",
             title: "FICA",
             body: "Social Security is 6.2% on wages up to the 2025 base of $176,100. Medicare is 1.45% on all wages, plus 0.9% additional Medicare above the filing-status threshold."),
        Item(icon: "map",
             title: "State income tax",
             body: "An approximate single flat effective rate per state, applied to taxable wages. Real states use progressive schedules, deductions, and credits — treat the state figure as a rough guide. Nine states have no wage income tax."),
        Item(icon: "minus.slash.plus",
             title: "Pre-tax deductions",
             body: "401(k) and ‘other pre-tax’ reduce income tax only. HSA and Section-125 health premiums reduce both income tax and FICA wages — the common payroll treatment."),
        Item(icon: "exclamationmark.triangle",
             title: "Estimate, not advice",
             body: "Stub does not account for credits, additional income, local taxes, or your exact W-4. It is a planning estimate, not tax advice. Confirm with a professional before making decisions.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(items) { item in
                    StubCard {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundStyle(StubTheme.green)
                                .frame(width: 30)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(StubTheme.primaryText(scheme))
                                Text(item.body)
                                    .font(.subheadline)
                                    .foregroundStyle(StubTheme.secondaryText(scheme))
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(16)
        }
        .background(StubTheme.appBackground(scheme).ignoresSafeArea())
        .navigationTitle("How estimates work")
        .navigationBarTitleDisplayMode(.inline)
    }
}
