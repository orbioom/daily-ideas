import SwiftUI

struct CellView: View {
    let cell: SokobanCell
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background
            cellBackground

            // Foreground icon / shape
            cellContent
        }
        .frame(width: size, height: size)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Background

    @ViewBuilder
    private var cellBackground: some View {
        switch cell {
        case .wall:
            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                .fill(PushTheme.wall)
        case .floor, .player:
            RoundedRectangle(cornerRadius: size * 0.10, style: .continuous)
                .fill(PushTheme.floor)
        case .target, .playerOnTarget:
            RoundedRectangle(cornerRadius: size * 0.10, style: .continuous)
                .fill(PushTheme.floor)
        case .box:
            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                .fill(PushTheme.box)
                .shadow(color: PushTheme.box.opacity(0.45), radius: size * 0.08, y: size * 0.06)
        case .boxOnTarget:
            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                .fill(PushTheme.boxOnTarget)
                .shadow(color: PushTheme.boxOnTarget.opacity(0.45), radius: size * 0.08, y: size * 0.06)
        }
    }

    // MARK: - Foreground content

    @ViewBuilder
    private var cellContent: some View {
        switch cell {
        case .wall:
            // Subtle grid texture for wall
            Rectangle()
                .fill(PushTheme.wall.opacity(0.0))
        case .floor:
            EmptyView()
        case .target:
            targetMarker
        case .playerOnTarget:
            ZStack {
                targetMarker
                playerShape
            }
        case .player:
            playerShape
        case .box:
            boxLabel
        case .boxOnTarget:
            boxOnTargetLabel
        }
    }

    // MARK: - Target marker (diamond)

    private var targetMarker: some View {
        ZStack {
            Circle()
                .strokeBorder(PushTheme.target, lineWidth: size * 0.06)
                .frame(width: size * 0.52, height: size * 0.52)

            Circle()
                .fill(PushTheme.target.opacity(0.25))
                .frame(width: size * 0.28, height: size * 0.28)
        }
    }

    // MARK: - Player (blue circle with face)

    private var playerShape: some View {
        ZStack {
            Circle()
                .fill(PushTheme.player)
                .frame(width: size * 0.68, height: size * 0.68)
                .shadow(color: PushTheme.player.opacity(0.4), radius: size * 0.08, y: size * 0.04)

            // Face dots
            HStack(spacing: size * 0.12) {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: size * 0.12, height: size * 0.12)
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: size * 0.12, height: size * 0.12)
            }
            .offset(y: -size * 0.05)
        }
    }

    // MARK: - Box label

    private var boxLabel: some View {
        ZStack {
            // Inner highlight
            RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: size * 0.04)
                .frame(width: size * 0.72, height: size * 0.72)
        }
    }

    // MARK: - Box on target label

    private var boxOnTargetLabel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: size * 0.04)
                .frame(width: size * 0.72, height: size * 0.72)

            Image(systemName: "checkmark")
                .font(.system(size: size * 0.32, weight: .heavy))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        switch cell {
        case .floor:         return "Empty floor"
        case .wall:          return "Wall"
        case .target:        return "Target"
        case .box:           return "Box"
        case .boxOnTarget:   return "Box on target"
        case .player:        return "You"
        case .playerOnTarget: return "You on target"
        }
    }
}

#Preview {
    HStack(spacing: 4) {
        CellView(cell: .wall, size: 48)
        CellView(cell: .floor, size: 48)
        CellView(cell: .target, size: 48)
        CellView(cell: .box, size: 48)
        CellView(cell: .boxOnTarget, size: 48)
        CellView(cell: .player, size: 48)
        CellView(cell: .playerOnTarget, size: 48)
    }
    .padding()
    .background(PushTheme.background)
}
