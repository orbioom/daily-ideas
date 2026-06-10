import SwiftUI

struct KeyboardView: View {
    let states: [Character: LetterState]
    let onKey: (Character) -> Void
    let onEnter: () -> Void
    let onDelete: () -> Void

    private let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]

    var body: some View {
        VStack(spacing: 7) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 5) {
                    if r == 2 {
                        actionKey("ENTER", action: onEnter).frame(width: 58)
                    }
                    ForEach(Array(rows[r]), id: \.self) { ch in
                        letterKey(ch)
                    }
                    if r == 2 {
                        actionKey(nil, system: "delete.left", action: onDelete).frame(width: 58)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func letterKey(_ ch: Character) -> some View {
        let state = states[ch] ?? .empty
        return Button { onKey(ch) } label: {
            Text(String(ch).uppercased())
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(state.filled ? .white : Brand.text)
                .background(state.filled ? state.tint : Brand.dynamic(0xCDD0DA, 0x3A3D49),
                            in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ch), \(stateWord(state))")
    }

    private func actionKey(_ title: String?, system: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let title { Text(title).font(.system(size: 12, weight: .bold)) }
                else if let system { Image(systemName: system) }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(Brand.text)
            .background(Brand.dynamic(0xCDD0DA, 0x3A3D49), in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title ?? "Delete")
    }

    private func stateWord(_ s: LetterState) -> String {
        switch s {
        case .correct: "correct position"; case .present: "in word"
        case .absent: "not in word"; case .empty: "untried"
        }
    }
}
