import SwiftUI

/// A transient success/confirmation toast presented as an overlay.
struct ToastView: View {
    let symbol: String
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(message)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.accent, in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast {
                ToastView(symbol: toast.symbol, message: toast.text)
                    .padding(.bottom, 28)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(reduceMotion ? nil : .easeInOut) {
                                self.toast = nil
                            }
                        }
                    }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: toast)
    }
}

struct ToastMessage: Equatable {
    let symbol: String
    let text: String
}

extension View {
    func toast(_ message: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: message))
    }
}
