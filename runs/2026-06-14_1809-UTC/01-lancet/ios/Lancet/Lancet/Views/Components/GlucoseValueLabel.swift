import SwiftUI

/// A color-coded glucose value rendered in the user's chosen unit.
/// Used in lists, the logbook grid, and detail rows. Color comes from the band.
struct GlucoseValueLabel: View {
    let mgdl: Double
    var size: CGFloat = 17
    var showUnit: Bool = false
    @EnvironmentObject private var settings: AppSettings

    private var band: GlucoseBand { settings.band(for: mgdl) }

    var body: some View {
        HStack(spacing: 4) {
            Text(settings.formatValue(mgdl))
                .font(Theme.rounded(size, .bold))
                .foregroundStyle(band.color)
                .monospacedDigit()
            if showUnit {
                Text(settings.unit.label)
                    .font(Theme.rounded(size * 0.62, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Glucose")
        .accessibilityValue("\(settings.accessibilityValue(mgdl)), \(band.rawValue)")
    }
}

/// A small filled pill showing band + value, for grid cells.
struct GlucoseChip: View {
    let mgdl: Double
    @EnvironmentObject private var settings: AppSettings

    private var band: GlucoseBand { settings.band(for: mgdl) }

    var body: some View {
        Text(settings.formatValue(mgdl))
            .font(Theme.rounded(14, .bold))
            .monospacedDigit()
            .foregroundStyle(band.color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(band.color.opacity(0.16))
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Glucose")
            .accessibilityValue("\(settings.accessibilityValue(mgdl)), \(band.rawValue)")
    }
}
