import SwiftUI

/// A transient success/info toast overlay.
struct ToastView: View {
    let symbol: String
    let message: String
    var tint: Color = Theme.good

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(tint)
            Text(message)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// A reusable modifier to present an auto-dismissing toast.
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let symbol: String
    let message: String
    var tint: Color = Theme.good
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented {
                ToastView(symbol: symbol, message: message, tint: tint)
                    .padding(.top, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation(reduceMotion ? nil : .easeOut) { isPresented = false }
                    }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, symbol: String, message: String,
               tint: Color = Theme.good) -> some View {
        modifier(ToastModifier(isPresented: isPresented, symbol: symbol, message: message, tint: tint))
    }
}
