import SwiftUI

/// A tasteful vinyl-disc motif: wax body, concentric grooves, and a tinted center label.
/// Purely decorative — hidden from accessibility.
struct VinylDisc: View {
    var labelHue: Double = 0.08
    /// 0…1 fraction of the diameter taken by the center label.
    var labelFraction: CGFloat = 0.42

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Wax body.
                Circle()
                    .fill(
                        RadialGradient(colors: [Theme.waxGroove, Theme.wax],
                                       center: .center,
                                       startRadius: size * 0.08,
                                       endRadius: size * 0.5)
                    )
                // Concentric grooves.
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.6)
                        .padding(size * (0.06 + CGFloat(i) * 0.05))
                }
                // Sheen sweep.
                Circle()
                    .fill(
                        LinearGradient(colors: [.white.opacity(0.10), .clear, .white.opacity(0.04)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                // Center label.
                Circle()
                    .fill(Theme.coverGradient(hue: labelHue))
                    .frame(width: size * labelFraction, height: size * labelFraction)
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.18), lineWidth: 1)
                    )
                // Spindle hole.
                Circle()
                    .fill(Theme.bg)
                    .frame(width: size * 0.045, height: size * 0.045)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
