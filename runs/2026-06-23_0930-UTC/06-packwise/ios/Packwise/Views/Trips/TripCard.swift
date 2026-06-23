import SwiftUI

/// A trip summary card used on the Trips list.
struct TripCard: View {
    let trip: Trip

    private var countdownText: String {
        if trip.isPast { return "Completed" }
        let days = trip.daysUntilDeparture
        if days < 0 { return "In progress" }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "In \(days) days"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack(alignment: .top, spacing: Theme.Space.md) {
                IconBadge(symbol: trip.tripType.symbol, tint: trip.tripType.tint, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.name)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Label(trip.destination, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                ProgressRing(progress: trip.progress, lineWidth: 6, size: 48,
                             tint: trip.isComplete ? Theme.success : Theme.primary)
            }

            HStack(spacing: Theme.Space.sm) {
                tag(trip.tripType.title, color: trip.tripType.tint)
                tag(countdownText, color: Theme.primary)
                Spacer()
                Text("\(trip.packedCount)/\(trip.totalCount) packed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
            }
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(trip.name), \(trip.destination)")
        .accessibilityValue("\(trip.tripType.title), \(countdownText), \(trip.packedCount) of \(trip.totalCount) items packed")
        .accessibilityHint("Opens the packing list")
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, Theme.Space.sm)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
