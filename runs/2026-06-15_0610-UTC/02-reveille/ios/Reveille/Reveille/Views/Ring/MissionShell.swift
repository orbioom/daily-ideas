import SwiftUI

/// Shared visual frame for a dismiss mission on the ring screen: a translucent card with a
/// title, a rep-progress row of dots, and arbitrary content. Keeps every mission consistent.
struct MissionShell<Content: View>: View {
    let title: String
    let subtitle: String
    let repsTotal: Int
    let repsDone: Int
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(title)
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(Theme.rounded(14))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            if repsTotal > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<repsTotal, id: \.self) { i in
                        Circle()
                            .fill(i < repsDone ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 9, height: 9)
                    }
                }
                .accessibilityLabel("\(repsDone) of \(repsTotal) done")
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

/// A glassy keypad/answer button used by the math mission.
struct GlassButton: View {
    let label: String
    var systemImage: String? = nil
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Image(systemName: systemImage)
                } else {
                    Text(label)
                }
            }
            .font(Theme.rounded(24, .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(prominent ? Color.white.opacity(0.28) : Color.white.opacity(0.14))
            )
        }
        .buttonStyle(.plain)
    }
}
