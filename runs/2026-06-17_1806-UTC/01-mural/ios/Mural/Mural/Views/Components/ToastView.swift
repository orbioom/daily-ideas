import SwiftUI

enum ToastKind {
    case success, error, info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success: return Theme.good
        case .error: return Theme.bad
        case .info: return Theme.accent
        }
    }
}

struct Toast: Equatable {
    let kind: ToastKind
    let message: String

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.message == rhs.message
    }
}

/// A floating confirmation banner. Respects Reduce Motion (fades only if reduced).
struct ToastView: View {
    let toast: Toast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.kind.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(toast.kind.tint)
            Text(toast.message)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(toast.message)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(toast: toast)
                    .padding(.top, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                            withAnimation(reduceMotion ? .none : .spring(duration: 0.3)) {
                                if self.toast == toast { self.toast = nil }
                            }
                        }
                    }
            }
        }
        .animation(reduceMotion ? .none : .spring(duration: 0.35), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
