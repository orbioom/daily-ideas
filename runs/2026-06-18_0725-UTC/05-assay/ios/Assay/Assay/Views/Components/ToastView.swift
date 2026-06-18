import SwiftUI

/// A transient success/info confirmation overlay.
struct ToastView: View {
    let icon: String
    let message: String
    var tint: Color = Theme.good

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
            Text(message)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// Modifier that presents a toast that auto-dismisses.
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(icon: toast.icon, message: toast.message, tint: toast.tint)
                    .padding(.top, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { self.toast = nil }
                        }
                    }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: toast?.id)
    }
}

struct ToastData: Equatable, Identifiable {
    let id = UUID()
    let icon: String
    let message: String
    var tint: Color = Theme.good
    static func == (l: ToastData, r: ToastData) -> Bool { l.id == r.id }
}

extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
