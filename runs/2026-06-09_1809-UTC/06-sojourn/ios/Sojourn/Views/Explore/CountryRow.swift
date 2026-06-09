import SwiftUI

/// A status pill for a country's current visit status.
struct StatusChip: View {
    let status: VisitStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbol)
                .font(.system(size: 10, weight: .semibold))
                .accessibilityHidden(true)
            Text(status.label)
                .font(Brand.mono(11, weight: .medium))
        }
        .foregroundStyle(status.tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(status.tint.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.label)
    }
}

/// A single country list row: flag, name, capital, and current status (if any).
/// The flag is decorative; the accessibility label spells out name + status.
struct CountryRow: View {
    let country: Country
    let status: VisitStatus?
    var isFavorite: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flagEmoji)
                .font(.system(size: 30))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(country.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Brand.warn)
                            .accessibilityHidden(true)
                    }
                }
                Text(country.capital)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let status {
                StatusChip(status: status)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        var parts = [country.name]
        if let status { parts.append(status.label.lowercased()) }
        if isFavorite { parts.append("favorite") }
        parts.append("capital \(country.capital)")
        return parts.joined(separator: ", ")
    }
}
