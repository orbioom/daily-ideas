import SwiftUI

/// The signature visual: a soft bottle-shaped gradient tinted by the fragrance's
/// dominant note family, with a juice-color glow driven by `colorHue`.
struct JuiceSwatch: View {
    let family: NoteFamily
    /// 0...1 juice color used to tint the liquid glow.
    let colorHue: Double
    var size: CGFloat = 120

    private var juiceColor: Color {
        // Map 0...1 to a warm-amber-through-spectrum hue for the "juice".
        Color(hue: colorHue, saturation: 0.5, brightness: 0.82)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(
                    LinearGradient(colors: [family.hue, family.hueDeep],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            // Juice glow puddled at the base.
            Ellipse()
                .fill(juiceColor.opacity(0.55))
                .frame(width: size * 0.7, height: size * 0.45)
                .blur(radius: size * 0.12)
                .offset(y: size * 0.22)
            // Bottle silhouette.
            Image(systemName: "drop.fill")
                .font(.system(size: size * 0.34, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            // Family glyph badge.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: family.symbol)
                        .font(.system(size: size * 0.16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(size * 0.1)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}
