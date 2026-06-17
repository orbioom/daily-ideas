import SwiftUI

/// The app's primary call-to-action button style.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var fill: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(Theme.rounded(17, .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(fill ? Color.white : Theme.accentDeep)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .fill(fill ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.accentSoft))
            )
        }
        .buttonStyle(.plain)
    }
}

/// A subtle secondary text button.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
