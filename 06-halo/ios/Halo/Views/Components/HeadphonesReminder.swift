import SwiftUI

struct HeadphonesReminder: View {
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: HaloTheme.spacingM) {
            Image(systemName: "headphones")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "#F59E0B"))

            VStack(alignment: .leading, spacing: 2) {
                Text("Headphones required")
                    .font(HaloTheme.labelFont)
                    .foregroundColor(HaloTheme.textPrimary)
                Text("Binaural beats only work with stereo headphones or earbuds.")
                    .font(HaloTheme.captionFont)
                    .foregroundColor(HaloTheme.textSecondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(HaloTheme.textTertiary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle().fill(HaloTheme.surfaceElevated)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(Color(hex: "#F59E0B").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color(hex: "#F59E0B").opacity(0.3), lineWidth: 1)
                )
        )
    }
}
