import SwiftUI

/// A transient confirmation toast (e.g. "Copied"). Drives itself via a token so
/// repeated copies re-trigger the animation.
struct ToastState: Equatable {
    var message: String
    var symbol: String
    var token: Int
}

struct ToastView: View {
    let message: String
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
            Text(message)
                .font(Theme.rounded(15, .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(
            Capsule().fill(Theme.ink.opacity(0.92))
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// View modifier that shows a toast at the bottom when `state` changes token.
private struct ToastModifier: ViewModifier {
    @Binding var state: ToastState?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let state, visible {
                    ToastView(message: state.message, symbol: state.symbol)
                        .padding(.bottom, 28)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: state?.token) { _, _ in
                guard state != nil else { return }
                withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.8)) {
                    visible = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 1_400_000_000)
                    withAnimation(reduceMotion ? .none : .easeOut(duration: 0.25)) {
                        visible = false
                    }
                }
            }
    }
}

extension View {
    func toast(_ state: Binding<ToastState?>) -> some View {
        modifier(ToastModifier(state: state))
    }
}
