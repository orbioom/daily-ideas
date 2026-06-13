import SwiftUI

struct KeyboardView: View {
    let states: [Character: LetterState]
    let onKey: (Character) -> Void
    let onEnter: () -> Void
    let onDelete: () -> Void

    private let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]

    var body: some View {
        VStack(spacing: 7) {
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 5) {
                    if i == 2 {
                        actionKey("ENTER", action: onEnter)
                    }
                    ForEach(Array(rows[i]), id: \.self) { ch in
                        letterKey(ch)
                    }
                    if i == 2 {
                        actionKey(nil, system: "delete.left", action: onDelete)
                    }
                }
            }
        }
    }

    private func letterKey(_ ch: Character) -> some View {
        let state = states[ch]
        let bg: Color = {
            switch state {
            case .correct: return Theme.correct
            case .present: return Theme.present
            case .absent: return Theme.absent
            default: return Theme.keyBase
            }
        }()
        let fg: Color = (state == nil || state == .empty || state == .filled) ? Theme.ink : .white
        return Button {
            onKey(ch); Haptics.tap()
        } label: {
            Text(String(ch).uppercased())
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(fg)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 6).fill(bg))
        }
        .accessibilityLabel(String(ch).uppercased())
    }

    private func actionKey(_ title: String?, system: String? = nil, action: @escaping () -> Void) -> some View {
        Button {
            action(); Haptics.tap()
        } label: {
            Group {
                if let title {
                    Text(title).font(.system(size: 12, weight: .bold))
                } else if let system {
                    Image(systemName: system).font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundStyle(Theme.ink)
            .frame(width: 52, minHeight: 52)
            .frame(maxWidth: 60)
            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.keyBase))
        }
        .accessibilityLabel(title ?? "Delete")
    }
}
