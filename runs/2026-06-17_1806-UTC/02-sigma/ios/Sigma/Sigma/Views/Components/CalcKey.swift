import SwiftUI

/// Visual role of a calculator key, driving its color treatment.
enum KeyStyle {
    case digit       // standard number key
    case function    // operators, scientific functions
    case accent      // the highlighted equals / primary action
    case destructive // clear

    func background(_ accent: Color) -> Color {
        switch self {
        case .digit: return Theme.key
        case .function: return Theme.keyFunction
        case .accent: return accent
        case .destructive: return Theme.keyFunction
        }
    }

    func foreground(_ accent: Color) -> Color {
        switch self {
        case .digit: return Theme.ink
        case .function: return Theme.ink
        case .accent: return Theme.accentInk
        case .destructive: return Theme.bad
        }
    }
}

/// A single tactile keypad button with subtle key shadows and press feedback.
struct CalcKey: View {
    let title: String
    var systemImage: String? = nil
    var style: KeyStyle = .digit
    var accent: Color = Theme.accent
    var isEnabled: Bool = true
    var accessibilityLabelText: String? = nil
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(Theme.rounded(22, .medium))
                } else {
                    Text(title)
                        .font(Theme.rounded(keyFontSize, .medium))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(isEnabled ? style.foreground(accent) : Theme.inkFaint)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerKey, style: .continuous)
                    .fill(isEnabled ? style.background(accent) : Theme.surfaceDeep)
                    .shadow(color: Theme.keyShadow.opacity(isEnabled ? 0.35 : 0), radius: pressed ? 1 : 4, y: pressed ? 1 : 3)
            )
            .scaleEffect(pressed && !reduceMotion ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerKey, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !pressed { pressed = true } }
                .onEnded { _ in pressed = false }
        )
        .accessibilityLabel(accessibilityLabelText ?? title)
        .accessibilityAddTraits(.isButton)
    }

    private var keyFontSize: CGFloat {
        title.count > 3 ? 18 : (title.count > 2 ? 20 : 26)
    }
}
