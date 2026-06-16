import SwiftUI

/// A tactile number pad sized to the puzzle, plus the action row (notes, erase,
/// hint, undo). Buttons announce themselves and respect Dynamic Type.
struct NumberPadView: View {
    let size: Int
    let notesMode: Bool
    let canUndo: Bool
    let valueCounts: [Int: Int]   // value -> times placed (to dim exhausted)
    let onNumber: (Int) -> Void
    let onErase: () -> Void
    let onToggleNotes: () -> Void
    let onHint: () -> Void
    let onUndo: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var columns: [GridItem] {
        // Up to 4 per row for 4-5, scaling for 6-7.
        let perRow = size <= 5 ? size : (size + 1) / 2
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: max(perRow, 1))
    }

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...max(size, 1), id: \.self) { number in
                    NumberKey(
                        number: number,
                        exhausted: (valueCounts[number] ?? 0) >= size,
                        reduceMotion: reduceMotion
                    ) { onNumber(number) }
                }
            }

            HStack(spacing: 10) {
                ActionKey(title: "Notes", systemImage: notesMode ? "pencil.circle.fill" : "pencil.circle",
                          isActive: notesMode, action: onToggleNotes)
                    .accessibilityValue(notesMode ? "on" : "off")
                ActionKey(title: "Erase", systemImage: "delete.left", action: onErase)
                ActionKey(title: "Hint", systemImage: "lightbulb", action: onHint)
                ActionKey(title: "Undo", systemImage: "arrow.uturn.backward", isEnabled: canUndo, action: onUndo)
            }
        }
    }
}

private struct NumberKey: View {
    let number: Int
    let exhausted: Bool
    let reduceMotion: Bool
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(exhausted ? Theme.textSecondary : Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.surfaceElevated)
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.accent.opacity(exhausted ? 0.0 : 0.18), lineWidth: 1)
                )
                .opacity(exhausted ? 0.5 : 1.0)
                .scaleEffect(pressed && !reduceMotion ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .accessibilityLabel("Enter \(number)")
        .accessibilityHint(exhausted ? "All \(number)s may already be placed" : "Places \(number) in the selected cell")
    }
}

private struct ActionKey: View {
    let title: String
    let systemImage: String
    var isActive: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(isActive ? Theme.accent : (isEnabled ? Theme.textPrimary : Theme.textSecondary))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Theme.accent.opacity(0.14) : Theme.surfaceElevated)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(title)
    }
}
