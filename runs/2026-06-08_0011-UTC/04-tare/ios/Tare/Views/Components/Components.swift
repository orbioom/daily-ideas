import SwiftUI

struct StatTile: View {
    var value: String
    var label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Brand.mono(20, weight: .semibold))
                .foregroundStyle(tint).monospacedDigit()
                .minimumScaleFactor(0.5).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Tiny inline sparkline of trend values.
struct Sparkline: View {
    var values: [Double]
    var tint: Color = Brand.info
    var body: some View {
        GeometryReader { geo in
            if values.count >= 2, let lo = values.min(), let hi = values.max() {
                let range = max(0.0001, hi - lo)
                Path { p in
                    for (i, v) in values.enumerated() {
                        let x = geo.size.width * CGFloat(i) / CGFloat(values.count - 1)
                        let y = geo.size.height * (1 - CGFloat((v - lo) / range))
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityHidden(true)
    }
}
