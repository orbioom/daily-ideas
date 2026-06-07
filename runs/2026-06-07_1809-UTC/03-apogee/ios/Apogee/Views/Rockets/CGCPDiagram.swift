import SwiftUI

/// A small schematic of the rocket body (nose on the left, tail on the right)
/// with the CG and CP marked at their positions along the length. The gap
/// between them is the stability margin. Purely informational.
struct CGCPDiagram: View {
    let lengthMm: Double
    let cgFromNoseMm: Double
    let cpFromNoseMm: Double
    let statusColor: Color

    private func fraction(_ mm: Double) -> Double {
        guard lengthMm > 0 else { return 0 }
        return min(1, max(0, mm / lengthMm))
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let cgX = fraction(cgFromNoseMm) * w
                let cpX = fraction(cpFromNoseMm) * w

                ZStack(alignment: .leading) {
                    // Body tube with a tapered nose hint.
                    Capsule()
                        .fill(Brand.text3.opacity(0.18))
                        .frame(height: 16)
                        .overlay(
                            Capsule().strokeBorder(Brand.hairline, lineWidth: 1)
                        )

                    // CP marker (the higher it sits behind CG, the more stable).
                    marker(at: cpX, color: Brand.info, glyph: "CP", up: true)
                    // CG marker.
                    marker(at: cgX, color: statusColor, glyph: "CG", up: false)
                }
                .frame(height: 56)
            }
            .frame(height: 56)

            HStack {
                Label("CP", systemImage: "circle.fill")
                    .foregroundStyle(Brand.info)
                Spacer()
                Text("Nose").foregroundStyle(Brand.text3)
                Spacer()
                Label("CG", systemImage: "circle.fill")
                    .foregroundStyle(statusColor)
            }
            .font(Brand.mono(10, weight: .medium))
            .labelStyle(.titleAndIcon)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Balance diagram. CG at \(Format.mm(cgFromNoseMm)) from nose, CP at \(Format.mm(cpFromNoseMm)) from nose.")
    }

    @ViewBuilder
    private func marker(at x: CGFloat, color: Color, glyph: String, up: Bool) -> some View {
        VStack(spacing: 2) {
            if up {
                Text(glyph).font(Brand.mono(9, weight: .bold)).foregroundStyle(color)
                pin(color)
            } else {
                pin(color)
                Text(glyph).font(Brand.mono(9, weight: .bold)).foregroundStyle(color)
            }
        }
        .frame(width: 28)
        .position(x: x, y: 28)
    }

    private func pin(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1))
    }
}
