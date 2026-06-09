import SwiftUI

/// A circular progress ring with a soft track and a gradient fill.
struct ProgressRing: View {
    var progress: Double          // 0…1
    var lineWidth: CGFloat = 14
    var tint: Color = Brand.live
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(progress, 1)))
                .stroke(
                    LinearGradient(colors: [tint.opacity(0.6), tint],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.4), value: progress)
        }
        .accessibilityHidden(true)
    }
}

/// A compact glass stat tile: a big mono value over a label.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.5)
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

/// A horizontal budget bar: spent vs budget. Turns to Brand.danger over budget.
struct BudgetBar: View {
    let fraction: Double      // 0…1
    let overBudget: Bool
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Brand.hairline)
                Capsule()
                    .fill(overBudget ? Brand.danger : Brand.live)
                    .frame(width: max(0, min(fraction, 1)) * geo.size.width)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A small rounded tag pill (status, relation, etc.).
struct TagPill: View {
    let text: String
    var symbol: String? = nil
    var color: Color = Brand.text2

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(Brand.mono(11, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}

extension GiftStatus {
    /// The accent color used for this status across the app.
    var color: Color {
        switch self {
        case .idea:    return Brand.info
        case .bought:  return Brand.warn
        case .wrapped: return Brand.magic
        case .given:   return Brand.live
        }
    }
}
