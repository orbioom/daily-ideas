import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(accent)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label.uppercased()).font(Brand.mono(11, weight: .medium)).tracking(1.0)
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

/// A colored health pill (Strong / Watch / At risk).
struct HealthPill: View {
    let health: BeeLogic.Health
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(health.color).frame(width: 7, height: 7)
                .shadow(color: health.color.opacity(0.6), radius: 3)
            Text(health.rawValue).font(Brand.mono(11, weight: .semibold)).foregroundStyle(Brand.text)
        }
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
        .accessibilityLabel("Health: \(health.rawValue)")
    }
}

/// Queen marking dot with the standard color for a year.
struct QueenDot: View {
    let year: Int
    var size: CGFloat = 14
    var body: some View {
        Circle()
            .fill(Color(hex: BeeLogic.queenColorHex(year: year)))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
            .accessibilityLabel("Queen marked \(BeeLogic.queenColorName(year: year)) (\(year))")
    }
}

/// A 1–5 rating shown as filled segments.
struct RatingBar: View {
    let rating: Rating
    var tint: Color = Brand.text
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= rating.rawValue ? tint : Brand.hairline)
                    .frame(width: 14, height: 6)
            }
        }
        .accessibilityLabel("\(rating.label), \(rating.rawValue) of 5")
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View { Eyebrow(text: title).padding(.horizontal, 4).padding(.top, 4) }
}
