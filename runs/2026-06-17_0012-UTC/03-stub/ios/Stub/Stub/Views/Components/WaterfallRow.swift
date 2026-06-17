import SwiftUI

/// A single labeled row in the breakdown waterfall, with an optional bar that
/// shows the amount relative to gross. Negative items render as deductions.
struct WaterfallRow: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let amount: Decimal
    let total: Decimal       // reference for bar width (usually annual gross)
    var color: Color = StubTheme.green
    var isDeduction: Bool = false
    var emphasized: Bool = false
    let roundWhole: Bool

    private var fraction: Double {
        guard total > 0 else { return 0 }
        let f = (amount / total).doubleValue
        return min(max(f, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(emphasized ? .subheadline.weight(.semibold) : .subheadline)
                    .foregroundStyle(StubTheme.primaryText(scheme))
                Spacer()
                Text((isDeduction ? "−" : "") + Format.currency(amount, whole: roundWhole))
                    .font(StubTheme.figureFont(emphasized ? .subheadline : .footnote,
                                               weight: emphasized ? .bold : .medium))
                    .foregroundStyle(isDeduction ? StubTheme.federal : StubTheme.primaryText(scheme))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(StubTheme.subtleSurface(scheme))
                    Capsule()
                        .fill(color)
                        .frame(width: max(3, geo.size.width * fraction))
                }
            }
            .frame(height: 7)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(isDeduction ? "minus " : "")\(Format.currencySpoken(amount, whole: roundWhole))")
    }
}

/// A compact key/value stat tile.
struct StatTile: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let value: String
    var accent: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(StubTheme.secondaryText(scheme))
            Text(value)
                .font(StubTheme.figureFont(.title3, weight: .bold))
                .foregroundStyle(accent ?? StubTheme.primaryText(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(StubTheme.subtleSurface(scheme))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
