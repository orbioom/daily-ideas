import SwiftUI

/// A transient confirmation toast shown on success actions (e.g. copy).
struct ToastView: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(Theme.rounded(15, .semibold))
                .accessibilityHidden(true)
            Text(message)
                .font(Theme.rounded(15, .semibold))
        }
        .foregroundStyle(Theme.accentInk)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(Theme.accent)
                .shadow(color: Theme.keyShadow.opacity(0.5), radius: 10, y: 4)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// A reusable view modifier presenting a `ToastView` overlay that auto-dismisses.
private struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let systemImage: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented {
                ToastView(message: message, systemImage: systemImage)
                    .padding(.top, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation(reduceMotion ? .none : .easeOut(duration: 0.25)) {
                                isPresented = false
                            }
                        }
                    }
                    .zIndex(1)
            }
        }
        .animation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, systemImage: String = "checkmark.circle.fill") -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, systemImage: systemImage))
    }
}
