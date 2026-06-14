import SwiftUI

/// A generated, image-free game cover: a deterministic gradient from the game's
/// coverHue, an SF Symbol watermark and the title initials. Respects cover style.
struct GameCover: View {
    let title: String
    let initials: String
    let hue: Double
    let style: CoverStyle
    var cornerRadius: CGFloat = Theme.cardCorner

    private var baseColor: Color {
        Color(hue: hue, saturation: 0.62, brightness: 0.78)
    }

    private var accentColor: Color {
        Color(hue: (hue + 0.12).truncatingRemainder(dividingBy: 1.0),
              saturation: 0.70, brightness: 0.62)
    }

    var body: some View {
        ZStack {
            background
            // Decorative controller watermark.
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.16))
                .rotationEffect(.degrees(-12))
                .offset(x: 26, y: 24)
                .accessibilityHidden(true)

            VStack {
                Spacer()
                Text(initials)
                    .font(Theme.rounded(34, .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                Spacer()
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
        // The initials already convey identity; expose the title to VoiceOver instead.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) cover")
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .gradient:
            LinearGradient(colors: [baseColor, accentColor],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .solid:
            baseColor
        }
    }
}
