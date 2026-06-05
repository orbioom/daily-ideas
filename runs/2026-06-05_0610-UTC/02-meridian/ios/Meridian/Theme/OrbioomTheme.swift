import SwiftUI

/// Orbioom color tokens and Liquid-Glass surfaces, translated to iOS.
extension Color {
    static let orbInk   = Color(red: 0.106, green: 0.114, blue: 0.165)  // #1B1D2A
    static let orbText2 = Color(red: 0.337, green: 0.353, blue: 0.439)  // #565A70
    static let orbText3 = Color(red: 0.545, green: 0.561, blue: 0.639)  // #8B8FA3
    static let orbLive  = Color(red: 0.525, green: 0.780, blue: 0.604)  // #86C79A
    static let orbMist  = Color(red: 0.929, green: 0.933, blue: 0.953)  // #EDEEF3
    static let orbMist2 = Color(red: 0.906, green: 0.914, blue: 0.941)  // #E7E9F0
}

/// Fixed page-mist background gradient.
struct OrbMistBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.orbMist, .orbMist2, Color(red: 0.925, green: 0.933, blue: 0.949)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// `.ultraThinMaterial` glass card with an illuminated edge.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.157, green: 0.173, blue: 0.314).opacity(0.10),
                    radius: 18, x: 0, y: 12)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    /// JetBrains-Mono-style eyebrow label.
    func eyebrow() -> some View {
        self.font(.system(.caption2, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(Color.orbText3)
            .textCase(.uppercase)
    }
}
