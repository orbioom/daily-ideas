import SwiftUI

struct TimelineRow: View {
    let item: ItineraryItem
    let use24h: Bool
    let currencySymbol: String

    private var timeLabel: String {
        item.isTimed ? ItineraryEngine.timeLabel(minutes: item.startTimeMinutes, use24h: use24h) : "Anytime"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(spacing: 2) {
                Text(timeLabel)
                    .font(Theme.font(.caption, weight: .bold))
                    .foregroundStyle(item.isTimed ? Theme.textPrimary : Theme.textSecondary)
                    .multilineTextAlignment(.center)
                if item.isTimed && item.durationMin > 0 {
                    Text(ItineraryEngine.durationLabel(item.durationMin))
                        .font(Theme.font(.caption2))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 58)

            // Connector dot
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(item.category.tint).frame(width: 30, height: 30)
                    Image(systemName: item.category.symbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                Rectangle()
                    .fill(Theme.separator)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(Theme.font(.body, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if item.booked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                }
                if !item.address.isEmpty {
                    Label(item.address, systemImage: "mappin")
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text(item.category.label)
                        .font(Theme.font(.caption2, weight: .medium))
                        .foregroundStyle(item.category.tint)
                    if item.cost > 0 {
                        Text(BudgetEngine.currencyString(item.cost, symbol: currencySymbol))
                            .font(Theme.font(.caption2, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.bottom, 8)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Double tap to edit")
    }

    private var accessibilityText: String {
        var parts = ["\(timeLabel), \(item.title), \(item.category.label)"]
        if item.booked { parts.append("booked") }
        if !item.address.isEmpty { parts.append("at \(item.address)") }
        if item.cost > 0 { parts.append("costs \(BudgetEngine.currencyString(item.cost, symbol: currencySymbol))") }
        return parts.joined(separator: ", ")
    }
}
