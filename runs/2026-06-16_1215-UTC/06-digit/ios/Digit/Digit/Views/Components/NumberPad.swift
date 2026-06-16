import SwiftUI

/// A custom 0-9 + delete + enter pad. No system keyboard. Large tappable targets + VoiceOver.
struct NumberPad: View {
    @Binding var text: String
    var maxDigits: Int = 4
    var isEnabled: Bool = true
    let onEnter: () -> Void
    var hapticsEnabled: Bool = true

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(1...9, id: \.self) { digit in
                key(label: "\(digit)", accessibility: "\(digit)") { append("\(digit)") }
            }
            // Bottom row: delete, 0, enter
            key(label: "", accessibility: "Delete", systemImage: "delete.left.fill",
                tint: Theme.surfaceAlt, fg: Theme.ink) { deleteLast() }
            key(label: "0", accessibility: "0") { append("0") }
            key(label: "", accessibility: "Enter", systemImage: "checkmark",
                tint: Theme.accent, fg: .white, action: submit)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }

    @ViewBuilder
    private func key(label: String, accessibility: String,
                     systemImage: String? = nil,
                     tint: Color = Theme.surface,
                     fg: Color = Theme.ink,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(Theme.rounded(26, .bold))
                } else {
                    Text(label)
                        .font(Theme.rounded(30, .bold))
                }
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(accessibility)
    }

    private func append(_ d: String) {
        guard isEnabled, text.count < maxDigits else { return }
        // Avoid leading zeros (e.g. "0" then "5" → "5").
        if text == "0" { text = d } else { text += d }
        Haptics.tap(hapticsEnabled)
    }

    private func deleteLast() {
        guard isEnabled, !text.isEmpty else { return }
        text.removeLast()
        Haptics.soft(hapticsEnabled)
    }

    private func submit() {
        guard isEnabled, !text.isEmpty else { return }
        onEnter()
    }
}
