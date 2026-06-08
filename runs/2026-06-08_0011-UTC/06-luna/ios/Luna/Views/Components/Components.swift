import SwiftUI

enum LunaColors {
    static let period = Color(hex: 0xB5556F)
    static let predicted = Color(hex: 0xC79AB0)
    static let fertile = Color(hex: 0x4FB98C)
    static let ovulation = Color(hex: 0x2C8C7C)
    static let luteal = Color(hex: 0x7A5EA8)

    static func phase(_ p: CyclePredictor.Phase) -> Color {
        switch p {
        case .menstrual: return period
        case .follicular: return Color(hex: 0x6FB97E)
        case .fertile: return fertile
        case .ovulation: return ovulation
        case .luteal: return luteal
        case .unknown: return Brand.text3
        }
    }
}

/// Big ring on the Today screen showing progress through the current cycle.
struct CycleRing: View {
    var cycleDay: Int
    var cycleLength: Int
    var phaseColor: Color
    var centerTop: String
    var centerBig: String
    var centerBottom: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        guard cycleLength > 0 else { return 0 }
        return min(1, max(0, Double(cycleDay) / Double(cycleLength)))
    }

    var body: some View {
        ZStack {
            Circle().stroke(Brand.hairline, lineWidth: 16)
            Circle().trim(from: 0, to: max(0.001, progress))
                .stroke(AngularGradient(colors: [phaseColor.opacity(0.6), phaseColor], center: .center),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.6), value: progress)
            VStack(spacing: 6) {
                Text(centerTop).font(Brand.mono(12, weight: .medium)).tracking(1.2).foregroundStyle(Brand.text3)
                Text(centerBig).font(Brand.mono(38, weight: .semibold)).foregroundStyle(Brand.text)
                Text(centerBottom).font(.subheadline).foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            .padding(36)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(centerTop) \(centerBig). \(centerBottom)")
    }
}

struct FlowDots: View {
    var flow: Flow
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...4, id: \.self) { i in
                Circle()
                    .fill(i <= flow.dots ? flow.color : Brand.hairline)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Flow: \(flow.label)")
    }
}

struct StatTile: View {
    var value: String
    var label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(tint)
                .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
