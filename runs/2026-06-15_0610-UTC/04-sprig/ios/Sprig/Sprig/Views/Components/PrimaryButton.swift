import SwiftUI

/// Full-width primary action button in Sprig's language.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(Theme.rounded(17, .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(enabled ? Theme.accent : Theme.inkFaint)
            )
        }
        .disabled(!enabled)
    }
}

/// A child avatar circle with the child's initial.
struct ChildAvatar: View {
    let child: Child
    var size: CGFloat = 44

    var body: some View {
        let color = ChildColors.color(hex: child.colorHex)
        Circle()
            .fill(color.opacity(0.22))
            .overlay(
                Text(initial)
                    .font(Theme.rounded(size * 0.42, .bold))
                    .foregroundStyle(color)
            )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var initial: String {
        String(child.displayName.prefix(1)).uppercased()
    }
}
