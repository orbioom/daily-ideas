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

/// A horizontal accuracy bar with a label and a percentage.
struct MasteryBar: View {
    let title: String
    let accuracy: Double      // 0…1
    let attempts: Int

    private var tint: Color {
        if accuracy >= 0.85 { return Brand.live }
        if accuracy >= 0.6 { return Brand.magic }
        if accuracy >= 0.4 { return Brand.warn }
        return Brand.danger
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(Format.percent(accuracy)) · \(attempts)")
                    .font(Brand.mono(13)).foregroundStyle(Brand.text2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.hairline)
                    Capsule().fill(tint.opacity(0.85))
                        .frame(width: max(2, geo.size.width * CGFloat(min(max(accuracy, 0), 1))))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(Format.percent(accuracy)) over \(attempts) attempts")
    }
}
