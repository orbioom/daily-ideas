import SwiftUI

/// Custom on-screen QWERTY keyboard. Each letter key reflects its best-known
/// state (green > yellow > gray). Enter and Delete are dedicated keys.
struct KeyboardView: View {
    @Environment(\.colorScheme) private var scheme
    let keyStates: [Character: TileState]
    let highContrast: Bool
    let disabled: Bool
    let onLetter: (Character) -> Void
    let onEnter: () -> Void
    let onDelete: () -> Void

    private let rows: [[Character]] = [
        Array("qwertyuiop"),
        Array("asdfghjkl"),
        Array("zxcvbnm")
    ]

    var body: some View {
        VStack(spacing: 7) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                let isLast = rowIndex == rows.count - 1
                HStack(spacing: 5) {
                    if isLast {
                        actionKey("ENTER", wide: true, action: onEnter)
                            .accessibilityLabel("Enter")
                    }
                    ForEach(rows[rowIndex], id: \.self) { ch in
                        letterKey(ch)
                    }
                    if isLast {
                        actionKey(nil, systemImage: "delete.left", wide: true, action: onDelete)
                            .accessibilityLabel("Delete")
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    @ViewBuilder
    private func letterKey(_ ch: Character) -> some View {
        let state = keyStates[ch] ?? .empty
        let bg: Color = {
            switch state {
            case .correct, .present, .absent:
                return state.fill(scheme: scheme, highContrast: highContrast)
            default:
                return LexTheme.subtleSurface(scheme)
            }
        }()
        let fg: Color = (state == .empty || state == .tbd)
            ? LexTheme.primaryText(scheme)
            : .white

        Button {
            onLetter(ch)
            Haptics.light()
        } label: {
            Text(String(ch).uppercased())
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(bg)
                )
                .foregroundStyle(fg)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(String(ch).uppercased()), \(keyStatePhrase(state))")
    }

    @ViewBuilder
    private func actionKey(_ title: String?, systemImage: String? = nil, wide: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.light()
        } label: {
            Group {
                if let title {
                    Text(title).font(.system(size: 12, weight: .bold, design: .rounded))
                } else if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 18, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LexTheme.subtleSurface(scheme))
            )
            .foregroundStyle(LexTheme.primaryText(scheme))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: wide ? 64 : nil)
    }

    private func keyStatePhrase(_ state: TileState) -> String {
        switch state {
        case .correct: return "in word, correct spot"
        case .present: return "in word, wrong spot"
        case .absent: return "not in word"
        default: return "unused"
        }
    }
}
