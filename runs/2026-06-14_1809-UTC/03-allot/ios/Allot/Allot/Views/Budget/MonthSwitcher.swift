import SwiftUI

/// Prev / current-month-title / next control for the budget.
struct MonthSwitcher: View {
    @Binding var monthKey: String
    let hapticsEnabled: Bool

    var body: some View {
        HStack {
            stepButton(systemImage: "chevron.left", label: "Previous month") {
                monthKey = BudgetEngine.month(monthKey, offsetBy: -1)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(BudgetEngine.title(forMonthKey: monthKey))
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                if monthKey == BudgetEngine.currentMonthKey {
                    Text("This month")
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.accent)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Showing \(BudgetEngine.title(forMonthKey: monthKey))")
            Spacer()
            stepButton(systemImage: "chevron.right", label: "Next month") {
                monthKey = BudgetEngine.month(monthKey, offsetBy: 1)
            }
        }
        .padding(.horizontal, 6)
    }

    private func stepButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(hapticsEnabled)
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.surface))
                .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }
}
