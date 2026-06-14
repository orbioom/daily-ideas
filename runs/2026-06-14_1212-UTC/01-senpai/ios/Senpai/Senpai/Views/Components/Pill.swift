import SwiftUI

/// A compact rounded label used for metadata (season, studio, genre).
struct Pill: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = Theme.inkSoft

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(Theme.rounded(12, .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.14)))
    }
}

/// A status pill coloured by the status, with the kind-aware label.
struct StatusPill: View {
    let status: WatchStatus
    let kind: AnimeMediaKind

    var body: some View {
        Pill(text: status.label(for: kind), systemImage: status.symbol, tint: status.color)
            .accessibilityLabel("Status: \(status.label(for: kind))")
    }
}
