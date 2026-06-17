import SwiftUI

/// A row of dots representing beats in the measure. The active beat fills.
/// With Reduce Motion the active dot fills discretely (no scaling pulse).
struct BeatIndicator: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let beatCount: Int
    /// Active beat index (0-based), or −1 when stopped.
    let activeBeat: Int
    let accentFirst: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<max(1, beatCount), id: \.self) { i in
                dot(for: i)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Beat indicator")
        .accessibilityValue(activeBeat >= 0 ? "Beat \(activeBeat + 1) of \(beatCount)" : "Stopped")
    }

    private func dot(for index: Int) -> some View {
        let isActive = index == activeBeat
        let isAccent = accentFirst && index == 0
        let baseColor = isAccent ? PitchTheme.indigo : PitchTheme.secondaryText(scheme)
        let fill = isActive ? (isAccent ? PitchTheme.indigo : PitchTheme.indigoGlow) : PitchTheme.track(scheme)

        return Circle()
            .fill(fill)
            .frame(width: isAccent ? 18 : 14, height: isAccent ? 18 : 14)
            .overlay(
                Circle().strokeBorder(baseColor.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(reduceMotion ? 1.0 : (isActive ? 1.25 : 1.0))
            .shadow(color: isActive ? fill.opacity(0.6) : .clear, radius: isActive ? 6 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: activeBeat)
    }
}
