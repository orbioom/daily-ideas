import SwiftUI

/// A small rounded label with a tinted background.
struct Pill: View {
    let text: String
    var color: Color = Theme.accent
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(Theme.rounded(12, .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.16)))
    }
}

/// A badge showing a stroke with its color and short name.
struct StrokeBadge: View {
    let stroke: Stroke

    var body: some View {
        Pill(text: stroke.shortLabel, color: stroke.hue, systemImage: stroke.symbol)
            .accessibilityLabel(stroke.label)
    }
}

/// A small lane-line motif used as a decorative divider.
struct LaneDivider: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { _ in
                Capsule()
                    .fill(Theme.hairline)
                    .frame(height: 3)
            }
        }
        .accessibilityHidden(true)
    }
}
