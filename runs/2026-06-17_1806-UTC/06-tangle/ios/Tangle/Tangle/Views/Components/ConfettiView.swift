import SwiftUI

/// Gentle falling confetti shown on level completion.
/// Honors Reduce Motion: when enabled it shows a single static celebratory
/// burst instead of an animated fall.
struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var active: Bool

    private let palette: [Color] = [
        Theme.accent, Theme.star, Theme.accentDeep, Color(hex: 0xF08A6E), Color(hex: 0x6EC6F0)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<28, id: \.self) { i in
                    ConfettiPiece(
                        index: i,
                        size: geo.size,
                        color: palette[i % palette.count],
                        active: active,
                        reduceMotion: reduceMotion
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ConfettiPiece: View {
    let index: Int
    let size: CGSize
    let color: Color
    let active: Bool
    let reduceMotion: Bool

    @State private var fall = false

    private var startX: CGFloat {
        guard size.width > 0 else { return 0 }
        let frac = CGFloat((index * 37) % 100) / 100
        return frac * size.width
    }
    private var drift: CGFloat { CGFloat(((index * 53) % 60) - 30) }
    private var delay: Double { Double(index % 10) * 0.06 }
    private var spin: Double { Double((index % 4) + 1) * 180 }

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: 8, height: 12)
            .position(
                x: startX + (reduceMotion ? 0 : (fall ? drift : 0)),
                y: reduceMotion ? size.height * 0.32 : (fall ? size.height + 20 : -20)
            )
            .rotationEffect(.degrees(reduceMotion ? 0 : (fall ? spin : 0)))
            .opacity(active ? (reduceMotion ? 0.9 : 1) : 0)
            .onChange(of: active) { _, isActive in
                guard !reduceMotion else { return }
                if isActive {
                    fall = false
                    withAnimation(.easeIn(duration: 2.2).delay(delay)) {
                        fall = true
                    }
                } else {
                    fall = false
                }
            }
    }
}
