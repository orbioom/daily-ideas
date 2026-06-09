import SwiftUI

/// A circular progress ring with a soft track and a gradient fill.
struct ProgressRing: View {
    var progress: Double          // 0…1
    var lineWidth: CGFloat = 14
    var tint: Color = Brand.magic
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: lineWidth)
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

/// A rounded chip used for category / difficulty tags.
struct TagChip: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = Brand.text2

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(Brand.mono(11, weight: .medium))
                .tracking(0.6)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

/// A row of 1…5 selectable circles for rating how a session felt.
struct FeelingPicker: View {
    @Binding var feeling: Int
    var activeTint: Color = Brand.live
    var inactiveTint: Color = .white.opacity(0.4)

    var body: some View {
        HStack(spacing: 14) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    Haptics.selection()
                    feeling = (feeling == i) ? 0 : i
                } label: {
                    Image(systemName: feeling >= i ? "circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(feeling >= i ? activeTint : inactiveTint)
                }
                .accessibilityLabel("Rate \(i) of 5")
                .accessibilityAddTraits(feeling == i ? [.isSelected] : [])
            }
        }
    }
}
