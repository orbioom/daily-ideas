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

/// A visual board: proportional segments for each placed piece plus the waste.
struct BoardBar: View {
    let layout: CutOptimizer.BoardLayout
    let unit: LengthUnit
    private let palette: [Color] = [
        Color(hex: 0x3A3E4C), Color(hex: 0x55617A), Color(hex: 0x6E5A47),
        Color(hex: 0x4E6BA8), Color(hex: 0x6B7A55)
    ]

    var body: some View {
        GeometryReader { geo in
            let total = max(1, layout.stockLength)
            HStack(spacing: 0) {
                ForEach(Array(layout.pieces.enumerated()), id: \.element.id) { idx, piece in
                    let w = geo.size.width * piece.length / total
                    Rectangle()
                        .fill(palette[idx % palette.count])
                        .frame(width: max(2, w))
                        .overlay(
                            Text(unit.string(piece.length, withUnit: false))
                                .font(Brand.mono(9, weight: .medium)).foregroundStyle(.white)
                                .lineLimit(1).minimumScaleFactor(0.5).padding(.horizontal, 2)
                                .opacity(w > 28 ? 1 : 0)
                        )
                        .overlay(Rectangle().frame(width: 1).foregroundStyle(.black.opacity(0.25)), alignment: .trailing)
                }
                if layout.waste > 0 {
                    let w = geo.size.width * layout.waste / total
                    ZStack {
                        Rectangle().fill(Brand.hairline)
                        Rectangle().stroke(Brand.text3.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                    .frame(width: max(0, w))
                }
            }
        }
        .frame(height: 30)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
        .accessibilityElement()
        .accessibilityLabel("Board \(unit.string(layout.stockLength)), \(layout.pieces.count) pieces, waste \(unit.string(layout.waste))")
    }
}
