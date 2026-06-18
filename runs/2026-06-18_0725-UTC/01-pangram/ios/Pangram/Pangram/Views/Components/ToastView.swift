import SwiftUI

enum ToastKind {
    case success, warn, error

    var color: Color {
        switch self {
        case .success: return Theme.good
        case .warn: return Theme.warn
        case .error: return Theme.bad
        }
    }

    var symbol: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warn: return "exclamationmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

/// A small floating pill used for accepted/rejected word feedback and rank toasts.
struct ToastView: View {
    let text: String
    let kind: ToastKind

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: kind.symbol)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(15, .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(kind.color)
        )
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}
