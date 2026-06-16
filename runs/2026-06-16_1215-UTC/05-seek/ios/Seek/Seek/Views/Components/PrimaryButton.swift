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
                }
                Text(title)
            }
            .font(Theme.rounded(17, .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(fill ? Color.white : Theme.accent)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(fill ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surfaceAlt))
            )
        }
        .buttonStyle(.plain)
    }
}
