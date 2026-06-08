import SwiftUI

struct QuickActionButton: View {
    let type: CareType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.14))
                        .frame(width: 50, height: 50)
                    Image(systemName: type.symbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(type.color)
                }
                Text(type.actionLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Brand.text2)
            }
        }
        .accessibilityLabel(type.actionLabel)
        .accessibilityHint("Log a \(type.label.lowercased()) event for this plant")
        .buttonStyle(QuickActionButtonStyle())
    }
}

private struct QuickActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.93 : 1)
            .animation(Brand.ease(0.2), value: configuration.isPressed)
    }
}
