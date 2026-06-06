import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(Brand.mono(19, weight: .semibold)).foregroundStyle(tint)
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(label.uppercased()).font(Brand.mono(10, weight: .medium)).tracking(1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
    }
}

struct Pill: View {
    let text: String
    var tint: Color = Brand.text2
    var body: some View {
        Text(text).font(.caption.weight(.semibold)).foregroundStyle(tint)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 1))
    }
}

/// Renders a span of months as a friendly "2 yr 3 mo".
enum MonthSpan {
    static func describe(months: Int) -> String {
        guard months > 0 else { return "—" }
        let y = months / 12, m = months % 12
        switch (y, m) {
        case (0, _): return "\(m) mo"
        case (_, 0): return "\(y) yr"
        default: return "\(y) yr \(m) mo"
        }
    }
}
