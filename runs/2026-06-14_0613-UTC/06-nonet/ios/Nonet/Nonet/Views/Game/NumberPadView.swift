import SwiftUI

/// The 1–9 number pad. Completed digits (all 9 placed) are dimmed.
struct NumberPadView: View {
    @ObservedObject var vm: GameViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 9)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...9, id: \.self) { digit in
                let done = vm.isComplete(digit)
                Button {
                    vm.enter(digit)
                } label: {
                    Text("\(digit)")
                        .font(Theme.rounded(26, .semibold))
                        .foregroundStyle(done ? Theme.textSecondary.opacity(0.4) : Theme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                                .stroke(Theme.separator, lineWidth: 1)
                        )
                }
                .disabled(done)
                .accessibilityLabel("Enter \(digit)")
                .accessibilityHint(done ? "All placed" : "")
            }
        }
    }
}

/// Control row: undo, erase, pencil, hint, pause.
struct GameControlsView: View {
    @ObservedObject var vm: GameViewModel
    let onHintBlocked: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            controlButton("arrow.uturn.backward", "Undo") { vm.undo() }
            controlButton("eraser", "Erase") { vm.erase() }
            controlButton(vm.pencilMode ? "pencil.circle.fill" : "pencil.circle",
                          "Pencil", active: vm.pencilMode) { vm.togglePencil() }
            controlButton("lightbulb", hintLabel) {
                if !vm.hint() { onHintBlocked() }
            }
            controlButton(vm.isPaused ? "play.fill" : "pause.fill",
                          vm.isPaused ? "Resume" : "Pause") { vm.togglePause() }
        }
    }

    private var hintLabel: String {
        if Pro.isUnlocked { return "Hint" }
        let left = max(0, vm.freeHintLimit - vm.hintsUsed)
        return "Hint (\(left))"
    }

    private func controlButton(_ icon: String, _ label: String, active: Bool = false,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(label)
                    .font(Theme.rounded(11, .medium))
            }
            .foregroundStyle(active ? Theme.accent : Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(active ? Theme.accent.opacity(0.12) : Theme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .stroke(Theme.separator, lineWidth: 1)
            )
        }
        .accessibilityLabel(label)
    }
}
