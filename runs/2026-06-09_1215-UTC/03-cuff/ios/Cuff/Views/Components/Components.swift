import SwiftUI

/// A compact glass stat tile: a big mono value over a label.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Brand.mono(24, weight: .semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(11, weight: .medium))
                .tracking(1.1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A small section title used above grouped content.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Brand.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A colored capsule labeling an AHA blood-pressure stage.
struct BPCategoryBadge: View {
    let category: BPCategory
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: category.color)
            Text(category.label)
                .font(compact ? Brand.mono(12, weight: .semibold) : Brand.mono(13, weight: .semibold))
                .foregroundStyle(category.color)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(category.color.opacity(0.14),
                    in: Capsule(style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Category \(category.label)")
    }
}

/// A small up/down/flat trend chip with a signed delta.
struct TrendChip: View {
    let trend: VitalsEngine.Trend
    var unit: String = ""
    var lowerIsBetter: Bool = true

    private var symbol: String {
        switch trend.direction {
        case .up:   return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }

    private var color: Color {
        switch trend.direction {
        case .flat: return Brand.text3
        case .up:   return lowerIsBetter ? Brand.warn : Brand.live
        case .down: return lowerIsBetter ? Brand.live : Brand.warn
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.caption2.weight(.bold))
            Text(Format.signed(trend.delta, decimals: abs(trend.delta) < 10 ? 1 : 0) + unit)
                .font(Brand.mono(12, weight: .medium))
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trend \(trend.direction == .up ? "up" : trend.direction == .down ? "down" : "flat"), \(Format.signed(trend.delta, decimals: 1))\(unit)")
    }
}
