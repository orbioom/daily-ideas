import SwiftUI

/// Custom on-screen QWERTY keyboard for grid entry. We don't use the system
/// keyboard so the board never shifts and entry stays single-character.
struct KeyboardView: View {
    let onKey: (Character) -> Void
    let onDelete: () -> Void
    let onNext: () -> Void

    private let rows: [[Character]] = [
        Array("QWERTYUIOP"),
        Array("ASDFGHJKL"),
        Array("ZXCVBNM")
    ]

    var body: some View {
        VStack(spacing: 7) {
            keyRow(rows[0])
            keyRow(rows[1])
            HStack(spacing: 6) {
                actionKey(symbol: "arrow.right.to.line", label: "Next clue", action: onNext)
                ForEach(rows[2], id: \.self) { ch in
                    letterKey(ch)
                }
                actionKey(symbol: "delete.left", label: "Delete", action: onDelete)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .background(Theme.surfaceAlt.ignoresSafeArea(edges: .bottom))
    }

    private func keyRow(_ chars: [Character]) -> some View {
        HStack(spacing: 6) {
            ForEach(chars, id: \.self) { ch in
                letterKey(ch)
            }
        }
    }

    private func letterKey(_ ch: Character) -> some View {
        Button {
            onKey(ch)
        } label: {
            Text(String(ch))
                .font(Theme.rounded(20, .medium))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Theme.surface)
                        .shadow(color: .black.opacity(0.08), radius: 0.5, y: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Letter \(String(ch))")
    }

    private func actionKey(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Theme.bg)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
