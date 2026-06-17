import SwiftUI

enum ToastKind {
    case good, bonus, neutral, bad

    var color: Color {
        switch self {
        case .good: return Theme.good
        case .bonus: return Theme.star
        case .neutral: return Theme.inkSoft
        case .bad: return Theme.bad
        }
    }

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .bonus: return "sparkles"
        case .neutral: return "info.circle.fill"
        case .bad: return "xmark.circle.fill"
        }
    }
}

/// A small floating toast for word feedback.
struct ToastView: View {
    let text: String
    let kind: ToastKind

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: kind.icon)
                .font(.system(size: 16, weight: .bold))
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(15, .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(kind.color)
                .shadow(color: kind.color.opacity(0.35), radius: 8, y: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
