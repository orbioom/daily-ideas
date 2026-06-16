import SwiftUI

/// Drives a transient success toast that auto-dismisses, respecting Reduce Motion.
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var symbol: String = "checkmark.circle.fill"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                ToastView(text: message, symbol: symbol)
                    .padding(.bottom, 28)
                    .transition(reduceMotion
                                ? .opacity
                                : .move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                                self.message = nil
                            }
                        }
                    }
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>, symbol: String = "checkmark.circle.fill") -> some View {
        modifier(ToastModifier(message: message, symbol: symbol))
    }
}
