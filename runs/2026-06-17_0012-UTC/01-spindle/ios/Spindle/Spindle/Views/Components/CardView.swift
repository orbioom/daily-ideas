import SwiftUI

/// Renders a single playing card — cream face with crisp rank + pips, or a
/// patterned back when face-down. Sized by `width`; height follows a fixed ratio.
struct CardView: View {
    let card: Card
    var width: CGFloat
    var selected: Bool = false
    var hinted: Bool = false
    var backStyle: CardBackStyle = .lattice

    private var height: CGFloat { width * 1.44 }
    private var corner: CGFloat { width * 0.13 }

    private let faceColor = Color(red: 0xFB / 255.0, green: 0xF7 / 255.0, blue: 0xEC / 255.0)

    var body: some View {
        ZStack {
            if card.faceUp {
                faceBody
            } else {
                CardBackView(backStyle: backStyle, width: width)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(borderColor, lineWidth: selected || hinted ? 2.4 : 0.8)
        )
        .shadow(color: .black.opacity(0.22), radius: 2, x: 0, y: 1)
    }

    private var borderColor: Color {
        if selected { return SpindleTheme.gold }
        if hinted { return SpindleTheme.emerald }
        return Color.black.opacity(0.18)
    }

    private var ink: Color {
        card.suit.isRed
            ? Color(red: 0xC0 / 255.0, green: 0x2A / 255.0, blue: 0x33 / 255.0)
            : Color(red: 0x1B / 255.0, green: 0x20 / 255.0, blue: 0x26 / 255.0)
    }

    private var faceBody: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(selected ? SpindleTheme.gold.opacity(0.18) : faceColor)
            .overlay(alignment: .topLeading) {
                cornerIndex
                    .padding(.leading, width * 0.10)
                    .padding(.top, width * 0.07)
            }
            .overlay(alignment: .bottomTrailing) {
                cornerIndex
                    .rotationEffect(.degrees(180))
                    .padding(.trailing, width * 0.10)
                    .padding(.bottom, width * 0.07)
            }
            .overlay {
                // Central large pip for visual identity.
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.42))
                    .foregroundStyle(ink.opacity(0.28))
                    .accessibilityHidden(true)
            }
    }

    private var cornerIndex: some View {
        VStack(spacing: -width * 0.02) {
            Text(card.rankLabel)
                .font(.system(size: width * 0.32, weight: .bold, design: .rounded))
            Text(card.suit.symbol)
                .font(.system(size: width * 0.26))
        }
        .foregroundStyle(ink)
        .accessibilityHidden(true)
    }
}

/// The patterned back of a face-down card.
struct CardBackView: View {
    var backStyle: CardBackStyle = .lattice
    var width: CGFloat

    private var corner: CGFloat { width * 0.13 }

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [SpindleTheme.emerald, SpindleTheme.emeraldDeep],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .overlay { pattern.foregroundStyle(Color.white.opacity(0.18)) }
            .overlay(
                RoundedRectangle(cornerRadius: corner * 0.7, style: .continuous)
                    .inset(by: width * 0.08)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
            )
    }

    @ViewBuilder private var pattern: some View {
        switch backStyle {
        case .lattice:
            LatticePattern()
        case .waves:
            WavesPattern()
        case .solid:
            Color.clear
        }
    }
}

private struct LatticePattern: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step = max(6, geo.size.width / 5)
                var x = -geo.size.height
                while x < geo.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + geo.size.height, y: geo.size.height))
                    x += step
                }
                var y = -geo.size.width
                while y < geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y + geo.size.width))
                    y += step
                }
            }
            .stroke(lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

private struct WavesPattern: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let rows = 6
                let h = geo.size.height / CGFloat(rows)
                for r in 0...rows {
                    let y = CGFloat(r) * h
                    path.move(to: CGPoint(x: 0, y: y))
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.addQuadCurve(
                            to: CGPoint(x: x + h, y: y),
                            control: CGPoint(x: x + h / 2, y: y - h / 2)
                        )
                        x += h
                    }
                }
            }
            .stroke(lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}
