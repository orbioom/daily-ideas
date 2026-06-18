import SwiftUI

/// The app's primary filled capsule button.
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
                    .font(Theme.roundedStyle(.headline))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(fill ? .white : Theme.accent)
            .background(
                Capsule().fill(fill ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.surfaceAlt))
            )
            .overlay(
                Capsule().strokeBorder(fill ? Color.clear : Theme.accent, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
