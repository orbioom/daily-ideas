import SwiftUI

struct ControlPadView: View {
    let onMove: (Direction) -> Void
    let onUndo: () -> Void
    let canUndo: Bool

    var body: some View {
        VStack(spacing: 6) {
            // Up
            HStack {
                Spacer()
                dpadButton(icon: "chevron.up", accessLabel: "Move up") { onMove(.up) }
                Spacer()
            }

            // Left / Undo / Right
            HStack(spacing: 6) {
                dpadButton(icon: "chevron.left", accessLabel: "Move left") { onMove(.left) }
                undoButton
                dpadButton(icon: "chevron.right", accessLabel: "Move right") { onMove(.right) }
            }

            // Down
            HStack {
                Spacer()
                dpadButton(icon: "chevron.down", accessLabel: "Move down") { onMove(.down) }
                Spacer()
            }
        }
    }

    // MARK: - D-pad button

    private func dpadButton(icon: String, accessLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
                    .frame(width: 58, height: 58)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(PushTheme.wall)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessLabel)
    }

    // MARK: - Undo center button

    private var undoButton: some View {
        Button(action: onUndo) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(canUndo ? PushTheme.accent.opacity(0.12) : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
                    .frame(width: 58, height: 58)

                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(canUndo ? PushTheme.accent : PushTheme.wall.opacity(0.25))
            }
        }
        .buttonStyle(.plain)
        .disabled(!canUndo)
        .accessibilityLabel("Undo move")
    }
}

#Preview {
    ControlPadView(onMove: { _ in }, onUndo: { }, canUndo: true)
        .padding(40)
        .background(PushTheme.background)
}
