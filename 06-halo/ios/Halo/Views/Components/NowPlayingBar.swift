import SwiftUI

struct NowPlayingBar: View {
    var engine: BinauralEngine
    var onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HaloTheme.spacingM) {
                ZStack {
                    Circle()
                        .fill(engine.sessionPreset?.category.color.opacity(0.25) ?? HaloTheme.accent.opacity(0.25))
                        .frame(width: 40, height: 40)
                    Circle()
                        .fill(engine.sessionPreset?.category.color.opacity(0.5) ?? HaloTheme.accent.opacity(0.5))
                        .frame(width: pulse ? 36 : 28, height: pulse ? 36 : 28)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    Image(systemName: engine.sessionPreset?.icon ?? "waveform")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.sessionPreset?.name ?? "Now Playing")
                        .font(HaloTheme.labelFont)
                        .foregroundStyle(HaloTheme.textPrimary)
                    Text(engine.sessionPreset?.binauralHzDisplay ?? "")
                        .font(HaloTheme.captionFont)
                        .foregroundStyle(HaloTheme.textSecondary)
                }

                Spacer()

                if let remaining = engine.remainingTime {
                    Text(formatTime(remaining))
                        .font(HaloTheme.captionFont)
                        .foregroundStyle(HaloTheme.textSecondary)
                        .monospacedDigit()
                }

                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HaloTheme.textTertiary)
            }
            .padding(.horizontal, HaloTheme.spacingM)
            .padding(.vertical, 10)
            .background(HaloTheme.surfaceElevated.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: HaloTheme.radiusM))
            .overlay(
                RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                    .stroke(HaloTheme.accent.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: -4)
            .padding(.horizontal, HaloTheme.spacingM)
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
