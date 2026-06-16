import SwiftUI

/// A lightweight success/info toast overlay.
struct ToastView: View {
    let text: String
    var symbol: String = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

/// View modifier to present a transient toast.
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var symbol: String = "checkmark.circle.fill"

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message {
                ToastView(text: message, symbol: symbol)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(nanoseconds: 1_900_000_000)
                        withAnimation { self.message = nil }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>, symbol: String = "checkmark.circle.fill") -> some View {
        modifier(ToastModifier(message: message, symbol: symbol))
    }
}
