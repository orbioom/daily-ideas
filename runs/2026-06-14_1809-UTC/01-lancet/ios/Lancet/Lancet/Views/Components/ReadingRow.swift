import SwiftUI

/// A single reading row: color-coded value, context, time, and carb/insulin badges.
struct ReadingRow: View {
    let reading: Reading
    @EnvironmentObject private var settings: AppSettings

    private var band: GlucoseBand { settings.band(for: reading.valueMgdl) }

    var body: some View {
        HStack(spacing: 14) {
            // Color-coded band indicator.
            Image(systemName: reading.context.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(band.color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(band.color.opacity(0.15)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    GlucoseValueLabel(mgdl: reading.valueMgdl, size: 19, showUnit: true)
                }
                HStack(spacing: 6) {
                    Text(reading.context.label)
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Text("·")
                        .foregroundStyle(Theme.inkFaint)
                    Text(reading.date.formatted(date: .omitted, time: .shortened))
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let carbs = reading.carbs, carbs > 0 {
                    badge("\(Int(carbs))g", "fork.knife")
                }
                if let insulin = reading.insulinUnits, insulin > 0 {
                    badge("\(formatUnits(insulin))U", "syringe")
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reading.context.label) reading")
        .accessibilityValue("\(settings.accessibilityValue(reading.valueMgdl)), \(band.rawValue), at \(reading.date.formatted(date: .omitted, time: .shortened))")
    }

    private func formatUnits(_ u: Double) -> String {
        u == u.rounded() ? String(Int(u)) : String(format: "%.1f", u)
    }

    private func badge(_ text: String, _ symbol: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 9, weight: .semibold))
            Text(text).font(Theme.rounded(11, .semibold))
        }
        .foregroundStyle(Theme.inkSoft)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(Theme.surfaceAlt))
        .accessibilityHidden(true)
    }
}
