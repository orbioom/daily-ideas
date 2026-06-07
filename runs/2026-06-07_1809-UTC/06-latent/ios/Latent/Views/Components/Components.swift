import SwiftUI

/// A compact metric tile: a big mono value over a quiet label.
struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Brand.mono(24, weight: .semibold))
                .foregroundStyle(accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(10, weight: .medium))
                .tracking(1.0)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A quiet section title used above grouped content.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Brand.text2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A horizontal labelled row (label left, value right).
struct InfoRow: View {
    let label: String
    let value: String
    var mono: Bool = false
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(mono ? Brand.mono(15, weight: .medium) : .body.weight(.medium))
                .foregroundStyle(Brand.text)
        }
        .font(.subheadline)
    }
}

/// A coloured pill badge.
struct Badge: View {
    let text: String
    var color: Color = Brand.text2
    var body: some View {
        Text(text)
            .font(Brand.mono(11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }
}

/// A horizontal labelled progress bar.
struct MeterBar: View {
    var fraction: Double
    var color: Color = Brand.live
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline).frame(height: height)
                Capsule().fill(color)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width, height: height)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
