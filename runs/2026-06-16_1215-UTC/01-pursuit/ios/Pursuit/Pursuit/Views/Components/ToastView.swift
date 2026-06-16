import SwiftUI

/// A transient confirmation toast overlay. Respects Reduce Motion.
struct ToastView: View {
    let message: String
    let symbol: String
    var tint: Color = Theme.good

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
            Text(message)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.elevated, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// View modifier to present a toast that auto-dismisses.
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(message: toast.message, symbol: toast.symbol, tint: toast.tint)
                    .padding(.top, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                                self.toast = nil
                            }
                        }
                    }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: toast?.id)
    }
}

struct ToastData: Equatable, Identifiable {
    let id = UUID()
    let message: String
    let symbol: String
    var tint: Color = Theme.good

    static func == (lhs: ToastData, rhs: ToastData) -> Bool { lhs.id == rhs.id }
}

extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
