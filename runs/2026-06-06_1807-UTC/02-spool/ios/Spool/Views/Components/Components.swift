import SwiftUI

/// A compact labeled metric tile.
struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
                .foregroundStyle(accent)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(11, weight: .medium)).tracking(1.0)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct Chip: View {
    let text: String
    var system: String? = nil
    var tint: Color = Brand.text2
    var body: some View {
        HStack(spacing: 4) {
            if let system { Image(systemName: system).font(.caption2).accessibilityHidden(true) }
            Text(text).font(Brand.mono(12, weight: .medium))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
    }
}

/// A round color swatch with a hairline ring (for filament colors).
struct ColorSwatch: View {
    let hex: String
    var size: CGFloat = 28
    var body: some View {
        Circle()
            .fill(Color(hexString: hex))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
            .accessibilityHidden(true)
    }
}

/// A horizontal remaining-fill bar with low/empty coloring.
struct RemainingBar: View {
    let fraction: Double
    var height: CGFloat = 8
    private var color: Color {
        if fraction <= 0.0 { return Brand.text3 }
        if fraction <= 0.12 { return Brand.danger }
        if fraction <= 0.30 { return Brand.warn }
        return Brand.live
    }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline)
                Capsule().fill(color)
                    .frame(width: max(height, geo.size.width * min(1, max(0, fraction))))
            }
        }
        .frame(height: height)
        .accessibilityLabel("\(Int((fraction * 100).rounded())) percent remaining")
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View { Eyebrow(text: title).padding(.horizontal, 4).padding(.top, 4) }
}
