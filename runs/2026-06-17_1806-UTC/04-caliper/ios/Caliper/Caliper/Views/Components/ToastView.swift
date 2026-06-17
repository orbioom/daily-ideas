import SwiftUI

/// A transient success/info toast overlay. Honors Reduce Motion by skipping the
/// slide animation and using a plain fade.
struct ToastView: View {
    let text: String
    var systemImage: String = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.accentDeep, in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                ToastView(text: message)
                    .padding(.bottom, 28)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.25)) {
                                self.message = nil
                            }
                        }
                    }
            }
        }
        .animation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
