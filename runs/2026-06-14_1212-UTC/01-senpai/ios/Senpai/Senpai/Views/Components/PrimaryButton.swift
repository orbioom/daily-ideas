import SwiftUI

/// Full-width primary action button in Senpai's vibrant language.
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(enabled
                          ? LinearGradient(colors: [Theme.accent, Theme.violet],
                                           startPoint: .leading, endPoint: .trailing)
                          : LinearGradient(colors: [Theme.inkFaint, Theme.inkFaint],
                                           startPoint: .leading, endPoint: .trailing))
            )
        }
        .disabled(!enabled)
    }
}
