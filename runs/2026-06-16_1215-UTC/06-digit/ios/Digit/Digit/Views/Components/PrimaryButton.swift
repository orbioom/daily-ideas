import SwiftUI

/// A big, friendly, tappable button in Digit's design language.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var fill: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(Theme.rounded(20, .bold))
                }
                Text(title)
                    .font(Theme.rounded(20, .bold))
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(fill ? Color.white : Theme.accent)
            .background {
                if fill {
                    RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                        .fill(Theme.heroGradient)
                } else {
                    RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                        .stroke(Theme.accent, lineWidth: 2)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }
}

/// A scale-down press effect that respects Reduce Motion.
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.96 : 1))
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
