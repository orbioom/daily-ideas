import SwiftUI

/// A static decorative ring glyph (used in onboarding / empty states). Draws a partial
/// arc with a soft accent. Purely decorative — callers hide it from accessibility.
struct RingGlyph: View {
    var progress: Double
    var lineWidth: CGFloat = 6
    var tint: Color = Brand.live

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.text3.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

/// The live countdown ring on the run screen. Honors Reduce Motion: when reduced, the
/// ring updates by fading its trim rather than animating a sweeping rotation.
struct CountdownRing: View {
    /// 0...1 progress consumed in the current step.
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 14
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.text3.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, 1 - progress)))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? .easeInOut(duration: 0.3) : .linear(duration: 0.1),
                           value: progress)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 40) {
        RingGlyph(progress: 0.7).frame(width: 80, height: 80)
        CountdownRing(progress: 0.35, tint: Brand.live, reduceMotion: false)
            .frame(width: 200, height: 200)
    }
    .padding()
    .background(Brand.pageBackground)
}
