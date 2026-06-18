import SwiftUI

/// A transient success / info toast overlay.
struct ToastView: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(Theme.accentDeep))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

/// View modifier that shows a toast bound to an optional message.
struct ToastModifier: ViewModifier {
    @Binding var message: ToastMessage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                ToastView(symbol: message.symbol, text: message.text)
                    .padding(.bottom, 24)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(reduceMotion ? .none : .easeInOut) { self.message = nil }
                        }
                    }
            }
        }
        .animation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8), value: message)
    }
}

struct ToastMessage: Equatable {
    let symbol: String
    let text: String
}

extension View {
    func toast(_ message: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
