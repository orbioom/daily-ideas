import SwiftUI

/// The month-by-month amortization schedule for the current plan.
struct ScheduleView: View {
    let result: PayoffEngine.Result
    let currency: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                Divider().overlay(Brand.hairline)
                if result.months.isEmpty {
                    EmptyStateView(icon: "calendar", title: "No schedule",
                                   message: "Add a plan with debts to generate a schedule.")
                } else {
                    ForEach(result.months) { row in
                        monthRow(row)
                        Divider().overlay(Brand.hairline.opacity(0.5))
                    }
                }
            }
            .padding(16)
            .glassCard()
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerRow: some View {
        HStack {
            Text("MONTH").frame(width: 70, alignment: .leading)
            Spacer()
            Text("PAID").frame(width: 80, alignment: .trailing)
            Text("INTEREST").frame(width: 80, alignment: .trailing)
            Text("BALANCE").frame(width: 86, alignment: .trailing)
        }
        .font(Brand.mono(10, weight: .medium)).tracking(0.8).foregroundStyle(Brand.text3)
        .padding(.bottom, 6)
    }

    private func monthRow(_ row: PayoffEngine.MonthRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("#\(row.index)").font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
                Text(row.date.formatted(.dateTime.month(.abbreviated).year(.twoDigits)))
                    .font(Brand.mono(10)).foregroundStyle(Brand.text3)
            }
            .frame(width: 70, alignment: .leading)
            Spacer()
            Text(Money.string(row.payment, code: currency)).frame(width: 80, alignment: .trailing)
                .font(Brand.mono(12)).foregroundStyle(Brand.text2)
            Text(Money.string(row.interest, code: currency)).frame(width: 80, alignment: .trailing)
                .font(Brand.mono(12)).foregroundStyle(Brand.warn)
            Text(Money.string(row.endingBalance, code: currency)).frame(width: 86, alignment: .trailing)
                .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text)
        }
        .padding(.vertical, 7)
    }
}
