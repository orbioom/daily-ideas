import SwiftUI

/// A success/info toast overlay. Respects Reduce Motion (fades instead of
/// sliding when motion is reduced).
struct ToastView: View {
    let symbol: String
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text(message)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.accent.opacity(0.96), in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// Drives a transient toast. Bind `message`; set it to show, it auto-clears.
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastState?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(symbol: toast.symbol, message: toast.message)
                    .padding(.top, 8)
                    .transition(reduceMotion
                                ? .opacity
                                : .move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 1_900_000_000)
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                                self.toast = nil
                            }
                        }
                    }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: toast)
    }
}

struct ToastState: Equatable {
    let symbol: String
    let message: String
}

extension View {
    func toast(_ toast: Binding<ToastState?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
