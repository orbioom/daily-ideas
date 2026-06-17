import SwiftUI

/// A transient success/info banner shown at the top of a screen.
struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let text: String
    let symbol: String
    var isError: Bool = false
}

struct ToastView: View {
    let message: ToastMessage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.symbol)
                .font(Theme.rounded(16, .bold))
            Text(message.text)
                .font(Theme.rounded(15, .semibold))
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(message.isError ? Theme.bad : Theme.accent)
        )
        .shadow(color: (message.isError ? Theme.bad : Theme.accent).opacity(0.4), radius: 12, y: 4)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(message.text))
    }
}

/// Attaches a toast overlay driven by an optional binding. Auto-dismisses.
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(message: toast)
                    .padding(.top, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.25)) {
                                self.toast = nil
                            }
                        }
                    }
            }
        }
        .animation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.8), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
