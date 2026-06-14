import SwiftUI

/// A deterministic gradient "cover" for a title (the app ships no images).
/// Overlays the kind symbol and optional initials for a poster-like feel.
struct CoverView: View {
    let hue: Double
    let kind: AnimeMediaKind
    var initials: String? = nil
    var intensity: AccentIntensity = .standard
    var cornerRadius: CGFloat = 16

    private var gradient: LinearGradient {
        let h = min(max(hue, 0), 1)
        let s1 = min(0.62 * intensity.saturationScale, 1)
        let s2 = min(0.80 * intensity.saturationScale, 1)
        let c1 = Color(hue: h, saturation: s1, brightness: 0.82)
        let c2 = Color(hue: (h + 0.12).truncatingRemainder(dividingBy: 1.0),
                       saturation: s2, brightness: 0.52)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(gradient)
            // Subtle diagonal sheen for depth.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(colors: [.white.opacity(0.18), .clear],
                                   startPoint: .top, endPoint: .center)
                )
            if let initials, !initials.isEmpty {
                Text(initials)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            } else {
                Image(systemName: kind.symbol)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .accessibilityHidden(true)
    }
}

extension String {
    /// Up to two uppercase initials from the first words.
    var coverInitials: String {
        let words = split(separator: " ").prefix(2)
        let chars = words.compactMap { $0.first }
        return String(chars).uppercased()
    }
}
