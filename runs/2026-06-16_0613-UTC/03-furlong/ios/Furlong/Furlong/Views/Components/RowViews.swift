import SwiftUI

struct TripRow: View {
    @EnvironmentObject private var settings: AppSettings
    let trip: Trip

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(trip.purpose.tint.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: trip.purpose.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(trip.purpose.tint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(trip.routeLabel)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(DateFormatting.medium.string(from: trip.date))
                    if trip.roundTrip {
                        Text("• round trip")
                    }
                }
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(settings.distance(trip.effectiveMiles))
                    .font(Theme.mono(15, .semibold))
                    .foregroundStyle(Theme.ink)
                TagPill(text: trip.purpose.rawValue,
                        symbol: trip.purpose.symbol,
                        tint: trip.purpose.tint)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(trip.purpose.rawValue) trip, \(trip.routeLabel)")
        .accessibilityValue("\(settings.distance(trip.effectiveMiles)) on \(DateFormatting.medium.string(from: trip.date))")
    }
}

struct ExpenseRow: View {
    @EnvironmentObject private var settings: AppSettings
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(expense.category.tint.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: expense.category.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(expense.category.tint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.displayCategory)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(DateFormatting.medium.string(from: expense.date))
                    if !expense.deductible {
                        Text("• not deductible")
                    }
                }
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(settings.money(expense.amount))
                .font(Theme.mono(15, .semibold))
                .foregroundStyle(expense.deductible ? Theme.ink : Theme.inkSoft)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(expense.displayCategory) expense")
        .accessibilityValue("\(settings.money(expense.amount)) on \(DateFormatting.medium.string(from: expense.date))\(expense.deductible ? "" : ", not deductible")")
    }
}
